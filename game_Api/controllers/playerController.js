const Player = require("../models/Player");
const Game = require("../models/Game");
const Movement = require("../models/Movement");
const { broadcastToGame } = require("../utils/websocket");

const handleError = (res, error, status = 500) =>
  res.status(status).json({ message: error.message || error });

async function getGameByCode(gameCode) {
  const game = await Game.findOne({ gameCode }).populate("players");
  if (!game) throw new Error("Juego no encontrado");
  return game;
}

async function getAllPlayers(req, res) {
  try {
    const players = await Player.find();
    res.json(players);
  } catch (err) {
    handleError(res, err);
  }
}

async function getPlayersByGame(req, res) {
  try {
    const players = await Player.find({ gameId: req.params.gameId });
    res.json(players);
  } catch (err) {
    handleError(res, err);
  }
}

async function getPlayer(req, res) {
  try {
    const player = await Player.findById(req.params.id);
    if (!player) return res.status(404).json({ message: "Jugador no encontrado" });
    res.json(player);
  } catch (err) {
    handleError(res, err);
  }
}

async function createPlayer(req, res) {
  try {
    const { gameCode, name, groupId } = req.body;
    const game = await getGameByCode(gameCode);
    const existingPlayers = game.players;

    if (existingPlayers.length >= 10) {
      return res.status(400).json({ message: "Máximo 10 jugadores permitidos" });
    }

    if (!Number.isInteger(groupId) || groupId < 1 || groupId > 5) {
      return res.status(400).json({ message: "El equipo debe ser un número entre 1 y 5" });
    }

    const playersInGroup = existingPlayers.filter((p) => p.groupId === groupId).length;
    if (playersInGroup >= 2) {
      return res.status(400).json({ message: `El equipo ${groupId} ya tiene 2 jugadores` });
    }

    const usedOrders = existingPlayers.map((p) => p.turnOrder);
    const availableOrders = Array.from({ length: 10 }, (_, i) => i + 1).filter(
      (order) => !usedOrders.includes(order)
    );
    const turnOrder = availableOrders.sort(() => Math.random() - 0.5)[0];

    const materialTypes = ["red", "yellow", "green", "blue", "purple"];
    const materials = materialTypes.flatMap((type, index) => [
      { type: type ?? "red", id: `${game._id}-${type}-${index * 2}` },
      { type: type ?? "red", id: `${game._id}-${type}-${index * 2 + 1}` },
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

    if (existingPlayers.length === 0) {
      game.creatorId = savedPlayer._id;
      game.players.push(savedPlayer._id);
      await game.save();
      creatorId = savedPlayer._id.toString();
      creatorName = savedPlayer.name;
    } else {
      game.players.push(savedPlayer._id);
      await game.save();
      if (game.creatorId) {
        const creator = game.players.find((p) => p._id.toString() === game.creatorId.toString());
        if (creator) creatorName = creator.name;
      }
    }

    const movement = new Movement({
      gameId: game._id,
      playerId: savedPlayer._id,
      actionType: "JOIN_GAME",
      clientInfo,
    });
    await movement.save();

    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "PLAYER_JOINED",
      gameCode,
      playerId: savedPlayer._id.toString(),
      player: savedPlayer,
      creatorId,
      creatorName,
    });
    res.status(201).json(savedPlayer);
  } catch (err) {
    handleError(res, err, 400);
  }
}

async function updatePlayer(req, res) {
  try {
    const player = await Player.findById(req.params.id);
    if (!player) return res.status(404).json({ message: "Jugador no encontrado" });

    const fields = [
      "name",
      "pieces",
      "materials",
      "hasGuessed",
      "isEliminated",
      "guesses",
      "connectionData",
      "isReady",
      "groupId",
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
    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "PLAYER_UPDATED",
      gameCode: game.gameCode,
      playerId: updatedPlayer._id.toString(),
      player: updatedPlayer,
    });
    res.json(updatedPlayer);
  } catch (err) {
    handleError(res, err, 400);
  }
}

async function placeMaterial(req, res) {
  try {
    const { materialId, balanceType, side } = req.body;
    const player = await Player.findById(req.params.id);
    if (!player) return res.status(404).json({ message: "Jugador no encontrado" });

    const game = await Game.findById(player.gameId).populate("players");
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });

    if (game.state !== "playing") {
      return res.status(400).json({ message: "El juego no está en curso" });
    }

    if (game.currentTeam !== player.groupId) {
      return res.status(400).json({ message: "No es el turno de tu equipo" });
    }

    if (player.isEliminated) {
      return res.status(400).json({ message: "Estás eliminado y no puedes realizar acciones" });
    }

    if (player.materials.length <= 1) {
      return res.status(400).json({ message: "No tienes suficientes materiales para colocar (mínimo 2)" });
    }

    const index = player.materials.findIndex((m) => m.id === materialId);
    if (index === -1) return res.status(404).json({ message: "Material no encontrado" });

    const material = player.materials.splice(index, 1)[0];
    const sideData = { type: material.type, playerId: player._id.toString() };

    const balance =
      balanceType === "main" ? game.mainBalanceState : game.secondaryBalanceState;
    side === "left" ? balance.leftSide.push(sideData) : balance.rightSide.push(sideData);

    if (balanceType === "main" || balanceType === "secondary") {
      const calcWeight = (side) =>
        side.reduce((sum, m) => sum + game.materialWeights[m.type], 0);
      balance.isBalanced = calcWeight(balance.leftSide) === calcWeight(balance.rightSide);
    }

    game.materialsPlacedThisTurn += 1;

    await Promise.all([player.save(), game.save()]);

    const movement = new Movement({
      gameId: player.gameId,
      playerId: player._id,
      actionType: "PLACE_MATERIAL",
      data: { material, balanceType, side },
      clientInfo: { ip: req.ip, userAgent: req.get("User-Agent") },
    });
    await movement.save();

    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "MATERIAL_PLACED",
      gameCode: game.gameCode,
      playerId: player._id.toString(),
      balanceType,
      side,
      material,
      isBalanced: balance.isBalanced,
      materialsPlacedThisTurn: game.materialsPlacedThisTurn,
    });

    res.json({
      message: "Material colocado",
      material,
      balanceType,
      side,
      isBalanced: balance.isBalanced,
      materialsPlacedThisTurn: game.materialsPlacedThisTurn,
    });
  } catch (err) {
    handleError(res, err, 400);
  }
}

async function makeGuess(req, res) {
  try {
    const player = await Player.findById(req.params.id);
    if (!player) return res.status(404).json({ message: "Jugador no encontrado" });

    const game = await Game.findById(player.gameId).populate("players");
    if (!game) return res.status(404).json({ message: "Juego no encontrado" });

    if (game.state !== "playing") {
      return res.status(400).json({ message: "El juego no está en curso" });
    }

    if (game.currentTeam !== player.groupId) {
      return res.status(400).json({ message: "No es el turno de tu equipo" });
    }

    if (player.isEliminated) {
      return res.status(400).json({ message: "Estás eliminado y no puedes realizar acciones" });
    }

    if (player.materials.length <= 1) {
      return res.status(400).json({ message: "No tienes suficientes materiales para hacer una adivinanza (mínimo 2)" });
    }

    if (!game.mainBalanceState.isBalanced) {
      return res.status(400).json({ message: "La balanza principal no está equilibrada" });
    }

    if (player.pieces <= 0) {
      return res.status(400).json({ message: "No hay piezas disponibles" });
    }

    if (player.hasGuessed) {
      return res.status(400).json({ message: "El jugador ya ha hecho una adivinanza" });
    }

    const { guesses } = req.body;
    if (!Array.isArray(guesses)) {
      return res.status(400).json({ message: "Formato de adivinanza inválido" });
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

    broadcastToGame(req.app.get("wss"), game._id.toString(), {
      type: "GUESS_MADE",
      gameCode: game.gameCode,
      playerId: player._id.toString(),
      guesses: validatedGuesses,
      guessResult: allCorrect,
      newPiecesTotal: player.pieces,
      gameState: game,
    });

    res.json({
      message: allCorrect ? "¡Todas las adivinanzas correctas!" : "Algunas fueron incorrectas",
      guessResult: allCorrect,
      guesses: validatedGuesses,
      newPiecesTotal: player.pieces,
      gameState: game,
    });
  } catch (err) {
    handleError(res, err, 400);
  }
}

async function updatePlayerTeam(req, res) {
try {
  const { gameCode, playerId } = req.params;
  const { groupId } = req.body;
  
  if (!groupId || groupId < 1 || groupId > 5) {
    return res.status(400).json({ message: "El equipo debe estar entre 1 y 5" });
  }

  // Verificar que el juego existe y obtener su estado
  const game = await getGameByCode(gameCode);
  
  // Solo permitir cambios cuando el juego esté en estado de espera
  if (game.state !== "waiting") {
    return res.status(400).json({ message: "No se puede cambiar de equipo una vez iniciada la partida" });
  }

  // Encontrar y actualizar el jugador
  const player = await Player.findById(playerId);
  if (!player) {
    return res.status(404).json({ message: "Jugador no encontrado" });
  }

  // Verificar que el jugador pertenece al juego indicado
  if (player.gameId.toString() !== game._id.toString()) {
    return res.status(400).json({ message: "El jugador no pertenece a este juego" });
  }
  
  // Actualizar el equipo del jugador
  player.groupId = groupId;
  await player.save();
  
  // Notificar a todos los clientes sobre el cambio de equipo
  broadcastToGame(game.gameCode, {
    type: "PLAYER_TEAM_CHANGED",
    gameCode: game.gameCode,
    playerId: player._id,
    playerName: player.name,
    newTeam: groupId,
  });
  
  res.json(player);
} catch (err) {
  handleError(res, err);
}
}

module.exports = {
  getAllPlayers,
  getPlayersByGame,
  getPlayer,
  createPlayer,
  updatePlayer,
  placeMaterial,
  makeGuess,
  updatePlayerTeam,
};