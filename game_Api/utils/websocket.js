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

// Enviar mensaje solo a los jugadores de un juego específico
function broadcastToGame(wss, gameId, data) {
  const message = JSON.stringify(data);
  const playerIds = new Set();

  // Encontrar todos los jugadores del juego
  for (const [playerId, client] of connectedPlayers.entries()) {
    const player = client.player; // Asumimos que hemos almacenado el jugador en el cliente
    if (player && player.gameId.toString() === gameId) {
      playerIds.add(playerId);
    }
  }

  // Enviar mensaje solo a los jugadores del juego
  for (const [playerId, client] of connectedPlayers.entries()) {
    if (playerIds.has(playerId) && client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  }
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

        if (!data.playerId) {
          console.error("Mensaje WebSocket:", data);
          return;
        }

        // Almacenar el jugador en el cliente WebSocket
        if (!connectedPlayers.has(data.playerId)) {
          const player = await Player.findById(data.playerId);
          if (player) {
            connectedPlayers.set(data.playerId, ws);
            ws.player = player; // Almacenar el jugador en el cliente para referencia
            console.log(`Jugador ${data.playerId} registrado en connectedPlayers`);
          } else {
            console.error(`Jugador ${data.playerId} no encontrado`);
            return;
          }
        }

        switch (data.type) {
          case "JOIN_GAME":
            console.log(`Jugador ${data.playerId} se unió al juego ${data.gameCode}`);
            break;

          case "START_GAME":
            console.log(`Juego ${data.gameCode} iniciado por ${data.playerId}`);
            break;

          case "GAME_ACTION":
            const { gameCode: actionGameCode, actionType, actionData } = data;
            const actionGame = await Game.findOne({ gameCode: actionGameCode }).populate("players");
            if (!actionGame || actionGame.state !== "playing") return;

            const movement = new Movement({
              gameId: actionGame._id,
              playerId: data.playerId,
              actionType,
              data: actionData,
            });
            await movement.save();

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

              actionGame.materialsPlacedThisTurn += 1;
              await actionGame.save();
            }

            broadcastToGame(wss, actionGame._id.toString(), {
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
          const game = await Game.findOne({ players: player._id }).populate("players");
          if (game) {
            broadcastToGame(wss, game._id.toString(), {
              type: "PLAYER_LEFT",
              gameCode: game.gameCode,
              playerId: disconnectedPlayerId,
            });

            // Verificar si el equipo actual se quedó sin jugadores
            const activeTeams = [...new Set(game.players.map((p) => p.groupId))];
            if (!activeTeams.includes(game.currentTeam)) {
              // Si el equipo actual está vacío, pasar al siguiente turno
              await require("./gameController").endTurn(game, wss);
            }
          }
        }
      }
    });
  });
}

module.exports = { setupWebSocket, broadcast, broadcastToGame };