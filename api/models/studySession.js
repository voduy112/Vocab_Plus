const mongoose = require("mongoose");

const studySessionSchema = new mongoose.Schema({
  userUid: { type: String, required: true, index: true },
  localId: { type: Number, required: true }, // ID từ SQLite
  deckLocalId: { type: Number, required: true },
  vocabularyLocalId: { type: Number, required: true },
  sessionType: { type: String, required: true }, // 'learn', 'review', 'test'
  result: { type: String, required: true }, // 'correct', 'incorrect', 'skipped'
  timeSpent: { type: Number, default: 0 }, // seconds
  createdAt: { type: Date, required: true },
  syncedAt: { type: Date, default: Date.now },
});

// Compound index
studySessionSchema.index({ userUid: 1, localId: 1 }, { unique: true });
studySessionSchema.index({ userUid: 1, deckLocalId: 1 });
studySessionSchema.index({ userUid: 1, vocabularyLocalId: 1 });

module.exports = mongoose.model("StudySession", studySessionSchema);
