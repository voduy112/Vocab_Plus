const mongoose = require("mongoose");

const vocabularySrsSchema = new mongoose.Schema({
  userUid: { type: String, required: true, index: true },
  vocabularyLocalId: { type: Number, required: true }, // Tham chiếu đến vocabulary.localId
  masteryLevel: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  lastReviewed: { type: Date },
  nextReview: { type: Date },
  // SRS fields (SM-2)
  srsEaseFactor: { type: Number, default: 2.5 },
  srsInterval: { type: Number, default: 0 }, // days
  srsRepetitions: { type: Number, default: 0 },
  srsDue: { type: Date },
  // Anki-like scheduler state
  srsType: { type: Number, default: 0 }, // 0=new, 1=learning, 2=review
  srsQueue: { type: Number, default: 0 }, // 0=new, 1=learning, 2=review
  srsLapses: { type: Number, default: 0 },
  srsLeft: { type: Number, default: 0 },
  syncedAt: { type: Date, default: Date.now },
});

// Compound index
vocabularySrsSchema.index(
  { userUid: 1, vocabularyLocalId: 1 },
  { unique: true }
);

module.exports = mongoose.model("VocabularySrs", vocabularySrsSchema);
