const Game = require("../models/Game");
const Player = require("../models/Player");
const Movement = require("../models/Movement");
const { broadcastToGame } = require("../utils/websocket");

const timers = new Map();

async function loadGame(req, res, next) {
  try {
    const game = await Game.findOne({ gameCode: req.params.id }).populate("players");
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
    weights[color] = (Math.floor(Math.random() * 10) + 1) * 2; // Números pares entre 2 y 20
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
  const game = req.game;
  if (game.state === "playing" && game.timeRemaining > 0) {
    const elapsedSeconds = Math.floor((Date.now() - new Date(game.lastTick).getTime()) / 1000);
    game.timeRemaining = Math.max(0, game.timeRemaining - elapsedSeconds);
  }
  res.json(game);
}

async function createGame(req, res) {
  try {
    const { roundTimeSeconds } = req.body;
    if (![60, 120, 180].includes(roundTimeSeconds)) {
      return res.status(400).json({ message: "El tiempo debe ser 60, 120 o 180 segundos" });
    }

    const gameCode = "G" + Math.floor(100000 + Math.random() * 900000).toString();
    const materialWeights = generateMaterialWeights();

    const newGame = new Game({
      gameCode,
      materialWeights,
      mainBalanceState: { leftSide: [], rightSide: [], isBalanced: false },
      secondaryBalanceState: { leftSide: [], rightSide: [], isBalanced: false },
      state: "waiting",
      currentPlayerIndex: 0,
      currentTeam: 1,
      roundTimeSeconds,
      timeRemaining: roundTimeSeconds,
      lastTick: new Date(),
    });

    const savedGame = await newGame.save();
    broadcastToGame(req.app.get("wss"), savedGame._id.toString(), {
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

    const groupCounts = game.players.reduce((acc, player) => {
      acc[player.groupId] = (acc[player.groupId] || 0) + 1;
      return acc;
    }, {});
    const activeGroups = Object.values(groupCounts).filter((count) => count > 0);
    if (activeGroups.length < 2) {
      return res.status(400).json({ message: "Debe haber al menos 2 equipos con jugadores" });
    }

    if (!game.creatorId) {
      return res.status(400).json({ message: "No se ha establecido un creador para este juego" });
    }
    const creator = game.players.find((p) => p._id.toString() === game.creatorId.toString());
    if (!creator) {
      return res.status(404).json({ message: "Creador no encontrado" });
    }

    game.state = "playing";
    game.startTime = new Date();
    game.timeRemaining = game.roundTimeSeconds;
    game.lastTick = new Date();
    await game.save();

    // Seleccionar un material aleatorio y revelar su peso
    const materialTypes = ["red", "yellow", "green", "blue", "purple"];
    const randomMaterial = materialTypes[Math.floor(Math.random() * materialTypes.length)];
    const revealedWeight = game.materialWeights[randomMaterial];

    startTurnTimer(game, req.app.get("wss"));

    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "GAME_STARTED",
      gameCode: game.gameCode,
      gameState: game,
      creatorId: game.creatorId.toString(),
      creatorName: creator.name,
    });

    // Enviar el peso del material aleatorio a todos los jugadores
    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "MATERIAL_WEIGHT_REVEALED",
      gameCode: game.gameCode,
      material: randomMaterial,
      weight: revealedWeight,
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
      "currentTeam",
      "timeRemaining",
      "materialsPlacedThisTurn",
      "lastTick",
    ];

    updatableFields.forEach((field) => {
      if (req.body[field] !== undefined) {
        req.game[field] = req.body[field];
      }
    });

    const updatedGame = await req.game.save();
    broadcastToGame(req.app.get("wss"), updatedGame._id.toString(), {
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
    const game = await Game.findOne({ gameCode });
    if (game) {
      if (timers.has(game._id.toString())) {
        clearInterval(timers.get(game._id.toString()));
        timers.delete(game._id.toString());
      }
      await Game.deleteOne({ gameCode });
      await Player.deleteMany({ gameId: game._id });
      await Movement.deleteMany({ gameId: game._id });
    }

    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "GAME_DELETED",
      gameCode,
    });
    res.json({ message: "Juego eliminado exitosamente" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

async function getGameStats(req, res) {
  try {
    const players = req.game.players;
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

async function startTurnTimer(game, wss) {
  if (timers.has(game._id.toString())) {
    clearInterval(timers.get(game._id.toString()));
  }

  const elapsedSeconds = Math.floor((Date.now() - new Date(game.lastTick).getTime()) / 1000);
  game.timeRemaining = Math.max(0, game.timeRemaining - elapsedSeconds);
  if (game.timeRemaining <= 0 && game.state === "playing") {
    await endTurn(game, wss);
    return;
  }
  game.lastTick = new Date();
  await game.save();

  const timer = setInterval(async () => {
    try {
      const currentGame = await Game.findById(game._id).populate("players");
      if (!currentGame || currentGame.state !== "playing") {
        clearInterval(timer);
        timers.delete(game._id.toString());
        return;
      }

      const elapsedSinceLastTick = Math.floor((Date.now() - new Date(currentGame.lastTick).getTime()) / 1000);
      currentGame.timeRemaining = Math.max(0, currentGame.timeRemaining - elapsedSinceLastTick);
      currentGame.lastTick = new Date();

      broadcastToGame(wss, currentGame._id.toString(), {
        type: "TIMER_UPDATE",
        gameCode: currentGame.gameCode,
        timeRemaining: currentGame.timeRemaining,
        serverTime: Date.now(),
      });

      if (currentGame.timeRemaining <= 0) {
        await endTurn(currentGame, wss);
      } else {
        await currentGame.save();
      }
    } catch (err) {
      console.error("Error en temporizador:", err);
      clearInterval(timer);
      timers.delete(game._id.toString());
    }
  }, 1000);

  timers.set(game._id.toString(), timer);
}

async function endTurn(game, wss) {
  try {
    if (game.state !== "playing") return;

    // Verificar si el equipo colocó al menos 2 materiales
    if (game.materialsPlacedThisTurn < 2) {
      const players = game.players.filter((p) => p.groupId === game.currentTeam);
      if (players.length > 0) {
        const player = players[Math.floor(Math.random() * players.length)];
        const availableMaterials = player.materials;
        if (availableMaterials.length > 0) {
          const indices = [];
          while (indices.length < 2 && availableMaterials.length > 0) {
            const index = Math.floor(Math.random() * availableMaterials.length);
            if (!indices.includes(index)) {
              indices.push(index);
              player.materials.splice(index, 1);
            }
          }
          await player.save();

          broadcastToGame(wss, game._id.toString(), {
            type: "PENALTY_APPLIED",
            gameCode: game.gameCode,
            playerId: player._id.toString(),
            message: `Equipo ${game.currentTeam} perdió 2 materiales por no colocar suficientes`,
          });
        }
      }
    }

    // Verificar si algún jugador tiene 0 materiales y eliminarlo
    const playersToUpdate = game.players.filter((p) => !p.isEliminated);
    for (const player of playersToUpdate) {
      if (player.materials.length === 0) {
        player.isEliminated = true;
        await player.save();
        broadcastToGame(wss, game._id.toString(), {
          type: "PLAYER_ELIMINATED",
          gameCode: game.gameCode,
          playerId: player._id.toString(),
          message: `El jugador ${player.name} ha sido eliminado por no tener materiales`,
        });
      }
    }

    // Encontrar el siguiente equipo con jugadores activos
    const activePlayers = game.players.filter((p) => !p.isEliminated);
    const activeTeams = [...new Set(activePlayers.map((p) => p.groupId))].sort((a, b) => a - b);
    if (activeTeams.length === 0) {
      game.state = "finished";
      game.endTime = new Date();
      await game.save();

      broadcastToGame(wss, game._id.toString(), {
        type: "GAME_ENDED",
        gameCode: game.gameCode,
        gameState: game,
        message: "El juego ha terminado porque no hay equipos activos",
      });

      if (timers.has(game._id.toString())) {
        clearInterval(timers.get(game._id.toString()));
        timers.delete(game._id.toString());
      }
      return;
    }

    let nextTeamIndex = activeTeams.indexOf(game.currentTeam) + 1;
    if (nextTeamIndex >= activeTeams.length) {
      nextTeamIndex = 0;
    }
    const nextTeam = activeTeams[nextTeamIndex];

    game.currentTeam = nextTeam;
    game.materialsPlacedThisTurn = 0;
    game.timeRemaining = game.roundTimeSeconds;
    game.lastTick = new Date();
    await game.save();

    startTurnTimer(game, wss);

    broadcastToGame(wss, game._id.toString(), {
      type: "TURN_CHANGED",
      gameCode: game.gameCode,
      currentTeam: game.currentTeam,
      timeRemaining: game.timeRemaining,
      serverTime: Date.now(),
    });
  } catch (err) {
    console.error("Error al finalizar turno:", err);
  }
}

async function restoreTimers(wss) {
  try {
    const activeGames = await Game.find({ state: "playing" }).populate("players");
    for (const game of activeGames) {
      if (game.timeRemaining > 0) {
        startTurnTimer(game, wss);
      } else {
        await endTurn(game, wss);
      }
    }
  } catch (err) {
    console.error("Error al restaurar temporizadores:", err);
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
  restoreTimers,
};