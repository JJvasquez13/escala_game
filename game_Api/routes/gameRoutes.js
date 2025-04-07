const express = require("express");
const router = express.Router();
const gameController = require("../controllers/gameController");

router.get("/", gameController.getAllGames);
router.get("/:id", gameController.loadGame, gameController.getGame);
router.post("/", gameController.createGame);
router.post("/:id/start", gameController.loadGame, gameController.startGame);
router.patch("/:id", gameController.loadGame, gameController.updateGame);
router.delete("/:id", gameController.loadGame, gameController.deleteGame);
router.get("/:id/stats", gameController.loadGame, gameController.getGameStats);

module.exports = (wss) => {
  router.wss = wss;
  return router;
};