const mongoose = require("mongoose");

const MovementSchema = new mongoose.Schema(
  {
    gameId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Game",
      required: true,
    },
    playerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Player",
      required: true,
    },
    actionType: {
      type: String,
      enum: [
        "JOIN_GAME",
        "PLACE_MATERIAL",
        "MAKE_GUESS",
        "END_TURN",
        "LEAVE_GAME",
      ],
      required: true,
    },
    data: {
      // For PLACE_MATERIAL
      material: {
        type: {
          type: String,
          enum: ["red", "yellow", "green", "blue", "purple"],
        },
        id: String, // opcional, si usas identificadores únicos
      },
      balanceType: { type: String, enum: ["main", "secondary"] },
      side: { type: String, enum: ["left", "right"] },

      // For MAKE_GUESS
      guesses: [
        {
          type: {
            type: String,
            enum: ["red", "yellow", "green", "blue", "purple"],
          },
          weight: Number,
        },
      ],
      guessResult: Boolean,
    },
    clientInfo: {
      ip: String,
      userAgent: String,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Movement", MovementSchema);
