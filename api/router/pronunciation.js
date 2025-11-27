const express = require("express");
const router = express.Router();
const multer = require("multer");
const pronunciationController = require("../controllers/pronunciationController");

// Cấu hình multer với memory storage để lưu file vào buffer
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
});

// Error handler cho multer
const handleMulterError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    console.error("[API][Multer Error]:", err);
    if (err.code === "LIMIT_FILE_SIZE") {
      return res.status(400).json({
        error: "file_too_large",
        detail: "File size exceeds 15MB limit",
      });
    }
    return res.status(400).json({
      error: "upload_error",
      detail: err.message,
    });
  }
  if (err) {
    console.error("[API][Upload Error]:", err);
    return res.status(500).json({
      error: "upload_error",
      detail: err.message || "Unknown upload error",
    });
  }
  next();
};

router.post(
  "/assess",
  upload.single("audio"),
  handleMulterError,
  pronunciationController.assessPronunciation
);

module.exports = router;
