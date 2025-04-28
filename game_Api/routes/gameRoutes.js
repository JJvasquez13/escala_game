const express = require("express");
const router = express.Router();
const gameController = require("../controllers/gameController");
const playerController = require("../controllers/playerController");

router.get("/", gameController.getAllGames);
router.get("/recent/list", gameController.getRecentGames);
router.get("/:id", gameController.loadGame, gameController.getGame);
router.post("/", gameController.createGame);
router.post("/:id/start", gameController.loadGame, gameController.startGame);
router.patch("/:id", gameController.loadGame, gameController.updateGame);
router.delete("/:id", gameController.loadGame, gameController.deleteGame);
router.get("/:id/stats", gameController.loadGame, gameController.getGameStats);

// Rutas para manejar jugadores dentro de un juego
router.put("/:gameCode/players/:playerId/team", playerController.updatePlayerTeam);

module.exports = (wss) => {
  router.wss = wss;
  return router;
};