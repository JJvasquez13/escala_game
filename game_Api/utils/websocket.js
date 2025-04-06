const Game = require("../models/Game");
const Player = require("../models/Player");
const Movement = require("../models/Movement");

const connectedPlayers = new Map();

function broadcast(wss, data) {
  const message = JSON.stringify(data);
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

function sendToPlayer(playerId, data) {
  const ws = connectedPlayers.get(playerId);
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
    return true;
  }
  return false;
}

function setupWebSocket(wss) {
  wss.on("connection", (ws, req) => {
    console.log(`Nuevo cliente conectado desde ${req.socket.remoteAddress}`);

    ws.on("message", async (message) => {
      try {
        const data = JSON.parse(message.toString());
        console.log(`Mensaje recibido: ${data.type} de jugador ${data.playerId}`);

        // Asegurarnos de que el mensaje incluya un playerId (el _id de MongoDB)
        if (!data.playerId) {
          console.error("Mensaje WebSocket:", data);
          return;
        }

        // Registrar al jugador en connectedPlayers usando su _id de MongoDB
        if (!connectedPlayers.has(data.playerId)) {
          connectedPlayers.set(data.playerId, ws);
          console.log(`Jugador ${data.playerId} registrado en connectedPlayers`);
        }

        switch (data.type) {
          case "JOIN_GAME":
            // Este evento ya se maneja en playerRoutes.js, pero podemos loguearlo
            console.log(`Jugador ${data.playerId} se unió al juego ${data.gameCode}`);
            break;

          case "START_GAME":
            // Este evento se maneja en gameRoutes.js, pero podemos loguearlo
            console.log(`Juego ${data.gameCode} iniciado por ${data.playerId}`);
            break;

          case "GAME_ACTION":
            const { gameCode: actionGameCode, actionType, actionData } = data;
            const actionGame = await Game.findOne({ gameCode: actionGameCode });
            if (!actionGame || actionGame.state !== "playing") return;

            const movement = new Movement({
              gameId: actionGame._id,
              playerId: data.playerId, // Usamos el _id de MongoDB enviado desde el frontend
              actionType,
              data: actionData,
            });
            await movement.save();

            // Actualizar estado del juego según la acción
            if (actionType === "PLACE_MATERIAL") {
              const { balanceType, side, material } = actionData;
              const balance =
                balanceType === "main"
                  ? actionGame.mainBalanceState
                  : actionGame.secondaryBalanceState;
              const targetSide =
                side === "left" ? balance.leftSide : balance.rightSide;
              targetSide.push({ type: material.type, playerId: data.playerId });

              const calcWeight = (side) =>
                side.reduce(
                  (sum, m) => sum + actionGame.materialWeights[m.type],
                  0
                );
              balance.isBalanced =
                calcWeight(balance.leftSide) === calcWeight(balance.rightSide);

              await actionGame.save();
            }

            broadcast(wss, {
              type: "GAME_UPDATE",
              gameCode: actionGameCode,
              gameState: actionGame,
            });
            break;
        }
      } catch (error) {
        console.error("Error procesando mensaje WebSocket:", error);
      }
    });

    ws.on("close", async () => {
      // Buscar el playerId asociado a este WebSocket
      let disconnectedPlayerId = null;
      for (const [playerId, client] of connectedPlayers.entries()) {
        if (client === ws) {
          disconnectedPlayerId = playerId;
          connectedPlayers.delete(playerId);
          break;
        }
      }

      if (disconnectedPlayerId) {
        console.log(`Jugador ${disconnectedPlayerId} desconectado`);
        const player = await Player.findById(disconnectedPlayerId);
        if (player) {
          const game = await Game.findOne({ players: player._id });
          if (game) {
            broadcast(wss, {
              type: "PLAYER_LEFT",
              gameCode: game.gameCode,
              playerId: disconnectedPlayerId,
            });
          }
        }
      }
    });
  });
}

module.exports = { setupWebSocket, broadcast };