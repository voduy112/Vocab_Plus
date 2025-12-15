"""
Pronunciation Assessment API

Cách so sánh Text và Audio để chấm điểm:

1. TEXT → PHONEMES (Expected):
   - Dùng G2P (Grapheme-to-Phoneme) để chuyển text thành phonemes mong đợi
   - Ví dụ: "beautiful" → ["B", "IY", "UW", "T", "AH", "F", "AH", "L"]

2. AUDIO → ALIGNMENT & SCORES:
   - Dùng Wav2Vec2-CTC để align audio với text reference
   - Với mỗi phoneme mong đợi:
     a. Tìm segment tương ứng trong audio (dựa trên alignment)
     b. Tính GOP-lite score: so sánh log-probability của ký tự trong segment
        với phoneme mong đợi
     c. Score cao (80-100) = phát âm đúng
        Score trung bình (60-79) = phát âm gần đúng
        Score thấp (<60) = phát âm sai

3. CHẤM ĐIỂM:
   - Accuracy: Phoneme Error Rate (PER) dựa trên weighted edit distance
   - Completeness: Tỷ lệ từ được phát âm đúng (coverage)
   - Fluency: Dựa trên 3 yếu tố:
     * Speech rate: tốc độ nói (số từ/giây)
     * Pause ratio: tỷ lệ thời gian im lặng
     * Rhythm consistency: độ đều đặn của phoneme
   - Overall: Weighted combination của 3 metrics trên (0.4*accuracy + 0.4*fluency + 0.2*completeness)

Lưu ý: Không nhận diện phonemes thực tế từ audio, mà so sánh audio với phonemes
mong đợi từ text để tính score. Đây là phương pháp "forced alignment" với scoring.
"""

from fastapi import FastAPI, UploadFile, File, Form
from fastapi.responses import JSONResponse
import io, numpy as np, soundfile as sf, re
import logging
from ctc_segm import assess_pronunciation, words_to_phonemes, word_covered, ipa_list_to_simple_seq

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s'
)
logger = logging.getLogger(__name__)
# Reduce noise from multipart library
logging.getLogger("python_multipart").setLevel(logging.WARNING)

app = FastAPI()
logger.info("FastAPI app initialized")

def normalize_words(text: str):
    return [w for w in re.sub(r'[^a-zA-Z\s]', ' ', text.lower()).split() if w]

def resample_to_16k(mono: np.ndarray, sr: int) -> np.ndarray:
    target_sr = 16000
    if sr == target_sr:
        return mono.astype("float32", copy=False)
    if len(mono) == 0:
        return mono.astype("float32", copy=False)
    new_len = int(round(len(mono) * target_sr / float(sr)))
    x_old = np.linspace(0.0, 1.0, num=len(mono), endpoint=False, dtype=np.float32)
    x_new = np.linspace(0.0, 1.0, num=max(1, new_len), endpoint=False, dtype=np.float32)
    mono_16k = np.interp(x_new, x_old, mono.astype("float32")).astype("float32")
    return mono_16k

@app.post("/align")
async def align(
    audio: UploadFile = File(...),
    referenceText: str = Form(...),
    languageCode: str = Form("en-US"),
):
    logger.info(f"Received alignment request: referenceText='{referenceText}', languageCode='{languageCode}'")
    try:
        logger.debug("Reading audio file...")
        wav_bytes = await audio.read()
        logger.debug(f"Audio file size: {len(wav_bytes)} bytes")
        if not wav_bytes or len(wav_bytes) < 100:
            return JSONResponse(
                {
                    "error": "invalid_audio",
                    "detail": "Audio file is empty or too small",
                },
                status_code=400,
            )
        
        audio_f, sr = sf.read(io.BytesIO(wav_bytes), dtype="float32", always_2d=True)
        mono = audio_f.mean(axis=1)
        mono = resample_to_16k(mono, sr)

        # Validate audio length (require at least 0.2s) and non-silence
        duration_ms = int(round(mono.size / 16000.0 * 1000))
        if mono.size < int(0.2 * 16000):
            return JSONResponse(
                {
                    "error": "audio_too_short",
                    "detail": "Audio must be >= 0.2s",
                    "durationMs": duration_ms,
                },
                status_code=400,
            )
        rms = float(np.sqrt(np.mean(np.square(mono))) or 0.0)
        if rms < 1e-4:  # near-silent recording
            return JSONResponse(
                {
                    "error": "audio_silent",
                    "detail": "Audio level too low",
                    "durationMs": duration_ms,
                    "rms": rms,
                },
                status_code=400,
            )

        words_ref = normalize_words(referenceText)
        if not words_ref:
            return JSONResponse(
                {
                    "error": "invalid_text",
                    "detail": "Reference text contains no valid words",
                },
                status_code=400,
            )

        # ===== Phoneme sequence assessment =====
        # Cách mới: So sánh ARPAbet (từ G2P) vs IPA (từ model) bằng edit distance
        logger.info("Starting phoneme sequence assessment...")
        logger.info("  Process: Audio → IPA phonemes → Compare with ARPAbet (G2P) → Scores")
        
        result = assess_pronunciation(mono, words_ref)
        
        accuracy_ph = result["accuracy_ph"]
        completeness = result["completeness"]
        fluency = result["fluency"]  # Sử dụng fluency từ calculate_fluency()
        speech_rate = result.get("speech_rate", 0.0)
        pause_ratio = result.get("pause_ratio", 0.0)
        rhythm_score = result.get("rhythm_score", 0.0)
        
        duration_ms = int(round(mono.size / 16000.0 * 1000))
        
        logger.info(f"Assessment results: accuracy={accuracy_ph:.1f}%, completeness={completeness:.1f}%, "
                   f"fluency={fluency:.1f}% (speech_rate={speech_rate:.2f} wps, pause={pause_ratio:.2%}, rhythm={rhythm_score:.1f}%)")

        # Overall score: weighted combination
        overall = 0.4 * accuracy_ph + 0.4 * fluency + 0.2 * completeness
        logger.info(f"Overall score: {overall:.1f}% (0.4*accuracy + 0.4*fluency + 0.2*completeness)")

        # Build words response (simplified - no timings)
        words_response = []
        ph_ref_flat = result["ph_ref_flat"]
        # Sử dụng IPA thay vì ARPABET
        ph_by_word = result.get("ph_by_word_ipa")
        if not ph_by_word:
            # Fallback: nếu không có IPA, dùng ARPABET nhưng log warning
            logger.warning("ph_by_word_ipa not found, falling back to ARPABET")
            _, ph_by_word = words_to_phonemes(words_ref)
        phoneme_correctness = result.get("phoneme_correctness") or []
        
        # Tính word scores dựa trên phoneme coverage
        word_scores = []
        ph_idx = 0
        for word_idx, word in enumerate(words_ref):
            word_ph_count = len(ph_by_word[word_idx]) if word_idx < len(ph_by_word) else 0
            # Word score = average của phoneme accuracy (đơn giản hóa)
            word_score = accuracy_ph  # Tạm thời dùng accuracy_ph cho tất cả words
            word_scores.append(word_score)
            
            words_response.append({
                "text": word,
                "start": 0,  # No timing available
                "end": duration_ms,
                "score": round(word_score, 1)
            })

        # Build phonemes response (simplified)
        phonemes_response = []
        ph_idx = 0
        for word_idx, word_ph_list in enumerate(ph_by_word):
            correctness_for_word = (
                phoneme_correctness[word_idx]
                if word_idx < len(phoneme_correctness)
                else []
            )
            logger.info(f"[RESULT][WORD #{word_idx}] '{words_ref[word_idx] if word_idx < len(words_ref) else '?'}'")
            for ph_idx, ph in enumerate(word_ph_list):
                is_correct = (
                    correctness_for_word[ph_idx]
                    if ph_idx < len(correctness_for_word)
                    else False
                )
                phonemes_response.append({
                    "wordIndex": word_idx,
                    "p": ph,
                    "start": 0,  # No timing available
                    "end": duration_ms,
                    "score": 100.0 if is_correct else 0.0,
                    "isCorrect": is_correct
                })
                logger.info(
                    f"    Phoneme {ph_idx:02d}: {ph:<4} -> {'✅' if is_correct else '❌'}"
                )

        # Build mistakes: words with low completeness
        mistakes = []
        pred_simple = ipa_list_to_simple_seq(result["ph_pred_list"])
        for word_idx, word in enumerate(words_ref):
            # Check if word is covered (from completeness calculation)
            ph_seq_word = ph_by_word[word_idx] if word_idx < len(ph_by_word) else []
            correctness_for_word = (
                phoneme_correctness[word_idx]
                if word_idx < len(phoneme_correctness)
                else []
            )
            
            if not word_covered(ph_seq_word, pred_simple):
                mistakes.append({
                    "wordIndex": word_idx,
                    "word": word,
                    "wordScore": round(accuracy_ph, 1),
                    "start": 0,
                    "end": duration_ms,
                    "phonemes": [
                        {
                            "p": ph,
                            "score": 100.0 if (
                                ph_idx < len(correctness_for_word)
                                and correctness_for_word[ph_idx]
                            ) else 0.0,
                            "isCorrect": correctness_for_word[ph_idx]
                            if ph_idx < len(correctness_for_word)
                            else False,
                            "start": 0,
                            "end": duration_ms
                        }
                        for ph_idx, ph in enumerate(ph_seq_word)
                    ]
                })

        logger.info(f"Found {len(mistakes)} words with low coverage")

        return JSONResponse({
            "overall": round(overall, 1),
            "accuracy": round(accuracy_ph, 1),
            "fluency": round(fluency, 1),
            "completeness": round(completeness, 1),
            "wordAccuracy": round(accuracy_ph, 1),  # Simplified
            "words": words_response,
            "phonemes": phonemes_response,
            "mistakes": mistakes
        })
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        logger.error(f"[ALIGNER][ERROR] {str(e)}")
        logger.error(f"[ALIGNER][TRACEBACK] {error_trace}")
        # Also print to stdout for docker logs
        print(f"[ALIGNER][ERROR] {str(e)}")
        print(f"[ALIGNER][TRACEBACK] {error_trace}")
        return JSONResponse(
            {
                "error": "internal_error",
                "detail": str(e),
                "type": type(e).__name__,
            },
            status_code=500,
        )

