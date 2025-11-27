const express = require("express");
const router = express.Router();
const voiceCoachController = require("../controllers/voiceCoachController");

// GET /voice-coach/audio?text=hello&language=en-US
// Trả về file audio (MP3 format)
router.get("/audio", voiceCoachController.getAudio);

module.exports = router;
