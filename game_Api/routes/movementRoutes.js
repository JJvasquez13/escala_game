const express = require("express");
const router = express.Router();
const Movement = require("../models/Movement");
const { broadcast } = require("../utils/websocket");

// Middleware para cargar un movimiento por ID
async function loadMovement(req, res, next) {
  try {
    const movement = await Movement.findById(req.params.id);
    if (!movement) {
      return res.status(404).json({ message: "Movimiento no encontrado" });
    }
    req.movement = movement;
    next();
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
}

// Obtener últimos 100 movimientos globales
router.get("/", async (req, res) => {
  try {
    const movements = await Movement.find().sort({ createdAt: -1 }).limit(100);
    res.json(movements);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Obtener movimientos por ID de juego
router.get("/game/:gameId", async (req, res) => {
  try {
    const movements = await Movement.find({ gameId: req.params.gameId }).sort({
      createdAt: -1,
    });
    res.json(movements);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Obtener movimientos por ID de jugador
router.get("/player/:playerId", async (req, res) => {
  try {
    const movements = await Movement.find({
      playerId: req.params.playerId,
    }).sort({ createdAt: -1 });
    res.json(movements);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Obtener movimiento por ID
router.get("/:id", loadMovement, (req, res) => {
  res.json(req.movement);
});

// Crear nuevo movimiento
router.post("/", async (req, res) => {
  try {
    const { gameId, playerId, actionType, data } = req.body;

    // Validaciones mínimas
    if (!gameId || !playerId || !actionType) {
      return res
        .status(400)
        .json({ message: "gameId, playerId y actionType son requeridos" });
    }

    const validActions = [
      "JOIN_GAME",
      "PLACE_MATERIAL",
      "MAKE_GUESS",
      "END_TURN",
      "LEAVE_GAME",
    ];
    if (!validActions.includes(actionType)) {
      return res.status(400).json({
        message: `actionType inválido. Tipos válidos: ${validActions.join(
          ", "
        )}`,
      });
    }

    const movement = new Movement({
      gameId,
      playerId,
      actionType,
      data: data || {},
      clientInfo: {
        ip: req.ip,
        userAgent: req.get("User-Agent"),
      },
    });

    const savedMovement = await movement.save();
    broadcast(req.app.get("wss"), {
      type: "MOVEMENT_CREATED",
      gameId,
      movement: savedMovement,
    });
    res.status(201).json(savedMovement);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// Estadísticas por juego
router.get("/stats/game/:gameId", async (req, res) => {
  try {
    const [actionCounts, playerCounts, timeline, totalMovements] =
      await Promise.all([
        Movement.aggregate([
          { $match: { gameId: req.params.gameId } },
          { $group: { _id: "$actionType", count: { $sum: 1 } } },
        ]),
        Movement.aggregate([
          { $match: { gameId: req.params.gameId } },
          { $group: { _id: "$playerId", count: { $sum: 1 } } },
        ]),
        Movement.aggregate([
          { $match: { gameId: req.params.gameId } },
          {
            $group: {
              _id: {
                $dateToString: { format: "%Y-%m-%d %H:%M", date: "$createdAt" },
              },
              count: { $sum: 1 },
            },
          },
          { $sort: { _id: 1 } },
        ]),
        Movement.countDocuments({ gameId: req.params.gameId }),
      ]);

    res.json({
      actionCounts,
      playerCounts,
      timeline,
      totalMovements,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Exportar el router como función que acepta wss
module.exports = (wss) => {
  router.wss = wss; // Guardar wss en el router
  return router;
};
