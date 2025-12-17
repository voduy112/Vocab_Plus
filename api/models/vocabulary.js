const mongoose = require("mongoose");

const vocabularySchema = new mongoose.Schema({
  userUid: { type: String, required: true, index: true },
  localId: { type: Number, required: true }, // ID từ SQLite
  deckLocalId: { type: Number, required: true }, // Tham chiếu đến deck.localId
  front: { type: String, required: true },
  back: { type: String, required: true },
  frontImageUrl: { type: String },
  frontImagePath: { type: String },
  backImageUrl: { type: String },
  backImagePath: { type: String },
  frontExtraJson: { type: String },
  backExtraJson: { type: String },
  createdAt: { type: Date, required: true },
  updatedAt: { type: Date, required: true },
  isActive: { type: Boolean, default: true },
  cardType: { type: String, default: "basis" },
  syncedAt: { type: Date, default: Date.now },
});

// Compound index
vocabularySchema.index({ userUid: 1, localId: 1 }, { unique: true });
vocabularySchema.index({ userUid: 1, deckLocalId: 1 });

module.exports = mongoose.model("Vocabulary", vocabularySchema);
