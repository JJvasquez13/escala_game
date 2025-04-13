const Game = require("../models/Game");
const Player = require("../models/Player");
const Movement = require("../models/Movement");
const { broadcast } = require("../utils/websocket");

async function loadGame(req, res, next) {
  try {
    const game = await Game.findOne({ gameCode: req.params.id });
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });
    req.game = game;
    next();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

function generateMaterialWeights() {
  const colors = ["red", "yellow", "green", "blue", "purple"];
  const weights = {};
  colors.forEach((color) => {
    weights[color] = (Math.floor(Math.random() * 10) + 1) * 2;
  });
  return weights;
}

async function getAllGames(req, res) {
  try {
    const games = await Game.find().sort({ createdAt: -1 });
    res.json(games);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

function getGame(req, res) {
  res.json(req.game);
}

async function createGame(req, res) {
  try {
    const gameCode = "G" + Math.floor(100000 + Math.random() * 900000).toString();
    const materialWeights = generateMaterialWeights();

    const newGame = new Game({
      gameCode,
      materialWeights,
      mainBalanceState: { leftSide: [], rightSide: [], isBalanced: false },
      secondaryBalanceState: { leftSide: [], rightSide: [], isBalanced: false },
      state: "waiting",
      currentPlayerIndex: 0,
    });

    const savedGame = await newGame.save();
    broadcast(req.app.get("wss"), {
      type: "GAME_CREATED",
      gameCode,
      gameState: savedGame,
    });
    res.status(201).json(savedGame);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
}

async function startGame(req, res) {
  try {
    const game = req.game;
    if (game.state !== "waiting") {
      return res.status(400).json({ message: "El juego ya ha comenzado o ha terminado" });
    }
    if (game.players.length < 2) {
      return res.status(400).json({ message: "Se necesitan al menos 2 jugadores para iniciar" });
    }

    // Validar que haya al menos un jugador en algún equipo
    const players = await Player.find({ gameId: game._id });
    const groupCounts = players.reduce((acc, player) => {
      acc[player.groupId] = (acc[player.groupId] || 0) + 1;
      return acc;
    }, {});
    const activeGroups = Object.values(groupCounts).filter((count) => count > 0);
    if (activeGroups.length < 1) {
      return res.status(400).json({ message: "Debe haber al menos un equipo con jugadores" });
    }

    if (!game.creatorId) {
      return res.status(400).json({ message: "No se ha establecido un creador para este juego" });
    }
    const creator = await Player.findById(game.creatorId);
    if (!creator) {
      return res.status(404).json({ message: "Creador no encontrado" });
    }

    game.state = "playing";
    game.startTime = new Date();
    await game.save();

    broadcast(req.app.get("wss"), {
      type: "GAME_STARTED",
      gameCode: game.gameCode,
      gameState: game,
      creatorId: game.creatorId.toString(),
      creatorName: creator.name,
    });

    res.json({ message: "Juego iniciado" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function updateGame(req, res) {
  try {
    const updatableFields = [
      "state",
      "endTime",
      "winners",
      "mainBalanceState",
      "secondaryBalanceState",
      "currentPlayerIndex",
    ];

    updatableFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        req.game[field] = req.body[field];
      }
    });

    const updatedGame = await req.game.save();
    broadcast(req.app.get("wss"), {
      type: "GAME_UPDATED",
      gameCode: req.params.id,
      gameState: updatedGame,
    });
    res.json(updatedGame);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
}

async function deleteGame(req, res) {
  try {
    const gameCode = req.params.id;
    await Game.deleteOne({ gameCode });
    await Player.deleteMany({ gameId: req.game._id });
    await Movement.deleteMany({ gameId: req.game._id });

    broadcast(req.app.get("wss"), { type: "GAME_DELETED", gameCode });
    res.json({ message: "Juego eliminado exitosamente" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getGameStats(req, res) {
  try {
    const players = await Player.find({ gameId: req.game._id });
    const movements = await Movement.find({ gameId: req.game._id });

    const stats = {
      totalPlayers: players.length,
      totalMoves: movements.length,
      movesPerPlayer: {},
      correctGuesses: 0,
      incorrectGuesses: 0,
      gameState: req.game.state,
      startTime: req.game.startTime,
      endTime: req.game.endTime,
      duration: req.game.endTime
        ? (new Date(req.game.endTime) - new Date(req.game.startTime)) / 1000
        : null,
      winners: players
        .filter((p) => req.game.winners.includes(p._id))
        .map((p) => p.name),
    };

    const moveCount = {};
    for (const m of movements) {
      const id = m.playerId.toString();
      moveCount[id] = (moveCount[id] || 0) + 1;
    }
    for (const player of players) {
      stats.movesPerPlayer[player.name] = moveCount[player._id.toString()] || 0;
    }

    const guessMovements = movements.filter((m) => m.actionType === "MAKE_GUESS");
    stats.correctGuesses = guessMovements.filter((m) => m.data.guessResult === true).length;
    stats.incorrectGuesses = guessMovements.filter((m) => m.data.guessResult === false).length;

    res.json(stats);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

module.exports = {
  loadGame,
  getAllGames,
  getGame,
  createGame,
  startGame,
  updateGame,
  deleteGame,
  getGameStats,
};