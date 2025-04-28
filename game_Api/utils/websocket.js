const Game = require("../models/Game");
const Player = require("../models/Player");
const Movement = require("../models/Movement");
const WebSocket = require("ws");

// Mapa para almacenar jugadores conectados y su información
const connectedPlayers = new Map();

// Guardar última actividad del jugador para detección de reconexiones
const playerLastActivity = new Map();

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
    if (player && player.gameId && player.gameId.toString() === gameId) {
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

// Verificar estado de las conexiones periódicamente
function startHeartbeat(wss) {
  const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
      if (ws.isAlive === false) {
        console.log("Cerrando cliente inactivo");
        return ws.terminate();
      }

      ws.isAlive = false;
      ws.ping();
    });
  }, 30000); // Verificar cada 30 segundos

  wss.on('close', () => {
    clearInterval(interval);
  });
}

function setupWebSocket(wss) {
  // Iniciar verificación de conexiones activas
  startHeartbeat(wss);

  wss.on("connection", (ws, req) => {
    console.log(`Nuevo cliente conectado desde ${req.socket.remoteAddress}`);
    
    // Marcar conexión como activa
    ws.isAlive = true;
    
    // Manejar pongs para heartbeat
    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on("message", async (message) => {
      try {
        const data = JSON.parse(message.toString());
        console.log(`Mensaje recibido: ${data.type} de jugador ${data.playerId || 'desconocido'}`);

        // Manejar mensajes de ping/pong para verificar conexión
        if (data.type === "PING") {
          ws.send(JSON.stringify({ type: "PONG", timestamp: Date.now() }));
          return;
        }

        if (!data.playerId) {
          console.error("Mensaje WebSocket sin playerId:", data);
          return;
        }
        
        // Registrar actividad del jugador
        playerLastActivity.set(data.playerId, Date.now());

        // Almacenar el jugador en el cliente WebSocket
        if (!connectedPlayers.has(data.playerId)) {
          const player = await Player.findById(data.playerId);
          if (player) {
            // Si había una conexión previa, intentar cerrarla limpiamente
            const oldWs = connectedPlayers.get(data.playerId);
            if (oldWs && oldWs !== ws && oldWs.readyState === WebSocket.OPEN) {
              console.log(`Cerrando conexión antigua de jugador ${data.playerId}`);
              oldWs.close();
            }
            
            connectedPlayers.set(data.playerId, ws);
            ws.player = player; // Almacenar el jugador en el cliente para referencia
            ws.playerId = data.playerId; // Guardar ID para referencia rápida
            console.log(`Jugador ${data.playerId} registrado en connectedPlayers`);
            
            // Notificar reconexión si corresponde
            const gameId = player.gameId;
            if (gameId) {
              const game = await Game.findById(gameId);
              if (game && game.state === "playing") {
                broadcastToGame(wss, gameId.toString(), {
                  type: "PLAYER_RECONNECTED",
                  gameCode: game.gameCode,
                  playerId: data.playerId,
                });
              }
            }
          } else {
            console.error(`Jugador ${data.playerId} no encontrado`);
            return;
          }
        } else if (connectedPlayers.get(data.playerId) !== ws) {
          // Actualizar la referencia si es una nueva conexión del mismo jugador
          const oldWs = connectedPlayers.get(data.playerId);
          if (oldWs && oldWs !== ws && oldWs.readyState === WebSocket.OPEN) {
            console.log(`Actualizando conexión para jugador ${data.playerId}`);
            oldWs.close();
          }
          connectedPlayers.set(data.playerId, ws);
          ws.player = await Player.findById(data.playerId);
          ws.playerId = data.playerId;
        }

        switch (data.type) {
          case "JOIN_GAME":
            console.log(`Jugador ${data.playerId} se unió al juego ${data.gameCode}`);
            break;

          case "START_GAME":
            console.log(`Juego ${data.gameCode} iniciado por ${data.playerId}`);
            break;
            
          case "PLAYER_TEAM_CHANGED":
            // Propagar cambio de equipo a todos los jugadores
            const teamGame = data.gameId ? 
              await Game.findById(data.gameId) : 
              await Game.findOne({ gameCode: data.gameCode });
              
            if (teamGame) {
              broadcastToGame(wss, teamGame._id.toString(), {
                type: "PLAYER_TEAM_CHANGED",
                gameCode: teamGame.gameCode,
                playerId: data.playerId,
                playerName: data.playerName,
                newTeam: data.newTeam,
              });
            }
            break;
            
          case "PLAYER_VOTED":
            // Propagar voto a todos los jugadores
            const voteGame = data.gameId ? 
              await Game.findById(data.gameId) : 
              await Game.findOne({ gameCode: data.gameCode });
              
            if (voteGame) {
              broadcastToGame(wss, voteGame._id.toString(), {
                type: "PLAYER_VOTED",
                gameCode: voteGame.gameCode,
                playerId: data.playerId,
                correctGuesses: data.correctGuesses,
              });
            }
            break;
            
          case "ALL_VOTES_COMPLETED":
            // Propagar resultados de votación a todos los jugadores
            const resultsGame = data.gameId ? 
              await Game.findById(data.gameId) : 
              await Game.findOne({ gameCode: data.gameCode });
              
            if (resultsGame) {
              // Si hay ganador, actualizar el juego en la base de datos
              if (data.winningTeam) {
                resultsGame.winners = [data.winningTeam];
                resultsGame.state = 'finished';
                await resultsGame.save();
              }
              
              // Enviar datos completos a todos los jugadores
              broadcastToGame(wss, resultsGame._id.toString(), {
                type: "ALL_VOTES_COMPLETED",
                gameCode: resultsGame.gameCode,
                playerVotes: data.playerVotes,
                materialWeights: data.materialWeights,
                winner: data.winner,
                winningTeam: data.winningTeam,
                teamScores: data.teamScores,
              });
            }
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
      const disconnectedPlayerId = ws.playerId;
      
      if (disconnectedPlayerId) {
        console.log(`Jugador ${disconnectedPlayerId} desconectado`);
        
        // No eliminamos inmediatamente del mapa para permitir reconexiones
        // Solo marcamos última desconexión para detectar posibles abandonos prolongados
        playerLastActivity.set(disconnectedPlayerId, -1 * Date.now()); // Valor negativo para indicar desconexión
        
        // Programar verificación después de un tiempo para determinar abandono real
        setTimeout(async () => {
          // Si el valor sigue siendo negativo después del tiempo de espera, considerar abandono
          const lastActivity = playerLastActivity.get(disconnectedPlayerId) || 0;
          if (lastActivity < 0 && Date.now() + lastActivity > 60000) { // 60 segundos sin reconexión
            console.log(`Jugador ${disconnectedPlayerId} abandonó la partida`);
            
            // Ahora sí limpiamos la referencia
            if (connectedPlayers.get(disconnectedPlayerId) === ws) {
              connectedPlayers.delete(disconnectedPlayerId);
            }
            
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
                  await require("../controllers/gameController").endTurn(game, wss);
                }
              }
            }
          }
        }, 10000); // Verificar después de 10 segundos
      }
    });
  });
}

module.exports = { setupWebSocket, broadcast, broadcastToGame };