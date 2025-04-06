const express = require("express");
const router = express.Router();
const Player = require("../models/Player");
const Game = require("../models/Game");
const Movement = require("../models/Movement");
const { broadcast } = require("../utils/websocket");

/* Helper to handle errors */
const handleError = (res, error, status = 500) =>
  res.status(status).json({ message: error.message || error });

/* Helper: Get game by gameCode */
const getGameByCode = async (gameCode) => {
  const game = await Game.findOne({ gameCode });
  if (!game) throw new Error("Juego no encontrado");
  return game;
};

/* GET: All players */
router.get("/", async (_, res) => {
  try {
    const players = await Player.find();
    res.json(players);
  } catch (err) {
    handleError(res, err);
  }
});

/* GET: Players by Game ID */
router.get("/game/:gameId", async (req, res) => {
  try {
    const players = await Player.find({ gameId: req.params.gameId });
    res.json(players);
  } catch (err) {
    handleError(res, err);
  }
});

/* GET: One player */
router.get("/:id", async (req, res) => {
  try {
    const player = await Player.findById(req.params.id);
    if (!player)
      return res.status(404).json({ message: "Jugador no encontrado" });
    res.json(player);
  } catch (err) {
    handleError(res, err);
  }
});

/* POST: Create new player */
router.post("/", async (req, res) => {
  try {
    const { gameCode, name } = req.body;
    const game = await getGameByCode(gameCode);
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });

    const existingPlayers = await Player.find({ gameId: game._id });
    if (existingPlayers.length >= 10) {
      return res.status(400).json({ message: "Máximo 10 jugadores permitidos" });
    }

    const groupId = Math.floor(existingPlayers.length / 2) + 1;

    const usedOrders = existingPlayers.map((p) => p.turnOrder);
    const availableOrders = Array.from({ length: 10 }, (_, i) => i + 1).filter(
      (order) => !usedOrders.includes(order)
    );
    const turnOrder = availableOrders.sort(() => Math.random() - 0.5)[0];

    const materialTypes = ["red", "yellow", "green", "blue", "purple"];
    const materials = materialTypes.flatMap((type, index) => [
      { type: type ?? 'red', id: `${game._id}-${type}-${index * 2}` },
      { type: type ?? 'red', id: `${game._id}-${type}-${index * 2 + 1}` },
    ]);

    const clientInfo = {
      ip: req.ip,
      userAgent: req.get("User-Agent"),
      lastConnection: new Date(),
    };

    const newPlayer = new Player({
      gameId: game._id,
      name: name || `Jugador ${existingPlayers.length + 1}`,
      groupId,
      turnOrder,
      materials,
      connectionData: clientInfo,
      isReady: false,
    });

    const savedPlayer = await newPlayer.save();

    let creatorId = game.creatorId ? game.creatorId.toString() : null;
    let creatorName = null;

    // Si es el primer jugador, establecerlo como el creador
    if (existingPlayers.length === 0) {
      game.creatorId = savedPlayer._id;
      game.players.push(savedPlayer._id);
      await game.save();
      creatorId = savedPlayer._id.toString();
      creatorName = savedPlayer.name;
      console.log(`Creador establecido para el juego ${game.gameCode}: ${creatorId} (${creatorName})`);
    } else {
      game.players.push(savedPlayer._id);
      await game.save();
      // Obtener el nombre del creador si ya existe
      if (game.creatorId) {
        const creator = await Player.findById(game.creatorId);
        if (creator) {
          creatorName = creator.name;
        }
      }
    }

    const movement = new Movement({
      gameId: game._id,
      playerId: savedPlayer._id,
      actionType: "JOIN_GAME",
      clientInfo,
    });
    await movement.save();

    broadcast(router.wss, {
      type: "PLAYER_JOINED",
      gameCode,
      playerId: savedPlayer._id.toString(),
      player: savedPlayer,
      creatorId, // Incluimos el creatorId en el mensaje
      creatorName, // Incluimos el nombre del creador en el mensaje
    });
    res.status(201).json(savedPlayer);
  } catch (err) {
    handleError(res, err, 400);
  }
});

/* PATCH: Update player */
router.patch("/:id", async (req, res) => {
  try {
    const player = await Player.findById(req.params.id);
    if (!player)
      return res.status(404).json({ message: "Jugador no encontrado" });

    const fields = [
      "name",
      "pieces",
      "materials",
      "hasGuessed",
      "isEliminated",
      "guesses",
      "connectionData",
      "isReady",
    ];
    fields.forEach((field) => {
      if (req.body[field] !== undefined) {
        player[field] = req.body[field];
      }
    });

    if (req.body.connectionData) {
      player.connectionData.lastConnection = new Date();
    }

    const updatedPlayer = await player.save();
    const game = await Game.findById(player.gameId);
    broadcast(req.app.get("wss"), {
      type: "PLAYER_UPDATED",
      gameCode: game.gameCode,
      playerId: updatedPlayer._id.toString(),
      player: updatedPlayer,
    });
    res.json(updatedPlayer);
  } catch (err) {
    handleError(res, err, 400);
  }
});

/* POST: Place material */
router.post("/:id/place-material", async (req, res) => {
  try {
    const { materialId, balanceType, side } = req.body;
    const player = await Player.findById(req.params.id);
    if (!player)
      return res.status(404).json({ message: "Jugador no encontrado" });

    const game = await Game.findById(player.gameId);
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });

    const index = player.materials.findIndex((m) => m.id === materialId);
    if (index === -1)
      return res.status(404).json({ message: "Material no encontrado" });

    const material = player.materials.splice(index, 1)[0];
    const sideData = { type: material.type, playerId: player._id.toString() };

    const balance =
      balanceType === "main"
        ? game.mainBalanceState
        : game.secondaryBalanceState;
    side === "left"
      ? balance.leftSide.push(sideData)
      : balance.rightSide.push(sideData);

    if (balanceType === "main" || balanceType === "secondary") {
      const calcWeight = (side) =>
        side.reduce((sum, m) => sum + game.materialWeights[m.type], 0);
      balance.isBalanced =
        calcWeight(balance.leftSide) === calcWeight(balance.rightSide);
    }

    await Promise.all([player.save(), game.save()]);

    const movement = new Movement({
      gameId: player.gameId,
      playerId: player._id,
      actionType: "PLACE_MATERIAL",
      data: { material, balanceType, side },
      clientInfo: { ip: req.ip, userAgent: req.get("User-Agent") },
    });
    await movement.save();

    broadcast(req.app.get("wss"), {
      type: "MATERIAL_PLACED",
      gameCode: game.gameCode,
      playerId: player._id.toString(),
      balanceType,
      side,
      material,
      isBalanced: balance.isBalanced,
    });

    res.json({
      message: "Material colocado",
      material,
      balanceType,
      side,
      isBalanced: balance.isBalanced,
    });
  } catch (err) {
    handleError(res, err, 400);
  }
});

/* POST: Make a guess */
router.post("/:id/guess", async (req, res) => {
  try {
    const player = await Player.findById(req.params.id);
    if (!player)
      return res.status(404).json({ message: "Jugador no encontrado" });

    const game = await Game.findById(player.gameId);
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });

    if (!game.mainBalanceState.isBalanced) {
      return res
        .status(400)
        .json({ message: "La balanza principal no está equilibrada" });
    }

    if (player.pieces <= 0) {
      return res.status(400).json({ message: "No hay piezas disponibles" });
    }

    if (player.hasGuessed) {
      return res.status(400).json({ message: "El jugador ya ha hecho una adivinanza" });
    }

    const { guesses } = req.body;
    if (!Array.isArray(guesses)) {
      return res
        .status(400)
        .json({ message: "Formato de adivinanza inválido" });
    }

    const validatedGuesses = guesses.map(({ type, weight }) => {
      if (!["red", "yellow", "green", "blue", "purple"].includes(type)) {
        throw new Error(`Tipo de material inválido: ${type}`);
      }
      if (typeof weight !== "number" || weight < 1 || weight > 20) {
        throw new Error(`Peso inválido para ${type}: ${weight}`);
      }
      const isCorrect = game.materialWeights[type] === weight;
      return { type, weight, isCorrect, time: new Date() };
    });

    let allCorrect = validatedGuesses.every((guess) => guess.isCorrect);

    player.pieces -= 1;
    player.guesses.push(...validatedGuesses);
    player.hasGuessed = true;

    if (allCorrect) {
      player.pieces += 2;
      if (!game.winners.includes(player._id)) {
        game.winners.push(player._id);
        game.state = "finished";
        game.endTime = new Date();
        await game.save();
      }
    }

    await player.save();

    const movement = new Movement({
      gameId: player.gameId,
      playerId: player._id,
      actionType: "MAKE_GUESS",
      data: {
        guesses: validatedGuesses,
        guessResult: allCorrect,
      },
      clientInfo: { ip: req.ip, userAgent: req.get("User-Agent") },
    });
    await movement.save();

    broadcast(req.app.get("wss"), {
      type: "GUESS_MADE",
      gameCode: game.gameCode,
      playerId: player._id.toString(),
      guesses: validatedGuesses,
      guessResult: allCorrect,
      newPiecesTotal: player.pieces,
      gameState: game,
    });

    res.json({
      message: allCorrect
        ? "¡Todas las adivinanzas correctas!"
        : "Algunas fueron incorrectas",
      guessResult: allCorrect,
      guesses: validatedGuesses,
      newPiecesTotal: player.pieces,
      gameState: game,
    });
  } catch (err) {
    handleError(res, err, 400);
  }
});

// Exportar el router como función que acepta wss
module.exports = (wss) => {
  router.wss = wss; // Guardar wss en el router
  return router;
};