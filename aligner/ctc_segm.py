import logging
import math
import os
import numpy as np
import torch
import torch.nn.functional as F

from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
from g2p_en import G2p

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s'
)
logger = logging.getLogger(__name__)

# ---------- Load model (singleton) ----------
logger.info("Initializing phoneme CTC model...")
_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
logger.info(f"Using device: {_device}")

# Model: facebook/wav2vec2-lv-60-espeak-cv-ft
# Output: IPA phonemes (m ɪ s t ɚ k w ɪ l t ɚ ...)
# Model được tải sẵn vào Docker image tại /opt/phoneme_model (offline, không cần internet)
MODEL_NAME = "/opt/phoneme_model"

# Verify model directory exists
if not os.path.exists(MODEL_NAME):
    raise FileNotFoundError(
        f"Model directory not found at {MODEL_NAME}. "
        "Make sure the model was downloaded during Docker build."
    )

if not os.path.isdir(MODEL_NAME):
    raise ValueError(f"{MODEL_NAME} exists but is not a directory")

# Check required files
required_files = ["config.json", "preprocessor_config.json"]
missing_files = [f for f in required_files if not os.path.exists(os.path.join(MODEL_NAME, f))]

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
    _processor = Wav2Vec2Processor.from_pretrained(MODEL_NAME, local_files_only=True)

    logger.info(f"Loading Wav2Vec2ForCTC model from local path: {MODEL_NAME}")
    try:
        _model = Wav2Vec2ForCTC.from_pretrained(MODEL_NAME, local_files_only=True).to(_device).eval()
    except Exception as load_error:
        logger.warning(f"Failed to load with local_files_only: {load_error}")
        logger.info("Attempting to load without local_files_only (may download missing files)...")
        _model = Wav2Vec2ForCTC.from_pretrained(MODEL_NAME).to(_device).eval()

    logger.info("Phoneme CTC model loaded successfully (offline mode)")
except Exception as e:
    logger.error(f"Failed to load phoneme model from {MODEL_NAME}: {e}")
    logger.error("Make sure the model was downloaded and copied to Docker image")
    raise

logger.info("Loading G2p (ARPAbet)...")
_g2p = G2p()

logger.info("All models (ASR phoneme + G2P) loaded successfully")


# ---------- ARPAbet to IPA mapping ----------
ARPABET_TO_IPA_BASE = {
    "B":  "b",
    "P":  "p",
    "T":  "t",
    "D":  "d",
    "K":  "k",
    "G":  "ɡ",
    "F":  "f",
    "V":  "v",
    "TH": "θ",
    "DH": "ð",
    "S":  "s",
    "Z":  "z",
    "SH": "ʃ",
    "ZH": "ʒ",
    "CH": "tʃ",
    "JH": "dʒ",
    "M":  "m",
    "N":  "n",
    "NG": "ŋ",
    "L":  "l",
    "R":  "ɹ",
    "Y":  "j",
    "W":  "w",
    # Vowels:
    "IY": "i",
    "IH": "ɪ",
    "EY": "e",
    "EH": "ɛ",
    "AE": "æ",
    "AA": "ɑ",
    "AH": "ə",
    "AO": "ɔ",
    "UH": "ʊ",
    "UW": "u",
    "ER": "ɝ",
    "OW": "o",
    "AY": "aɪ",
    "AW": "aʊ",
    "OY": "ɔɪ",
}


# ---------- Core functions ----------
def audio_to_phoneme_ids(wav_16k: np.ndarray, top_k: int = 1) -> tuple[np.ndarray, np.ndarray, list[list[int]]]:
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
        
        # Get top-k predictions for each timestep
        top_k_probs, top_k_ids_tensor = torch.topk(log_probs, k=min(top_k, log_probs.size(-1)), dim=-1)  # [T, top_k]
        top_k_ids = top_k_ids_tensor.cpu().numpy().tolist()  # [[id1, id2, ...], ...]
    
    return best_ids.cpu().numpy(), log_probs.cpu().numpy(), top_k_ids


def decode_ids_to_phones(ids: np.ndarray) -> tuple[list[str], str]:
    """Decode phoneme IDs to IPA phoneme list and text."""
    tensor_ids = torch.from_numpy(ids).unsqueeze(0).long()
    text = _processor.batch_decode(tensor_ids, skip_special_tokens=True)[0]
    phones = []
    for p in text.split(" "):
        p = p.strip()
        if p:
            phones.append(p)
    return phones, text


def decode_multiple_candidates(top_k_ids: list[list[int]], ref_simple: list[str], max_candidates: int = 5) -> list[tuple[list[str], float]]:
    """
    Decode multiple candidate sequences from top-k predictions and score them.
    
    Args:
        top_k_ids: list of top-k IDs per timestep [[id1, id2, ...], ...]
        ref_simple: reference simple sequence for scoring
        max_candidates: maximum number of candidates to evaluate
    
    Returns:
        List of (candidate_sequence, score) tuples, sorted by score (best first)
    """
    if not top_k_ids:
        return []
    
    T = len(top_k_ids)
    
    # Generate candidate from ID choices
    def generate_candidate(choices: list[int]) -> list[str]:
        """Generate phoneme sequence from ID choices."""
        ids_array = np.array(choices)
        phones, _ = decode_ids_to_phones(ids_array)
        return ipa_list_to_simple_seq(phones)
    
    # Try greedy: always pick top-1
    greedy_choices = [ids[0] for ids in top_k_ids]
    greedy_seq = generate_candidate(greedy_choices)
    greedy_score = 1.0 - (sequence_per(ref_simple, greedy_seq) if ref_simple else 1.0)
    candidates = [(greedy_seq, greedy_score)]
    
    # Try variations: at each position, try top-2 if available
    if max_candidates > 1:
        for pos in range(min(T, 3)):  # Only try first 3 positions to limit combinations
            if len(top_k_ids[pos]) >= 2:
                variant_choices = greedy_choices.copy()
                variant_choices[pos] = top_k_ids[pos][1]  # Try second best at this position
                variant_seq = generate_candidate(variant_choices)
                variant_score = 1.0 - (sequence_per(ref_simple, variant_seq) if ref_simple else 1.0)
                candidates.append((variant_seq, variant_score))
    
    # Remove duplicates and sort by score
    seen = set()
    unique_candidates = []
    for seq, score in candidates:
        seq_tuple = tuple(seq)
        if seq_tuple not in seen:
            seen.add(seq_tuple)
            unique_candidates.append((seq, score))
    
    # Sort by score (best first) and limit
    unique_candidates.sort(key=lambda x: x[1], reverse=True)
    return unique_candidates[:max_candidates]


def words_to_phonemes(words: list[str]) -> tuple[list[str], list[list[str]]]:
    """
    Convert words to ARPAbet phonemes using G2P (for completeness calculation).
    """
    logger.debug(f"words_to_phonemes: input words={words}")
    phs = []
    per_word = []
    for w in words:
        g2p_output = _g2p(w)
        logger.debug(f"words_to_phonemes: word '{w}' -> G2P raw output: {g2p_output}")
        seq = []
        for s in g2p_output:
            ph_clean = ''.join(c for c in s if c.isalpha())
            if ph_clean and ph_clean.isupper():
                seq.append(ph_clean)
        logger.debug(f"words_to_phonemes: word '{w}' -> filtered phonemes {seq}")
        if not seq:
            logger.warning(f"words_to_phonemes: No valid phonemes found for word '{w}', G2P output: {g2p_output}")
        per_word.append(seq)
        phs.extend(seq)
    logger.debug(f"words_to_phonemes: total phonemes={len(phs)}, per_word={per_word}")
    return phs, per_word


def words_to_ipa_direct(words: list[str]) -> tuple[list[str], list[list[str]], list[str], list[list[str]]]:
    """
    Convert words to IPA using ARPAbet + ARPABET_TO_IPA_BASE.
    Không phụ thuộc phonemizer để tránh lỗi 'language "en" is not supported'.
    
    Returns:
        (phs_ipa, per_word_ipa, ph_ref_flat, ph_by_word_arpa)
        - phs_ipa: flat list of IPA phonemes
        - per_word_ipa: IPA phonemes per word
        - ph_ref_flat: flat list of ARPAbet phonemes (for completeness)
        - ph_by_word_arpa: ARPAbet phonemes per word (for completeness)
    """
    logger.debug(f"words_to_ipa_direct (ARPAbet-based): input words={words}")

    # Lấy ARPAbet cho toàn câu + từng từ (chỉ gọi 1 lần)
    ph_ref_flat, ph_by_word_arpa = words_to_phonemes(words)

    phs_ipa: list[str] = []
    per_word_ipa: list[list[str]] = []

    # Flat list IPA
    for ph in ph_ref_flat:
        ipa = ARPABET_TO_IPA_BASE.get(ph, "")
        if ipa:
            phs_ipa.append(ipa)
        else:
            logger.debug(f"words_to_ipa_direct: no IPA mapping for ARPAbet '{ph}'")

    # Per-word IPA
    for seq_arpa in ph_by_word_arpa:
        word_ipa: list[str] = []
        for ph in seq_arpa:
            ipa = ARPABET_TO_IPA_BASE.get(ph, "")
            if ipa:
                word_ipa.append(ipa)
        per_word_ipa.append(word_ipa)

    logger.debug(f"words_to_ipa_direct: total IPA phonemes={len(phs_ipa)}, per_word={per_word_ipa}")
    return phs_ipa, per_word_ipa, ph_ref_flat, ph_by_word_arpa


# ---------- IPA simplification / grouping ----------
IPA_SIMPLE_MAP = {
    "ə": "ʌ",
    "ɐ": "ʌ",
    "ʌ": "ʌ",
    "i": "i",
    "ɪ": "i",
    "e": "e",
    "ɛ": "e",
    "u": "u",
    "ʊ": "u",
    "ɔ": "ɔ",
    "o": "ɔ",
    "ɝ": "ɝ",
    "ɚ": "ɝ",
}


# Pre-compiled mapping for faster lookup
_ESPEAK_NORMALIZE_MAP = {
    "ɑ5": "ɝ",
    "ɚ": "ɝ",
    "ɝ˞": "ɝ",
    "ɾ": "t",
    "ᵻ": "ɪ",
    "kh": "k",
    "kʰ": "k",
    "ph": "p",
    "pʰ": "p",
    "th": "t",
    "tʰ": "t",
}


def normalize_espeak_token(token: str) -> str:
    """
    Chuẩn hóa 1 phoneme từ espeak-style về dạng IPA đơn giản hơn.
    Xử lý r-colored vowels, syllabic r, aspirated stops, v.v.
    """
    if not token:
        return ""
    
    t = token.strip()
    if not t:
        return ""

    # Map một số pattern đặc biệt TRƯỚC khi xoá digit/diacritics
    t = _ESPEAK_NORMALIZE_MAP.get(t, t)

    # syllabic r: ɹ̩, ɹ̩˞ -> ɹ (check after mapping)
    if "ɹ" in t and "̩" in t:
        t = "ɹ"

    # Bỏ số stress / tone (0, 1, 2, 5...)
    t = "".join(ch for ch in t if not ch.isdigit())

    # Loại bỏ diacritics (Combining Diacritical Marks U+0300–U+036F)
    t = "".join(ch for ch in t if not (0x0300 <= ord(ch) <= 0x036F))

    # Check aspirated stops again after removing diacritics
    t = _ESPEAK_NORMALIZE_MAP.get(t, t)

    return t


def _simple_ipa_char(ch: str) -> str:
    if not ch:
        return ch
    base_char = ch[0]
    return IPA_SIMPLE_MAP.get(base_char, base_char)


def arpa_to_simple_seq(ph_ref_flat: list[str]) -> list[str]:
    """Convert ARPAbet phonemes to simple IPA sequence (for backward compatibility)."""
    simple = []
    for ph in ph_ref_flat:
        ipa = ARPABET_TO_IPA_BASE.get(ph, "")
        if not ipa:
            continue
        ch = ipa[0]
        ch = _simple_ipa_char(ch)
        simple.append(ch)
    return simple


def ipa_list_to_simple_seq_direct(ph_ipa_list: list[str]) -> list[str]:
    """
    Convert IPA phoneme list directly to simple sequence (grouped).
    Không qua ARPAbet mapping.
    """
    simple = []
    for ph in ph_ipa_list:
        if not ph:
            continue
        # Normalize espeak token first
        ph_norm = normalize_espeak_token(ph)
        if not ph_norm:
            continue
        # Get first character and group
        ch = ph_norm[0]
        if ch:
            simple.append(_simple_ipa_char(ch))
    return simple


def ipa_list_to_simple_seq(ph_pred_list: list[str]) -> list[str]:
    """Convert IPA phoneme list to simple sequence with grouping."""
    simple = []
    for idx, s in enumerate(ph_pred_list):
        if not s:
            continue
        s_norm = normalize_espeak_token(s)
        if not s_norm:
            logger.debug(f"ipa_list_to_simple_seq: [{idx}] '{s}' normalized to empty, skipping")
            continue
        ch_original = s_norm[0]
        if ch_original:
            ch_grouped = _simple_ipa_char(ch_original)
            if ch_original != ch_grouped:
                logger.debug(f"ipa_list_to_simple_seq: [{idx}] '{s}' -> '{s_norm}' -> '{ch_original}' -> grouped '{ch_grouped}'")
            simple.append(ch_grouped)
    return simple


# ---------- Weighted phoneme distance ----------

# Use set for O(1) lookup instead of O(n) tuple search
CONFUSABLE = {
    # --- Plosive T/D vs flap ---
    ("t", "ɾ"), ("ɾ", "t"),
    ("d", "ɾ"), ("ɾ", "d"),

    # --- Vowel centralization / gần nhau ---
    ("ə", "ʌ"), ("ʌ", "ə"),
    ("ə", "ɪ"), ("ɪ", "ə"),
    ("ʌ", "ɪ"), ("ɪ", "ʌ"),

    # --- ih-like vowels ---
    ("ɪ", "ᵻ"), ("ᵻ", "ɪ"),

    # --- oo vs u vs ʊ ---
    ("u", "ʊ"), ("ʊ", "u"),

    # --- o vs ɔ ---
    ("o", "ɔ"), ("ɔ", "o"),

    # --- fricatives gần ---
    ("s", "ʃ"), ("ʃ", "s"),
    ("z", "ʒ"), ("ʒ", "z"),

    # --- nasals ---
    ("n", "ŋ"), ("ŋ", "n"),
    ("n", "m"), ("m", "n"),

    # --- liquids ---
    ("l", "ɹ"), ("ɹ", "l"),

    # --- misc voicing pairs ---
    ("t", "d"), ("d", "t"),
}
CONFUSABLE_SET = set(CONFUSABLE)


def phoneme_sub_cost(a: str, b: str) -> float:
    """Chi phí thay thế giữa 2 phoneme."""
    if a == b:
        return 0.0
    if (a, b) in CONFUSABLE_SET:
        return 0.5  # phát âm gần giống, phạt nửa lỗi
    return 1.0      # khác hẳn, phạt full


def edit_distance_weighted(a: list[str], b: list[str]) -> float:
    """
    Weighted edit distance:
    - insert = 1.0
    - delete = 1.0
    - substitute = 0.0 / 0.5 / 1.0
    """
    m, n = len(a), len(b)
    dp = [[0.0]*(n+1) for _ in range(m+1)]

    # Base cases
    for i in range(1, m+1):
        dp[i][0] = dp[i-1][0] + 1.0  # delete
    for j in range(1, n+1):
        dp[0][j] = dp[0][j-1] + 1.0  # insert

    # DP
    for i in range(1, m+1):
        for j in range(1, n+1):
            dp[i][j] = min(
                dp[i-1][j] + 1.0,                       # delete
                dp[i][j-1] + 1.0,                       # insert
                dp[i-1][j-1] + phoneme_sub_cost(a[i-1], b[j-1])  # substitute
            )

    return dp[m][n]


def edit_distance(a: list, b: list) -> int:
    """
    Legacy unweighted edit distance (vẫn giữ lại nếu chỗ khác cần).
    """
    m, n = len(a), len(b)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(m+1):
        dp[i][0] = i
    for j in range(n+1):
        dp[0][j] = j
    for i in range(1, m+1):
        for j in range(1, n+1):
            dp[i][j] = min(
                dp[i-1][j] + 1,
                dp[i][j-1] + 1,
                dp[i-1][j-1] + (a[i-1] != b[j-1])
            )
    return dp[m][n]


def sequence_per(ref_simple: list[str], pred_simple: list[str]) -> float:
    """
    Tính PER với sliding window trên pred_simple.
    Dùng weighted edit distance để không phạt quá nặng các âm gần giống.
    """
    if not ref_simple:
        # Nếu reference rỗng, coi như tất cả predicted đều sai
        return 1.0 if pred_simple else 0.0

    Lr = len(ref_simple)
    Lp = len(pred_simple)

    # Nếu pred ngắn hơn hoặc bằng -> so trực tiếp
    if Lp <= Lr:
        ed = edit_distance_weighted(ref_simple, pred_simple)
        return ed / max(1, Lr)

    # Nếu pred dài hơn -> sliding window để tránh phạt padding
    min_ed = math.inf
    for i in range(0, Lp - Lr + 1):
        window = pred_simple[i:i+Lr]
        ed = edit_distance_weighted(ref_simple, window)
        if ed < min_ed:
            min_ed = ed

    return min_ed / max(1, Lr)


def word_covered(ph_seq_word: list[str], pred_simple_seq: list[str]) -> bool:
    """
    Check if a word's phonemes are covered in predicted sequence.
    Dùng sliding window + threshold theo độ dài từ.
    """
    if not ph_seq_word:
        return False
    
    ref_simple = arpa_to_simple_seq(ph_seq_word)
    if not ref_simple:
        return False
    
    min_ed = math.inf
    for i in range(0, max(1, len(pred_simple_seq) - len(ref_simple) + 1)):
        window = pred_simple_seq[i:i+len(ref_simple)]
        ed = edit_distance_weighted(ref_simple, window)
        min_ed = min(min_ed, ed)

    # Cho phép sai 1 phoneme cho từ ngắn (<=3)
    if len(ref_simple) <= 3:
        threshold = 1.0
    else:
        threshold = len(ref_simple) * 0.4

    return min_ed <= threshold


def calculate_fluency(wav_16k: np.ndarray, words_ref: list[str], ph_pred_list: list[str]) -> dict:
    """
    Tính độ trôi chảy (fluency) dựa trên:
    1. Speech rate: tốc độ nói (số từ/giây)
    2. Pause ratio: tỷ lệ thời gian im lặng
    3. Rhythm consistency: độ đều đặn của nhịp điệu
    
    Args:
        wav_16k: audio array, float32, mono, 16kHz
        words_ref: danh sách từ tham chiếu
        ph_pred_list: danh sách phoneme dự đoán
    
    Returns:
        dict với các metrics: fluency_score, speech_rate, pause_ratio, rhythm_score
    """
    # 1. Tính thời gian audio (giây)
    audio_duration = len(wav_16k) / 16000.0  # 16kHz sampling rate
    
    if audio_duration <= 0:
        return {
            "fluency_score": 0.0,
            "speech_rate": 0.0,
            "pause_ratio": 1.0,
            "rhythm_score": 0.0,
        }
    
    # 2. Speech rate: số từ / giây
    num_words = len(words_ref)
    speech_rate = num_words / audio_duration if audio_duration > 0 else 0.0
    
    # Speech rate lý tưởng: 2-4 từ/giây (120-240 WPM)
    # Dùng smooth scoring function thay vì hard threshold
    ideal_min, ideal_max = 2.0, 4.0
    acceptable_min, acceptable_max = 1.2, 5.5
    
    if ideal_min <= speech_rate <= ideal_max:
        speech_rate_score = 1.0
    elif acceptable_min <= speech_rate < ideal_min:
        # Chậm hơn lý tưởng nhưng vẫn chấp nhận được
        speech_rate_score = 0.7 + ((speech_rate - acceptable_min) / (ideal_min - acceptable_min)) * 0.3
    elif ideal_max < speech_rate <= acceptable_max:
        # Nhanh hơn lý tưởng nhưng vẫn chấp nhận được
        speech_rate_score = 1.0 - ((speech_rate - ideal_max) / (acceptable_max - ideal_max)) * 0.3
    else:
        # Quá chậm hoặc quá nhanh: phạt nặng hơn
        if speech_rate < acceptable_min:
            speech_rate_score = max(0.3, 0.7 * (speech_rate / acceptable_min))
        else:
            speech_rate_score = max(0.3, 0.7 * (1.0 - (speech_rate - acceptable_max) / acceptable_max))
    
    # 3. Pause ratio: dựa trên năng lượng audio
    # Tính RMS energy để phát hiện pause
    frame_size = 1600  # 100ms tại 16kHz
    num_frames = len(wav_16k) // frame_size
    if num_frames > 0:
        energies = []
        for i in range(num_frames):
            frame = wav_16k[i * frame_size:(i + 1) * frame_size]
            rms = np.sqrt(np.mean(frame ** 2))
            energies.append(rms)
        
        if energies:
            energy_threshold = np.percentile(energies, 20)  # 20% thấp nhất coi là pause
            pause_frames = sum(1 for e in energies if e < energy_threshold)
            pause_ratio = pause_frames / len(energies) if len(energies) > 0 else 0.0
        else:
            pause_ratio = 0.0
    else:
        pause_ratio = 0.0
    
    # Pause ratio hợp lý: 5-35% (mở rộng range để linh hoạt hơn)
    ideal_min, ideal_max = 0.05, 0.35
    acceptable_min, acceptable_max = 0.02, 0.50
    
    if ideal_min <= pause_ratio <= ideal_max:
        pause_score = 1.0
    elif acceptable_min <= pause_ratio < ideal_min:
        # Ít pause hơn lý tưởng nhưng vẫn OK
        pause_score = 0.8 + ((pause_ratio - acceptable_min) / (ideal_min - acceptable_min)) * 0.2
    elif ideal_max < pause_ratio <= acceptable_max:
        # Nhiều pause hơn lý tưởng nhưng vẫn OK
        pause_score = 1.0 - ((pause_ratio - ideal_max) / (acceptable_max - ideal_max)) * 0.3
    else:
        # Quá ít hoặc quá nhiều pause: phạt
        if pause_ratio < acceptable_min:
            pause_score = max(0.4, 0.8 * (pause_ratio / acceptable_min))
        else:
            pause_score = max(0.4, 0.7 * (1.0 - (pause_ratio - acceptable_max) / 0.3))
    
    # 4. Rhythm consistency: độ đều đặn của phoneme
    # Dựa trên số phoneme dự đoán so với reference
    # Sử dụng ph_ref_flat đã tính sẵn từ assess_pronunciation
    # Nhưng vì đây là hàm độc lập, tính lại từ words_ref
    _, ph_by_word_ref = words_to_phonemes(words_ref)
    num_ref_phonemes = sum(len(seq) for seq in ph_by_word_ref)
    num_pred_phonemes = len(ph_pred_list)
    
    if num_ref_phonemes > 0:
        phoneme_ratio = num_pred_phonemes / num_ref_phonemes
        # Tỷ lệ hợp lý: 0.7 - 1.4 (mở rộng để linh hoạt với ASR model)
        ideal_min, ideal_max = 0.7, 1.4
        acceptable_min, acceptable_max = 0.5, 1.8
        
        if ideal_min <= phoneme_ratio <= ideal_max:
            rhythm_score = 1.0
        elif acceptable_min <= phoneme_ratio < ideal_min:
            # Ít phoneme hơn nhưng vẫn chấp nhận được
            rhythm_score = 0.7 + ((phoneme_ratio - acceptable_min) / (ideal_min - acceptable_min)) * 0.3
        elif ideal_max < phoneme_ratio <= acceptable_max:
            # Nhiều phoneme hơn nhưng vẫn chấp nhận được
            rhythm_score = 1.0 - ((phoneme_ratio - ideal_max) / (acceptable_max - ideal_max)) * 0.3
        else:
            # Quá ít hoặc quá nhiều: phạt
            if phoneme_ratio < acceptable_min:
                rhythm_score = max(0.4, 0.7 * (phoneme_ratio / acceptable_min))
            else:
                rhythm_score = max(0.4, 0.7 * (1.0 - (phoneme_ratio - acceptable_max) / acceptable_max))
    else:
        rhythm_score = 0.0
    
    # 5. Fluency score tổng hợp (weighted average)
    # Trọng số: speech_rate 30%, pause 30%, rhythm 40%
    fluency_score = (
        speech_rate_score * 0.3 +
        pause_score * 0.3 +
        rhythm_score * 0.4
    ) * 100.0
    
    phoneme_ratio_display = num_pred_phonemes / num_ref_phonemes if num_ref_phonemes > 0 else 0.0
    logger.debug(f"Fluency calculation details: speech_rate={speech_rate:.2f} wps (score={speech_rate_score:.2f}), "
                 f"pause_ratio={pause_ratio:.2%} (score={pause_score:.2f}), "
                 f"phoneme_ratio={phoneme_ratio_display:.2f} (score={rhythm_score:.2f})")
    
    return {
        "fluency_score": fluency_score,
        "speech_rate": speech_rate,
        "pause_ratio": pause_ratio,
        "rhythm_score": rhythm_score * 100.0,
    }


def assess_pronunciation(wav_16k: np.ndarray, words_ref: list[str]) -> dict:
    logger.info("=" * 60)
    logger.info("Starting pronunciation assessment")
    logger.info(f"  Input: {len(words_ref)} words, audio duration={len(wav_16k)/16000:.2f}s, shape={wav_16k.shape}")
    logger.info(f"  Words: {words_ref}")
    
    # Step 1: Get IPA from words (ARPAbet → IPA) - chỉ gọi G2P 1 lần
    logger.info("-" * 60)
    logger.info("Step 1: Converting words to reference phonemes")
    ph_ref_ipa, _, ph_ref_flat, ph_by_word = words_to_ipa_direct(words_ref)
    logger.info(f"  → Reference IPA phonemes ({len(ph_ref_ipa)}): {ph_ref_ipa[:30]}{'...' if len(ph_ref_ipa) > 30 else ''}")
    logger.info(f"  → Reference ARPAbet phonemes ({len(ph_ref_flat)}): {ph_ref_flat[:30]}{'...' if len(ph_ref_flat) > 30 else ''}")
    
    # Step 2: Build reference simple sequence
    logger.info("-" * 60)
    logger.info("Step 2: Building reference simple sequence")
    if not ph_ref_ipa:
        logger.warning("  ⚠️ IPA reference is empty, using ARPAbet → IPA mapping")
        ref_simple = arpa_to_simple_seq(ph_ref_flat)
    else:
        ref_simple = ipa_list_to_simple_seq_direct(ph_ref_ipa)
    logger.info(f"  → Reference simple sequence (length {len(ref_simple)}): {ref_simple[:40]}{'...' if len(ref_simple) > 40 else ''}")
    
    # Step 3: Model → IPA với top-k predictions
    logger.info("-" * 60)
    logger.info("Step 3: Processing audio with Wav2Vec2 model")
    ids, _, top_k_ids = audio_to_phoneme_ids(wav_16k, top_k=3)
    
    # Decode best candidate (greedy)
    ph_pred_list, ph_pred_text = decode_ids_to_phones(ids)
    logger.info(f"  → Predicted IPA phonemes ({len(ph_pred_list)}): {ph_pred_list[:30]}{'...' if len(ph_pred_list) > 30 else ''}")
    logger.debug(f"  → Predicted text: '{ph_pred_text[:200]}{'...' if len(ph_pred_text) > 200 else ''}'")
    
    # Step 4: Try multiple candidates and pick best match
    logger.info("-" * 60)
    logger.info("Step 4: Evaluating candidate sequences")
    candidates = decode_multiple_candidates(top_k_ids, ref_simple, max_candidates=5)
    
    if candidates:
        logger.info(f"  → Generated {len(candidates)} candidate sequences:")
        for idx, (cand_seq, cand_score) in enumerate(candidates):
            logger.info(f"    Candidate #{idx+1}:")
            logger.info(f"      Score: {cand_score:.3f}")
            logger.info(f"      Length: {len(cand_seq)}")
            logger.info(f"      Sequence: {cand_seq[:50]}{'...' if len(cand_seq) > 50 else ''}")
            if idx == 0:
                logger.info(f"      Status: ✅ Best candidate")
        
        best_seq, best_score = candidates[0]
        logger.info(f"  ✅ Selected best candidate: score={best_score:.3f}")
        pred_simple = best_seq
    else:
        logger.warning("  ⚠️ No candidates generated, using greedy fallback")
        pred_simple = ipa_list_to_simple_seq(ph_pred_list)
    
    logger.info(f"  → Final predicted simple sequence (length {len(pred_simple)}): {pred_simple[:50]}{'...' if len(pred_simple) > 50 else ''}")
    
    # Step 5: Calculate PER với sliding window
    logger.info("-" * 60)
    logger.info("Step 5: Calculating phoneme accuracy (PER)")
    per = sequence_per(ref_simple, pred_simple)
    accuracy_ph = (1 - per) * 100.0
    logger.info(f"  → Phoneme Error Rate (PER): {per:.3f}")
    logger.info(f"  → Phoneme Accuracy: {accuracy_ph:.1f}%")
    
    # Step 6: Calculate Completeness
    logger.info("-" * 60)
    logger.info("Step 6: Calculating word completeness")
    covered = 0
    total = len(ph_by_word)
    for word_idx, seq in enumerate(ph_by_word):
        is_covered = word_covered(seq, pred_simple)
        if is_covered:
            covered += 1
        logger.debug(f"  Word '{words_ref[word_idx] if word_idx < len(words_ref) else '?'}': {'✅ covered' if is_covered else '❌ not covered'}")
    
    completeness = 100.0 * covered / max(1, total)
    logger.info(f"  → Completeness: {completeness:.1f}% ({covered}/{total} words covered)")
    
    # Step 7: Calculate Fluency
    logger.info("-" * 60)
    logger.info("Step 7: Calculating fluency metrics")
    fluency_metrics = calculate_fluency(wav_16k, words_ref, ph_pred_list)
    logger.info(f"  → Speech rate: {fluency_metrics['speech_rate']:.2f} words/second")
    logger.info(f"  → Pause ratio: {fluency_metrics['pause_ratio']:.2%}")
    logger.info(f"  → Rhythm score: {fluency_metrics['rhythm_score']:.1f}%")
    logger.info(f"  → Fluency score: {fluency_metrics['fluency_score']:.1f}%")
    
    # Final summary
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
        "rhythm_score": fluency_metrics["rhythm_score"],
        "ph_ref_flat": ph_ref_flat,
        "ph_pred_list": ph_pred_list,
        "ph_pred_text": ph_pred_text,
        "per": per,
    }
