const mongoose = require("mongoose");

const GameSchema = new mongoose.Schema(
  {
    gameCode: {
      type: String,
      required: true,
      unique: true,
    },
    players: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Player",
      },
    ],
    startTime: {
      type: Date,
      default: Date.now,
    },
    endTime: {
      type: Date,
    },
    state: { // Cambiado de status a state
      type: String,
      enum: ["waiting", "playing", "finished"],
      default: "waiting",
    },
    creatorId: { // Nuevo campo para el ID del creador
      type: mongoose.Schema.Types.ObjectId,
      ref: "Player",
    },
    winners: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Player",
      },
    ],
    materialWeights: {
      red: { type: Number, min: 1, max: 20 },
      yellow: { type: Number, min: 1, max: 20 },
      green: { type: Number, min: 1, max: 20 },
      blue: { type: Number, min: 1, max: 20 },
      purple: { type: Number, min: 1, max: 20 },
    },
    mainBalanceState: {
      leftSide: [
        {
          type: {
            type: String,
            enum: ["red", "yellow", "green", "blue", "purple"],
          },
          playerId: { type: mongoose.Schema.Types.ObjectId, ref: "Player" },
        },
      ],
      rightSide: [
        {
          type: {
            type: String,
            enum: ["red", "yellow", "green", "blue", "purple"],
          },
          playerId: { type: mongoose.Schema.Types.ObjectId, ref: "Player" },
        },
      ],
      isBalanced: { type: Boolean, default: false },
    },
    secondaryBalanceState: {
      leftSide: [
        {
          type: {
            type: String,
            enum: ["red", "yellow", "green", "blue", "purple"],
          },
          playerId: { type: mongoose.Schema.Types.ObjectId, ref: "Player" },
        },
      ],
      rightSide: [
        {
          type: {
            type: String,
            enum: ["red", "yellow", "green", "blue", "purple"],
          },
          playerId: { type: mongoose.Schema.Types.ObjectId, ref: "Player" },
        },
      ],
      isBalanced: { type: Boolean, default: false }, // Añadido para consistencia
    },
    currentPlayerIndex: {
      type: Number,
      default: 0,
    },
    roundTimeSeconds: {
      type: Number,
      default: 300, // 5 minutes
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Game", GameSchema);