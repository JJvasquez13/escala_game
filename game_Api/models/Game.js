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
    state: {
      type: String,
      enum: ["waiting", "playing", "finished"],
      default: "waiting",
    },
    creatorId: {
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
      isBalanced: { type: Boolean, default: false },
    },
    currentPlayerIndex: {
      type: Number,
      default: 0,
    },
    currentTeam: {
      type: Number,
      default: 1,
    },
    roundTimeSeconds: {
      type: Number,
      enum: [60, 120, 180],
      required: true,
    },
    timeRemaining: {
      type: Number,
      default: 0,
    },
    materialsPlacedThisTurn: {
      type: Number,
      default: 0,
    },
    lastTick: {
      type: Date, // Marca de tiempo del último tick del temporizador
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Game", GameSchema);