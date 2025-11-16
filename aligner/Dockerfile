FROM python:3.11-slim
WORKDIR /app

# System deps
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    build-essential gcc g++ python3-dev \
    ffmpeg \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

# Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# NLTK data
RUN python -m nltk.downloader averaged_perceptron_tagger_eng punkt

# ⬇️ Tải model vào /opt/phoneme_model trong lúc build
RUN python - << 'EOF'
from pathlib import Path
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor

MODEL_ID = "facebook/wav2vec2-lv-60-espeak-cv-ft"
TARGET_DIR = Path("/opt/phoneme_model")
TARGET_DIR.mkdir(parents=True, exist_ok=True)

print("Downloading processor...")
processor = Wav2Vec2Processor.from_pretrained(MODEL_ID)
print("Downloading model...")
model = Wav2Vec2ForCTC.from_pretrained(MODEL_ID)

processor.save_pretrained(TARGET_DIR)
model.save_pretrained(TARGET_DIR)

print("Model saved to", TARGET_DIR)
EOF

# ✅ Kiểm tra lại thư mục model tồn tại & có file
RUN ls -R /opt/phoneme_model

# Copy code cuối cùng (để không ghi đè model vì model nằm ở /opt)
COPY . .

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
