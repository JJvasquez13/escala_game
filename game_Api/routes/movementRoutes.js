const express = require("express");
const router = express.Router();
const movementController = require("../controllers/movementController");

router.get("/", movementController.getRecentMovements);
router.get("/game/:gameId", movementController.getMovementsByGame);
router.get("/player/:playerId", movementController.getMovementsByPlayer);
router.get("/:id", movementController.loadMovement, movementController.getMovement);
router.post("/", movementController.createMovement);
router.get("/stats/game/:gameId", movementController.getGameMovementStats);

module.exports = (wss) => {
  router.wss = wss;
  return router;
};