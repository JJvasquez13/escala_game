require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const bodyParser = require("body-parser");
const http = require("http");
const WebSocket = require("ws");
const gameRoutes = require("./routes/gameRoutes");
const movementRoutes = require("./routes/movementRoutes");
const playerRoutes = require("./routes/playerRoutes");
const { setupWebSocket } = require("./utils/websocket");
const { restoreTimers } = require("./controllers/gameController");

const app = express();
const PORT = process.env.PORT || 5000;
const server = http.createServer(app);
const wss = new WebSocket.Server({ server, path: "/ws" });

app.set("wss", wss);

app.use(cors());
app.use(bodyParser.json());

app.use("/api/games", gameRoutes(wss));
app.use("/api/movements", movementRoutes(wss));
app.use("/api/players", playerRoutes(wss));

app.get("/api/health", (req, res) => {
  res.json({ status: "ok", connections: wss.clients.size });
});

const startServer = async () => {
  try {
    const MONGODB_URI =
      process.env.MONGODB_URI || "mongodb://localhost:27017/juegoEscala";
    await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("Conectado a MongoDB");

    setupWebSocket(wss);

    // Restaurar temporizadores de juegos activos
    await restoreTimers(wss);

    server.listen(PORT, "0.0.0.0", () => {
      const serverIp =
        require("os")
          .networkInterfaces()
          ["Ethernet"]?.find((i) => i.family === "IPv4")?.address ||
        "localhost";
      console.log(`=================================================`);
      console.log(`Servidor corriendo en el puerto ${PORT}`);
      console.log(`WebSocket disponible en: ws://${serverIp}:${PORT}/ws`);
      console.log(`API disponible en: http://${serverIp}:${PORT}/api`);
      console.log(`IP del servidor: ${serverIp}`);
      console.log(`=================================================`);
    });
  } catch (err) {
    console.error("Error al conectar a MongoDB:", err);
    process.exit(1);
  }
};

startServer();