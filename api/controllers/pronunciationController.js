const axios = require("axios");
const FormData = require("form-data");

const pronunciationController = {
  assessPronunciation: async (req, res) => {
    // Khai báo ALIGNER_URL ở đầu function để có thể dùng trong catch block
    const ALIGNER_URL =
      process.env.ALIGNER_URL || "http://vocab-plus-aligner:8000";

    try {
      // Debug: Log request info
      console.log("[API] Request received:", {
        method: req.method,
        url: req.url,
        headers: {
          "content-type": req.headers["content-type"],
          "content-length": req.headers["content-length"],
        },
        body: req.body,
        hasFile: !!req.file,
        fileInfo: req.file
          ? {
              fieldname: req.file.fieldname,
              originalname: req.file.originalname,
              mimetype: req.file.mimetype,
              size: req.file.size,
              hasBuffer: !!req.file.buffer,
            }
          : null,
      });

      const { referenceText, languageCode = "en-US" } = req.body;
      if (!req.file || !referenceText) {
        console.error("[API] Missing required fields:", {
          hasFile: !!req.file,
          referenceText: !!referenceText,
          body: req.body,
        });
        return res
          .status(400)
          .json({ error: "audio + referenceText required" });
      }

      // Validate file size (minimum ~2KB for valid audio)
      if (req.file.size < 2000) {
        return res.status(400).json({
          error: "audio_too_small",
          detail: "Audio file too small (minimum 2KB)",
        });
      }

      // Validate file format
      // Python aligner uses soundfile which supports: WAV, FLAC, OGG, AIFF, etc.
      // Recommended: WAV 16kHz mono PCM for best compatibility
      const supportedMimeTypes = [
        "audio/wav",
        "audio/wave",
        "audio/x-wav",
        "audio/flac",
        "audio/ogg",
        "audio/aiff",
        "audio/x-aiff",
      ];
      const fileExt = req.file.originalname?.split(".").pop()?.toLowerCase();
      const isSupportedExt = ["wav", "flac", "ogg", "aiff", "aif"].includes(
        fileExt
      );
      const isSupportedMime =
        !req.file.mimetype ||
        supportedMimeTypes.includes(req.file.mimetype.toLowerCase());

      // Debug: log incoming file meta
      try {
        console.log(
          "[API] Incoming audio:",
          {
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
            hasBuffer: !!req.file.buffer,
            ext: fileExt,
            isSupportedExt,
            isSupportedMime,
          },
          { referenceText, languageCode }
        );
      } catch {}

      // Warn but don't reject if format is unknown (let Python aligner handle it)
      if (!isSupportedExt && !isSupportedMime) {
        console.warn(
          "[API] Unknown audio format:",
          req.file.mimetype,
          fileExt,
          "- forwarding to aligner anyway"
        );
      }

      // forward sang Python aligner
      const form = new FormData();
      form.append("audio", req.file.buffer, {
        filename: req.file.originalname || "audio.wav",
        contentType: req.file.mimetype || "audio/wav",
      });
      form.append("referenceText", referenceText);
      form.append("languageCode", languageCode);

      const r = await axios.post(ALIGNER_URL + "/align", form, {
        headers: form.getHeaders(),
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
        timeout: 60000, // 60 seconds timeout
      });

      // (tuỳ chọn) lưu DB ở đây
      return res.json(r.data);
    } catch (e) {
      // Log chi tiết hơn để debug
      const errorDetails = {
        status: e?.response?.status,
        statusText: e?.response?.statusText,
        data: e?.response?.data,
        message: e?.message,
        code: e?.code,
        url: ALIGNER_URL + "/align",
      };

      console.error("[API][align_failed]", errorDetails);

      // Nếu aligner trả về lỗi cụ thể, forward nó
      if (e?.response?.status && e?.response?.data) {
        return res.status(e.response.status).json({
          error: "align_failed",
          detail:
            e.response.data?.detail ||
            e.response.data?.error ||
            e.response.data,
          alignerError: e.response.data,
        });
      }

      // Lỗi network hoặc timeout
      if (e?.code === "ECONNREFUSED" || e?.code === "ETIMEDOUT") {
        return res.status(503).json({
          error: "aligner_unavailable",
          detail: `Cannot connect to aligner service at ${ALIGNER_URL}. Is it running?`,
        });
      }

      return res.status(500).json({
        error: "align_failed",
        detail: e?.message || "Unknown error",
        code: e?.code,
      });
    }
  },
};

module.exports = pronunciationController;
