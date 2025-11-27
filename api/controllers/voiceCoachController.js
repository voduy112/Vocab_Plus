const axios = require("axios");

const voiceCoachController = {
  /**
   * Tạo audio từ text sử dụng Google Text-to-Speech (gTTS)
   * GET /voice-coach/audio?text=hello&language=en-US
   */
  getAudio: async (req, res) => {
    try {
      const { text, language = "en-US" } = req.query;

      // Validate input
      if (!text || text.trim().length === 0) {
        return res.status(400).json({
          error: "text_required",
          detail: "Query parameter 'text' is required",
        });
      }

      // Validate text length (giới hạn để tránh abuse)
      if (text.length > 500) {
        return res.status(400).json({
          error: "text_too_long",
          detail: "Text must be less than 500 characters",
        });
      }

      // Map language code (en-US -> en)
      const langCode = language.split("-")[0] || "en";

      console.log(`[VoiceCoach] Generating audio for: "${text}" (${langCode})`);

      // Sử dụng Google Translate TTS API (miễn phí, không cần API key)
      // Endpoint: https://translate.google.com/translate_tts
      const ttsUrl = `https://translate.google.com/translate_tts?ie=UTF-8&tl=${langCode}&client=tw-ob&q=${encodeURIComponent(
        text
      )}`;

      console.log(`[VoiceCoach] Requesting audio from Google TTS...`);
      const requestStartTime = Date.now();

      try {
        // Tải audio từ Google TTS
        const response = await axios.get(ttsUrl, {
          responseType: "arraybuffer",
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
          },
          timeout: 10000, // 10 seconds
        });

        const requestDuration = Date.now() - requestStartTime;
        const audioSize = response.data ? Buffer.from(response.data).length : 0;

        console.log(
          `[VoiceCoach] Audio downloaded successfully: ${audioSize} bytes (${(
            audioSize / 1024
          ).toFixed(2)} KB) in ${requestDuration}ms`
        );

        if (response.status === 200 && response.data) {
          // Set headers để trả về audio file
          res.setHeader("Content-Type", "audio/mpeg");
          res.setHeader(
            "Content-Disposition",
            `inline; filename="voice_coach_${Date.now()}.mp3"`
          );
          res.setHeader("Cache-Control", "public, max-age=31536000"); // Cache 1 year

          // Trả về audio data
          const audioBuffer = Buffer.from(response.data);
          console.log(
            `[VoiceCoach] Sending audio to client: ${audioBuffer.length} bytes`
          );

          res.send(audioBuffer);

          console.log(`[VoiceCoach] ✅ Audio sent successfully for: "${text}"`);
          return;
        } else {
          throw new Error("Failed to fetch audio from TTS service");
        }
      } catch (ttsError) {
        const requestDuration = Date.now() - requestStartTime;
        console.error(
          `[VoiceCoach] ❌ TTS error after ${requestDuration}ms:`,
          ttsError.message
        );

        if (ttsError.response) {
          console.error(
            `[VoiceCoach] Response status: ${ttsError.response.status}`,
            `Response data: ${ttsError.response.data ? "present" : "empty"}`
          );
        }

        if (ttsError.code) {
          console.error(`[VoiceCoach] Error code: ${ttsError.code}`);
        }

        // Fallback: Trả về error nhưng không crash
        return res.status(503).json({
          error: "tts_service_unavailable",
          detail: "Text-to-speech service is temporarily unavailable",
          message: ttsError.message,
        });
      }
    } catch (e) {
      console.error("[VoiceCoach][ERROR]", e);

      return res.status(500).json({
        error: "internal_error",
        detail: e?.message || "Unknown error occurred",
      });
    }
  },
};

module.exports = voiceCoachController;
