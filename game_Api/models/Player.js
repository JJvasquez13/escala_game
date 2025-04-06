const mongoose = require("mongoose");

const PlayerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
    },
    gameId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Game",
      required: true,
    },
    groupId: {
      type: Number,
      required: true,
    },
    turnOrder: {
      type: Number,
      required: true,
    },
    pieces: {
      type: Number,
      default: 2,
    },
    materials: [
      {
        type: {
          type: String,
          enum: ["red", "yellow", "green", "blue", "purple"],
        },
        id: String, // si usas un ID visual o interno, si no, puedes quitarlo
      },
    ],
    hasGuessed: {
      type: Boolean,
      default: false,
    },
    isEliminated: {
      type: Boolean,
      default: false,
    },
    guesses: [
      {
        type: {
          type: String,
          enum: ["red", "yellow", "green", "blue", "purple"],
        },
        weight: { type: Number, min: 1, max: 20 },
        isCorrect: Boolean,
        time: { type: Date, default: Date.now },
      },
    ],
    connectionData: {
      ip: String,
      userAgent: String,
      lastConnection: { type: Date, default: Date.now },
    },
    isReady: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Player", PlayerSchema);
