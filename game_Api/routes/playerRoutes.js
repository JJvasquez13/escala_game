const express = require("express");
const router = express.Router();
const playerController = require("../controllers/playerController");

router.get("/", playerController.getAllPlayers);
router.get("/game/:gameId", playerController.getPlayersByGame);
router.get("/:id", playerController.getPlayer);
router.post("/", playerController.createPlayer);
router.patch("/:id", playerController.updatePlayer);
router.post("/:id/place-material", playerController.placeMaterial);
router.post("/:id/guess", playerController.makeGuess);

module.exports = (wss) => {
  router.wss = wss;
  return router;
};