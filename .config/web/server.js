import express from "express";
import { createServer } from "http";
import { WebSocketServer } from "ws";
import { watch } from "chokidar";
import { readFileSync } from "fs";

const app = express();
const server = createServer(app);
const wss = new WebSocketServer({ server });
const WS_STATE = {
  CONNECTING: 0,
  OPEN: 1,
  CLOSING: 2,
  CLOSED: 3,
};

const CSS_PATH = "./colors.css";

app.get("/colors.css", (_req, res) => {
  res.setHeader("Content-Type", "text/css");
  res.send(readFileSync(CSS_PATH, "utf8"));
});

function broadcast(msg) {
  wss.clients.forEach((client) => {
    if (client.readyState === WS_STATE.OPEN) {
      client.send(msg);
    }
  });
}

watch(CSS_PATH).on("change", () => {
  console.log("[WATCH] CSS changed");
  broadcast("changed");
});

server.listen(8765, "127.0.0.1", () => {
  console.log("Server running");
});
