import logging
import math
import os
import difflib
import numpy as np
import torch
import torch.nn.functional as F

from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
from phonemizer import phonemize
from phonemizer.separator import Separator

# ----------------- Logging -----------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s",
)
logger = logging.getLogger(__name__)

# ----------------- Load model (singleton) -----------------
logger.info("Initializing phoneme CTC model...")
_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
logger.info(f"Using device: {_device}")

# Model: facebook/wav2vec2-lv-60-espeak-cv-ft
# Cho phép override bằng biến môi trường (hữu ích khi chạy local)
MODEL_NAME = os.getenv("PHONEME_MODEL_PATH", "/opt/phoneme_model")

if not os.path.exists(MODEL_NAME):
    raise FileNotFoundError(
        f"Model directory not found at {MODEL_NAME}. "
        "Make sure the model was downloaded during Docker build, "
        "or set PHONEME_MODEL_PATH environment variable to point to the model directory."
    )
if not os.path.isdir(MODEL_NAME):
    raise ValueError(f"{MODEL_NAME} exists but is not a directory")

required_files = ["config.json", "preprocessor_config.json"]
missing_files = [
    f for f in required_files if not os.path.exists(os.path.join(MODEL_NAME, f))
]
if missing_files:
    all_files = os.listdir(MODEL_NAME) if os.path.exists(MODEL_NAME) else []
    logger.error(f"Model directory {MODEL_NAME} is missing required files: {missing_files}")
    logger.error(f"Existing files: {all_files}")
    raise FileNotFoundError(
        f"Model directory {MODEL_NAME} is missing required files: {missing_files}. "
        "Please rebuild Docker image to download the model correctly."
    )

logger.info(f"✅ Model directory found at: {MODEL_NAME}")

try:
    logger.info(f"Loading processor from local path: {MODEL_NAME}")
    # local_files_only=True và cache_dir=None để không tạo thư mục mới
    _processor = Wav2Vec2Processor.from_pretrained(
        MODEL_NAME, 
        local_files_only=True,
        cache_dir=None
    )

    logger.info(f"Loading Wav2Vec2ForCTC model from local path: {MODEL_NAME}")
    try:
        _model = (
            Wav2Vec2ForCTC.from_pretrained(
                MODEL_NAME,
                local_files_only=True,
                cache_dir=None  # Không dùng cache để tránh tạo thư mục
            )
            .to(_device)
            .eval()
        )
    except Exception as load_error:
        logger.error(f"Failed to load model with local_files_only: {load_error}")
        logger.error(
            f"Model directory {MODEL_NAME} exists but cannot load model. "
            "This should not happen if model was downloaded correctly during Docker build."
        )
        raise FileNotFoundError(
            f"Cannot load model from {MODEL_NAME}. "
            "Please rebuild Docker image to download the model correctly."
        ) from load_error

    logger.info("Phoneme CTC model loaded successfully (offline mode)")
except Exception as e:
    logger.error(f"Failed to load phoneme model from {MODEL_NAME}: {e}")
    logger.error("Make sure the model was downloaded and copied to Docker image")
    raise

logger.info("Loading phonemizer backend...")
_PHONEMIZER_LANGUAGE = os.getenv("PHONEMIZER_LANGUAGE", "en-us")
_PHONEMIZER_BACKEND = os.getenv("PHONEMIZER_BACKEND", "espeak")
_PHONEMIZER_SEPARATOR = Separator(phone=" ", syllable="", word="")
logger.info("All models (ASR phoneme + phonemizer) loaded successfully")

# ----------------- Core: audio → phoneme IDs -----------------
def audio_to_phoneme_ids(
    wav_16k: np.ndarray, top_k: int = 1
) -> tuple[np.ndarray, np.ndarray, list[list[int]]]:
    """
    Convert audio to phoneme IDs with top-k predictions.

    Args:
        wav_16k: float32, mono, 16kHz, [-1,1]
        top_k: number of top predictions to return per timestep

    Returns:
        best_ids: (T,) best predicted phoneme IDs
        log_probs: (T, V) log-probabilities over vocab
        top_k_ids: list of lists, top-k IDs per timestep
    """
    logger.debug(f"audio_to_phoneme_ids: audio shape={wav_16k.shape}, top_k={top_k}")
    with torch.no_grad():
        inputs = _processor(wav_16k, sampling_rate=16000, return_tensors="pt")
        input_values = inputs.input_values.to(_device)
        logits = _model(input_values).logits  # [1, T, V]
        log_probs = F.log_softmax(logits, dim=-1)[0]  # [T, V]
        best_ids = torch.argmax(log_probs, dim=-1)  # [T]

        # top-k IDs cho từng timestep
        _, top_k_ids_tensor = torch.topk(
            log_probs, k=min(top_k, log_probs.size(-1)), dim=-1
        )  # [T, top_k]
        top_k_ids = top_k_ids_tensor.cpu().numpy().tolist()

    return best_ids.cpu().numpy(), log_probs.cpu().numpy(), top_k_ids


def decode_ids_to_phones(ids: np.ndarray) -> tuple[list[str], str]:
    """Decode phoneme IDs thành list IPA phoneme + raw text."""
    tensor_ids = torch.from_numpy(ids).unsqueeze(0).long()
    text = _processor.batch_decode(tensor_ids, skip_special_tokens=True)[0]
    phones: list[str] = []
    for p in text.split(" "):
        p = p.strip()
        if p:
            phones.append(p)
    return phones, text


# ----------------- Word → IPA (phonemizer) -----------------
def _phonemize_word(word: str) -> list[str]:
    """
    Phonemizer/espeak → IPA tokens cho 1 từ.
    """
    if not word:
        return []
    ipa_string = phonemize(
        word,
        language=_PHONEMIZER_LANGUAGE,
        backend=_PHONEMIZER_BACKEND,
        strip=True,
        preserve_punctuation=False,
        with_stress=False,
        separator=_PHONEMIZER_SEPARATOR,
        njobs=1,
    )
    tokens = [tok.strip() for tok in ipa_string.replace("|", " ").split() if tok.strip()]
    return tokens


def words_to_ipa_direct(
    words: list[str],
) -> tuple[list[str], list[list[str]], list[str], list[list[str]]]:
    """
    Word list → IPA (dùng phonemizer trực tiếp, không fallback).

    Trả về:
        phs_ipa           : list IPA phoneme (flat)
        per_word_ipa      : list[list IPA phoneme] per word
        ph_ref_simple     : flat simple-IPA (grouped) cho PER
        ph_by_word_simple : simple-IPA per word
    """
    logger.debug(f"words_to_ipa_direct (phonemizer): input words={words}")
    phs_ipa: list[str] = []
    per_word_ipa: list[list[str]] = []

    for word in words:
        ipa_tokens: list[str] = []
        try:
            ipa_tokens = _phonemize_word(word)
        except Exception as e:
            logger.warning(f"words_to_ipa_direct: phonemizer failed for '{word}': {e}")
            raise
        if not ipa_tokens:
            raise ValueError(f"words_to_ipa_direct: phonemizer returned empty IPA for '{word}'")
        per_word_ipa.append(ipa_tokens)
        phs_ipa.extend(ipa_tokens)

    ph_ref_simple = ipa_list_to_simple_seq_direct(phs_ipa)
    ph_by_word_simple = [ipa_list_to_simple_seq_direct(seq) for seq in per_word_ipa]

    logger.debug(
        f"words_to_ipa_direct: total IPA phonemes={len(phs_ipa)}, per_word={per_word_ipa}"
    )
    return phs_ipa, per_word_ipa, ph_ref_simple, ph_by_word_simple

# ----------------- IPA normalization & simplification -----------------
_ESPEAK_NORMALIZE_MAP = {
    # r-colored / stressed vowels
    "ɑ5": "ɝ",
    "ɚ": "ɝ",
    "ɝ˞": "ɝ",
    "ə1": "ə",
    "ə2": "ə",
    "əɜ": "ɚ",
    # flap / allophones
    "ɾ": "t",
    "ᵻ": "ɪ",
    # aspirated stops
    "kh": "k",
    "kʰ": "k",
    "ph": "p",
    "pʰ": "p",
    "th": "t",
    "tʰ": "t",
    # weird affricates / clusters
    "tɕh": "tʃ",
    "ts.h": "tʃ",
    "ts": "tʃ",
    # i-variants
    "i5": "iː",
}


def normalize_espeak_token(token: str) -> str:
    if not token:
        return ""

    t = token.strip()
    if not t:
        return ""

    # Map đặc biệt trước
    t = _ESPEAK_NORMALIZE_MAP.get(t, t)

    # syllabic r: ɹ̩, ɹ̩˞ → ɹ
    if "ɹ" in t and "̩" in t:
        t = "ɹ"

    # bỏ số stress / tone
    t = "".join(ch for ch in t if not ch.isdigit())
    # bỏ diacritics (U+0300–U+036F)
    t = "".join(ch for ch in t if not (0x0300 <= ord(ch) <= 0x036F))

    # remap aspirated stops sau khi bỏ diacritics
    t = _ESPEAK_NORMALIZE_MAP.get(t, t)
    return t


def _simple_ipa_char(ch: str) -> str:
    if not ch:
        return ch
    return ch[0]


def ipa_list_to_simple_seq_direct(ph_ipa_list: list[str]) -> list[str]:
    """
    IPA list → simple-IPA (lấy char "nhóm" đầu tiên sau normalize).
    Giữ nguyên phoneme dài (có ː) như iː, uː, etc.
    """
    simple: list[str] = []
    for ph in ph_ipa_list:
        if not ph:
            continue
        ph_norm = normalize_espeak_token(ph)
        if not ph_norm:
            continue
        # Giữ nguyên phoneme dài (có ː) trong simple-IPA
        if len(ph_norm) > 1 and ph_norm[1] == 'ː':
            simple.append(ph_norm[:2])  # Giữ nguyên 'iː', 'uː', etc.
        else:
            ch = ph_norm[0]
            if ch:
                simple.append(_simple_ipa_char(ch))
    return simple


def ipa_list_to_simple_seq(ph_pred_list: list[str]) -> list[str]:
    """
    IPA list từ model → simple-IPA sequence (log chi tiết nếu normalize làm rỗng).
    """
    simple: list[str] = []
    for idx, s in enumerate(ph_pred_list):
        if not s:
            continue
        s_norm = normalize_espeak_token(s)
        if not s_norm:
            logger.debug(
                f"ipa_list_to_simple_seq: [{idx}] '{s}' normalized to empty, skipping"
            )
            continue
        # Giữ nguyên phoneme dài (có ː) trong simple-IPA
        if len(s_norm) > 1 and s_norm[1] == 'ː':
            simple.append(s_norm[:2])  # Giữ nguyên 'iː', 'uː', etc.
            logger.debug(
                f"ipa_list_to_simple_seq: [{idx}] '{s}' -> '{s_norm}' (long vowel, kept as '{s_norm[:2]}')"
            )
        else:
            ch_original = s_norm[0]
            if ch_original:
                ch_grouped = _simple_ipa_char(ch_original)
                if s != s_norm or ch_original != ch_grouped:
                    logger.debug(
                        f"ipa_list_to_simple_seq: [{idx}] '{s}' -> '{s_norm}' "
                        f"-> '{ch_original}' -> grouped '{ch_grouped}'"
                    )
                simple.append(ch_grouped)
    return simple

# ----------------- Weighted phoneme distance / PER -----------------
CONFUSABLE = {
    # Plosive T/D vs flap
    ("t", "ɾ"),
    ("ɾ", "t"),
    ("d", "ɾ"),
    ("ɾ", "d"),
    # Vowel gần nhau
    ("ə", "ʌ"),
    ("ʌ", "ə"),
    ("ə", "ɪ"),
    ("ɪ", "ə"),
    ("ʌ", "ɪ"),
    ("ɪ", "ʌ"),
    ("ɪ", "ᵻ"),
    ("ᵻ", "ɪ"),
    ("u", "ʊ"),
    ("ʊ", "u"),
    ("o", "ɔ"),
    ("ɔ", "o"),
    # Front vowels gần nhau
    ("æ", "ɛ"),
    ("ɛ", "æ"),
    ("æ", "e"),
    ("e", "æ"),
    ("ɛ", "e"),
    ("e", "ɛ"),
    # Central vowels và open vowels (common confusion)
    ("ʌ", "a"),
    ("a", "ʌ"),
    ("ʌ", "ɑ"),
    ("ɑ", "ʌ"),
    # R-colored vowels vs central vowels
    ("ɝ", "ʌ"),
    ("ʌ", "ɝ"),
    ("ɝ", "ə"),
    ("ə", "ɝ"),
    ("ɚ", "ʌ"),
    ("ʌ", "ɚ"),
    # Fricative
    ("s", "ʃ"),
    ("ʃ", "s"),
    ("z", "ʒ"),
    ("ʒ", "z"),
    # Nasals
    ("n", "ŋ"),
    ("ŋ", "n"),
    ("n", "m"),
    ("m", "n"),
    # Liquids
    ("l", "ɹ"),
    ("ɹ", "l"),
    # Voicing pairs
    ("t", "d"),
    ("d", "t"),
    # Dental fricatives vs stops (common L2 error)
    ("ð", "d"),
    ("d", "ð"),
    ("θ", "t"),
    ("t", "θ"),
}


def normalize_ipa_phoneme(ph: str) -> str:
    """Normalize IPA phoneme (bỏ stress, diacritics) nhưng giữ nguyên cấu trúc."""
    if not ph:
        return ""
    return normalize_espeak_token(ph)


def phoneme_sub_cost(a: str, b: str) -> float:
    """Chi phí thay thế giữa 2 phoneme IPA (sau normalize)."""
    a_norm = normalize_ipa_phoneme(a)
    b_norm = normalize_ipa_phoneme(b)
    
    if a_norm == b_norm:
        return 0.0
    
    # Lấy base character (ký tự đầu) để check CONFUSABLE
    # Với long vowels (có ː), vẫn lấy ký tự đầu (ví dụ: 'aː' → 'a')
    a_base = a_norm[0] if a_norm else ""
    b_base = b_norm[0] if b_norm else ""
    
    # Check CONFUSABLE với base characters
    if (a_base, b_base) in CONFUSABLE:
        logger.debug(f"phoneme_sub_cost: '{a}' -> '{b}' (confusable: cost=0.5)")
        return 0.5  # phát âm gần giống → phạt nửa lỗi
    logger.debug(f"phoneme_sub_cost: '{a}' -> '{b}' (not confusable: cost=1.0)")
    return 1.0  # khác hẳn


def edit_distance_weighted(a: list[str], b: list[str]) -> float:
    """
    Weighted edit distance:
      insert = 1.0
      delete = 1.0
      substitute = 0.0 / 0.5 / 1.0
    """
    m, n = len(a), len(b)
    dp = [[0.0] * (n + 1) for _ in range(m + 1)]

    for i in range(1, m + 1):
        dp[i][0] = dp[i - 1][0] + 1.0
    for j in range(1, n + 1):
        dp[0][j] = dp[0][j - 1] + 1.0

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            dp[i][j] = min(
                dp[i - 1][j] + 1.0,  # delete
                dp[i][j - 1] + 1.0,  # insert
                dp[i - 1][j - 1] + phoneme_sub_cost(a[i - 1], b[j - 1]),  # sub
            )
    return dp[m][n]


def sequence_per(ref_simple: list[str], pred_simple: list[str]) -> float:
    """
    Tính PER trên simple-IPA với sliding window (tránh phạt padding ở cuối).
    """
    if not ref_simple:
        return 1.0 if pred_simple else 0.0

    Lr = len(ref_simple)
    Lp = len(pred_simple)

    # pred ngắn hơn/equal → so trực tiếp
    if Lp <= Lr:
        ed = edit_distance_weighted(ref_simple, pred_simple)
        return ed / max(1, Lr)

    # pred dài hơn → sliding window
    min_ed = math.inf
    for i in range(0, Lp - Lr + 1):
        window = pred_simple[i : i + Lr]
        ed = edit_distance_weighted(ref_simple, window)
        if ed < min_ed:
            min_ed = ed

    return min_ed / max(1, Lr)

# ----------------- Word coverage & alignment flags -----------------
def word_covered(
    ph_seq_word: list[str],
    pred_simple_seq: list[str],
    phoneme_format: str = "simple",
) -> bool:
    """
    Check 1 từ có được "phủ" bởi pred hay không (dùng simple-IPA).

    phoneme_format:
      - "simple": ph_seq_word đã là simple-IPA
      - "ipa"   : ph_seq_word là IPA, sẽ convert sang simple-IPA
    """
    if not ph_seq_word:
        return False

    if phoneme_format == "ipa":
        ref_simple = ipa_list_to_simple_seq_direct(ph_seq_word)
    else:  # "simple" hoặc default
        ref_simple = [ph for ph in ph_seq_word if ph]

    if not ref_simple:
        return False

    min_ed = math.inf
    for i in range(0, max(1, len(pred_simple_seq) - len(ref_simple) + 1)):
        window = pred_simple_seq[i : i + len(ref_simple)]
        ed = edit_distance_weighted(ref_simple, window)
        min_ed = min(min_ed, ed)

    # cho từ ngắn (<=3 phoneme) → cho phép sai 1 phoneme
    if len(ref_simple) <= 3:    
        threshold = 1.0
    else:
        threshold = len(ref_simple) * 0.4

    return min_ed <= threshold


def compute_phoneme_match_flags(
    ref_simple: list[str], pred_simple: list[str]
) -> list[bool]:
    """
    Align ref_simple với pred_simple (simple-IPA) và trả về list[bool] match / not.
    """
    if not ref_simple:
        return []
    matcher = difflib.SequenceMatcher(a=ref_simple, b=pred_simple or [])
    flags: list[bool] = []
    for tag, i1, i2, _, _ in matcher.get_opcodes():
        length = i2 - i1
        if length <= 0:
            continue
        if tag == "equal":
            flags.extend([True] * length)
        else:
            flags.extend([False] * length)

    if len(flags) < len(ref_simple):
        flags.extend([False] * (len(ref_simple) - len(flags)))
    elif len(flags) > len(ref_simple):
        flags = flags[: len(ref_simple)]
    return flags


def split_flags_by_lengths(
    flags: list[bool], lengths: list[int]
) -> list[list[bool]]:
    """
    Chia flags flat thành từng từ theo lengths.
    """
    result: list[list[bool]] = []
    idx = 0
    for length in lengths:
        segment = flags[idx : idx + length]
        if len(segment) < length:
            segment = segment + [False] * (length - len(segment))
        result.append(segment)
        idx += length
    return result

# ----------------- Fluency metrics -----------------
def calculate_fluency(
    wav_16k: np.ndarray,
    words_ref: list[str],
    ph_pred_list: list[str],
    ref_phonemes_per_word: list[list[str]] | None = None,
) -> dict:
    """
    Tính độ trôi chảy (fluency) dựa trên:
      - Speech rate (từ/giây)
      - Pause ratio
    """
    audio_duration = len(wav_16k) / 16000.0
    if audio_duration <= 0:
        return {
            "fluency_score": 0.0,
            "speech_rate": 0.0,
            "pause_ratio": 1.0,
        }

    # Speech rate
    num_words = len(words_ref)
    speech_rate = num_words / audio_duration if audio_duration > 0 else 0.0

    ideal_min, ideal_max = 2.0, 4.0
    acceptable_min, acceptable_max = 0.7, 5.5

    if ideal_min <= speech_rate <= ideal_max:
        speech_rate_score = 1.0
    elif acceptable_min <= speech_rate < ideal_min:
        speech_rate_score = 0.7 + (
            (speech_rate - acceptable_min) / (ideal_min - acceptable_min)
        ) * 0.3
    elif ideal_max < speech_rate <= acceptable_max:
        speech_rate_score = 1.0 - (
            (speech_rate - ideal_max) / (acceptable_max - ideal_max)
        ) * 0.3
    else:
        if speech_rate < acceptable_min:
            speech_rate_score = max(0.3, 0.7 * (speech_rate / acceptable_min))
        else:
            speech_rate_score = max(
                0.3, 0.7 * (1.0 - (speech_rate - acceptable_max) / acceptable_max)
            )

    # Pause ratio (RMS energy)
    frame_size = 1600  # 100ms
    num_frames = len(wav_16k) // frame_size
    if num_frames > 0:
        energies: list[float] = []
        for i in range(num_frames):
            frame = wav_16k[i * frame_size : (i + 1) * frame_size]
            rms = np.sqrt(np.mean(frame ** 2))
            energies.append(rms)

        if energies:
            energy_threshold = np.percentile(energies, 20)  # 20% thấp nhất = pause
            pause_frames = sum(1 for e in energies if e < energy_threshold)
            pause_ratio = pause_frames / len(energies) if len(energies) > 0 else 0.0
        else:
            pause_ratio = 0.0
    else:
        pause_ratio = 0.0

    ideal_min, ideal_max = 0.05, 0.35
    acceptable_min, acceptable_max = 0.02, 0.50

    if ideal_min <= pause_ratio <= ideal_max:
        pause_score = 1.0
    elif acceptable_min <= pause_ratio < ideal_min:
        pause_score = 0.8 + (
            (pause_ratio - acceptable_min) / (ideal_min - acceptable_min)
        ) * 0.2
    elif ideal_max < pause_ratio <= acceptable_max:
        pause_score = 1.0 - (
            (pause_ratio - ideal_max) / (acceptable_max - ideal_max)
        ) * 0.3
    else:
        if pause_ratio < acceptable_min:
            pause_score = max(0.4, 0.8 * (pause_ratio / acceptable_min))
        else:
            pause_score = max(
                0.4, 0.7 * (1.0 - (pause_ratio - acceptable_max) / 0.3)
            )

    # Fluency chỉ dựa trên speech rate + pause ratio
    fluency_score = (speech_rate_score * 0.5 + pause_score * 0.5) * 100.0

    return {
        "fluency_score": fluency_score,
        "speech_rate": speech_rate,
        "pause_ratio": pause_ratio,
    }

# ----------------- Main API -----------------
def assess_pronunciation(wav_16k: np.ndarray, words_ref: list[str]) -> dict:
    logger.info("=" * 60)
    logger.info("Starting pronunciation assessment")
    logger.info(
        f"  Input: {len(words_ref)} words, "
        f"audio duration={len(wav_16k)/16000:.2f}s, shape={wav_16k.shape}"
    )
    logger.info(f"  Words: {words_ref}")

    # Step 1: Word → IPA (phonemizer)
    logger.info("-" * 60)
    logger.info("Step 1: Converting words to reference phonemes")
    ph_ref_ipa, per_word_ipa, ph_ref_simple_from_words, ph_by_word_simple = (
        words_to_ipa_direct(words_ref)
    )
    logger.info(
        f"  → Reference IPA phonemes ({len(ph_ref_ipa)}): "
        f"{ph_ref_ipa[:30]}{'...' if len(ph_ref_ipa) > 30 else ''}"
    )

    ref_simple = ph_ref_simple_from_words
    if not ref_simple and ph_ref_ipa:
        ref_simple = ipa_list_to_simple_seq_direct(ph_ref_ipa)

    # Step 2: Audio → phoneme IDs → IPA
    logger.info("-" * 60)
    logger.info("Step 2: Decoding audio to IPA phonemes (Wav2Vec2)")
    ids, _, top_k_ids = audio_to_phoneme_ids(wav_16k, top_k=3)

    ph_pred_list, ph_pred_text = decode_ids_to_phones(ids)
    logger.info(
        f"  → Predicted IPA phonemes ({len(ph_pred_list)}): "
        f"{ph_pred_list[:30]}{'...' if len(ph_pred_list) > 30 else ''}"
    )
    logger.debug(
        f"  → Predicted text: '{ph_pred_text[:200]}{'...' if len(ph_pred_text) > 200 else ''}'"
    )
    
    # Step 3: Normalize predicted IPA phonemes
    logger.info("-" * 60)
    logger.info("Step 3: Normalizing predicted IPA phonemes")
    ph_pred_normalized = [normalize_espeak_token(ph) for ph in ph_pred_list if ph]
    ph_pred_normalized = [ph for ph in ph_pred_normalized if ph]  # Bỏ các phoneme rỗng sau normalize
    logger.info(
        f"  → Normalized IPA phonemes ({len(ph_pred_normalized)}): "
        f"{ph_pred_normalized[:30]}{'...' if len(ph_pred_normalized) > 30 else ''}"
    )
    
    # Convert sang simple-IPA
    pred_simple = ipa_list_to_simple_seq(ph_pred_list)

    # Phoneme correctness cho UI (dùng simple-IPA per word)
    flat_simple_ref: list[str] = []
    lengths: list[int] = []
    for seq in ph_by_word_simple:
        lengths.append(len(seq))
        flat_simple_ref.extend(seq)

    phoneme_match_flags_flat = compute_phoneme_match_flags(
        flat_simple_ref, pred_simple
    )
    phoneme_correctness_by_word = split_flags_by_lengths(
        phoneme_match_flags_flat, lengths
    )

    # Step 4: PER / Accuracy
    logger.info("-" * 60)
    logger.info("Step 4: Calculating phoneme accuracy (PER)")
    logger.info(f"  → Reference simple-IPA ({len(ref_simple)}): {ref_simple}")
    logger.info(f"  → Predicted simple-IPA ({len(pred_simple)}): {pred_simple}")
    per = sequence_per(ref_simple, pred_simple)
    accuracy_ph = (1 - per) * 100.0
    logger.info(f"  → Phoneme Error Rate (PER): {per:.3f}")
    logger.info(f"  → Phoneme Accuracy: {accuracy_ph:.1f}%")

    # Step 5: Completeness (dựa trên simple-IPA per word)
    logger.info("-" * 60)
    logger.info("Step 5: Calculating word completeness")
    covered = 0
    total = len(ph_by_word_simple)
    for word_idx, seq in enumerate(ph_by_word_simple):
        is_covered = word_covered(seq, pred_simple, phoneme_format="simple")
        if is_covered:
            covered += 1
        logger.debug(
            f"  Word '{words_ref[word_idx] if word_idx < len(words_ref) else '?'}': "
            f"{'✅ covered' if is_covered else '❌ not covered'}"
        )

    completeness = 100.0 * covered / max(1, total)
    logger.info(
        f"  → Completeness: {completeness:.1f}% ({covered}/{total} words covered)"
    )

    # Step 6: Fluency
    logger.info("-" * 60)
    logger.info("Step 6: Calculating fluency metrics")
    fluency_metrics = calculate_fluency(wav_16k, words_ref, ph_pred_list, per_word_ipa)
    logger.info(
        f"  → Speech rate: {fluency_metrics['speech_rate']:.2f} words/second"
    )
    logger.info(f"  → Pause ratio: {fluency_metrics['pause_ratio']:.2%}")
    logger.info(f"  → Fluency score: {fluency_metrics['fluency_score']:.1f}%")

    logger.info("=" * 60)
    logger.info("Assessment Summary:")
    logger.info(f"  Accuracy:    {accuracy_ph:.1f}%")
    logger.info(f"  Completeness: {completeness:.1f}%")
    logger.info(f"  Fluency:     {fluency_metrics['fluency_score']:.1f}%")
    logger.info("=" * 60)

    return {
        "accuracy_ph": accuracy_ph,
        "completeness": completeness,
        "fluency": fluency_metrics["fluency_score"],
        "speech_rate": fluency_metrics["speech_rate"],
        "pause_ratio": fluency_metrics["pause_ratio"],
        "ph_ref_flat": ph_ref_simple_from_words,
        "ph_by_word_simple": ph_by_word_simple,
        "ph_by_word_arpa": [],  # Empty list since G2P is removed
        "phoneme_correctness": phoneme_correctness_by_word,
        "per_word_ipa": per_word_ipa,
        "ph_by_word_ipa": per_word_ipa,
        "ph_ref_ipa": ph_ref_ipa,
        "ph_pred_list": ph_pred_list,
        "ph_pred_text": ph_pred_text,
        "per": per,
    }
