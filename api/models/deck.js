const mongoose = require("mongoose");

const deckSchema = new mongoose.Schema({
  userUid: { type: String, required: true, index: true },
  localId: { type: Number, required: true }, // ID từ SQLite
  name: { type: String, required: true },
  color: { type: String, default: "#2196F3" },
  createdAt: { type: Date, required: true },
  updatedAt: { type: Date, required: true },
  isActive: { type: Boolean, default: true },
  isFavorite: { type: Boolean, default: false },
  syncedAt: { type: Date, default: Date.now },
});

// Compound index để đảm bảo mỗi user chỉ có 1 deck với localId tương ứng
deckSchema.index({ userUid: 1, localId: 1 }, { unique: true });

module.exports = mongoose.model("Deck", deckSchema);
