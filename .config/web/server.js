import express from "express";
import { createServer } from "http";
import { watch } from "chokidar";
import { readFileSync } from "fs";

const app = express();
const server = createServer(app);

const CSS_PATH = "./colors.css";

let cachedCSS = "";
let lastModified = Date.now();

// load initial
function loadCSS() {
  cachedCSS = readFileSync(CSS_PATH, "utf8");
  lastModified = Date.now();
}

loadCSS();

// watch file
watch(CSS_PATH).on("change", () => {
  console.log("[WATCH] CSS changed");
  loadCSS();
});

// simple endpoint
app.get("/colors.css", (_req, res) => {
  res.setHeader("Content-Type", "text/css");
  res.setHeader("Cache-Control", "no-cache");

  // optional: simple ETag-like behavior
  res.setHeader("X-Theme-Version", String(lastModified));

  res.send(cachedCSS);
});

// optional: lightweight "check update" endpoint (better than downloading full css every time)
app.get("/colors.meta", (_req, res) => {
  res.json({
    version: lastModified,
  });
});

server.listen(8765, "127.0.0.1", () => {
  console.log("Server running on http://127.0.0.1:8765");
});
