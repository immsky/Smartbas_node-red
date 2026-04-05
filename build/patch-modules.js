#!/usr/bin/env node
/**
 * SmartBAS — Post-install module patcher
 * --------------------------------------
 * Overlays SmartBAS branding on bundled node-modules that cannot be forked
 * (node-red-dashboard, @flowfuse/node-red-dashboard). Run once after
 * `npm install` and before building the Windows installer.
 *
 * Usage:
 *   node build/patch-modules.js           (patches ./node_modules relative to repo root)
 *   node build/patch-modules.js --root X  (patches X/node_modules)
 *
 * Idempotent — safe to re-run. Creates .orig backups on first patch.
 */

"use strict";
const fs = require("fs");
const path = require("path");

// -- CLI args -----------------------------------------------------------------
let rootArg = null;
for (let i = 2; i < process.argv.length; i++) {
  if (process.argv[i] === "--root" && process.argv[i + 1]) rootArg = process.argv[++i];
}
const repoRoot = rootArg ? path.resolve(rootArg) : path.resolve(__dirname, "..");
const nodeModules = path.join(repoRoot, "node_modules");
const assetsDir = path.join(__dirname, "assets");

const log = (msg, tag = "INFO") => console.log(`[patch-modules][${tag}] ${msg}`);

// -- Helpers ------------------------------------------------------------------
function backupOnce(file) {
  const orig = file + ".orig";
  if (fs.existsSync(file) && !fs.existsSync(orig)) fs.copyFileSync(file, orig);
}

function patchFile(file, replacements) {
  if (!fs.existsSync(file)) { log(`skip (missing): ${file}`, "WARN"); return false; }
  backupOnce(file);
  let text = fs.readFileSync(file, "utf8");
  let changed = 0;
  for (const [from, to] of replacements) {
    const parts = text.split(from);
    if (parts.length > 1) { text = parts.join(to); changed += parts.length - 1; }
  }
  fs.writeFileSync(file, text, "utf8");
  log(`patched (${changed} repl): ${path.relative(repoRoot, file)}`);
  return changed > 0;
}

function copyOver(src, dst) {
  if (!fs.existsSync(src)) { log(`asset missing: ${src}`, "WARN"); return; }
  fs.copyFileSync(src, dst);
  log(`copied: ${path.relative(repoRoot, dst)}`);
}

function injectStyle(file, styleId, css) {
  if (!fs.existsSync(file)) return;
  let text = fs.readFileSync(file, "utf8");
  if (text.includes(`id="${styleId}"`)) return; // already injected
  backupOnce(file);
  const block = `<style id="${styleId}">${css}</style></head>`;
  text = text.replace("</head>", block);
  fs.writeFileSync(file, text, "utf8");
  log(`injected style: ${path.relative(repoRoot, file)}`);
}

// -----------------------------------------------------------------------------
// 1. node-red-dashboard (classic)
// -----------------------------------------------------------------------------
function patchNodeRedDashboard() {
  const d = path.join(nodeModules, "node-red-dashboard");
  if (!fs.existsSync(d)) { log("node-red-dashboard not installed, skipping", "WARN"); return; }
  log("== patching node-red-dashboard ==");

  const repl = [["Node-RED Dashboard", "SmartBAS BMS Dashboard"]];

  // Server-side + node config
  patchFile(path.join(d, "ui.js"), repl);
  patchFile(path.join(d, "nodes/ui_base.html"), repl);
  patchFile(path.join(d, "nodes/locales/en-US/ui_base.json"), repl);
  patchFile(path.join(d, "nodes/locales/de/ui_base.json"), repl);

  // Compiled front-end
  const dist = path.join(d, "dist");
  patchFile(path.join(dist, "js/app.min.js"), repl);
  patchFile(path.join(dist, "index.html"), [
    ["Welcome to the Node-RED Dashboard", "Welcome to SmartBAS BMS Dashboard"],
    ["<title></title>", "<title>SmartBAS BMS Dashboard</title>"],
    ['content="Node-RED"', 'content="SmartBAS BMS"'],
    ['content="#097479"', 'content="#D4A017"']
  ]);

  // Inject SmartBAS welcome-page theme
  injectStyle(path.join(dist, "index.html"), "SMARTBAS_THEME",
    ".node-red-ui--notabs{background:linear-gradient(135deg,#fafafa 0%,#fff8e1 100%)!important;min-height:100vh}" +
    ".node-red-ui--notabs h2{color:#1c1c1c!important;font-family:'Segoe UI',Roboto,sans-serif;font-weight:600;margin-top:20px!important}" +
    ".node-red-ui--notabs center{color:#606060}" +
    ".node-red-ui--notabs img{border-radius:8px;box-shadow:0 4px 12px rgba(212,160,23,.2);background:#fff;padding:8px}" +
    ".node-red-ui--notabs table{position:relative}" +
    ".node-red-ui--notabs table::after{content:\"\";display:block;width:60px;height:3px;background:#D4A017;margin:16px auto 0;border-radius:2px}"
  );

  // Replace dashboard icons
  copyOver(path.join(assetsDir, "dashboard-icon-64.png"),  path.join(dist, "icon64x64.png"));
  copyOver(path.join(assetsDir, "dashboard-icon-120.png"), path.join(dist, "icon120x120.png"));
  copyOver(path.join(assetsDir, "dashboard-icon-192.png"), path.join(dist, "icon192x192.png"));
}

// -----------------------------------------------------------------------------
// 2. @flowfuse/node-red-dashboard
// -----------------------------------------------------------------------------
function patchFlowfuseDashboard() {
  const d = path.join(nodeModules, "@flowfuse/node-red-dashboard");
  if (!fs.existsSync(d)) { log("@flowfuse/node-red-dashboard not installed, skipping", "WARN"); return; }
  log("== patching @flowfuse/node-red-dashboard ==");

  const indexFile = path.join(d, "dist/index.html");
  patchFile(indexFile, [
    ["<title>FlowFuse Dashboard</title>", "<title>SmartBAS BMS Dashboard</title>"],
    ['content="FlowFuse Dashboard"', 'content="SmartBAS BMS Dashboard"']
  ]);

  // Replace base64 favicon with SmartBAS glyph
  const glyph = path.join(assetsDir, "smartbas_glyph.png");
  if (fs.existsSync(glyph) && fs.existsSync(indexFile)) {
    const b64 = fs.readFileSync(glyph).toString("base64");
    let html = fs.readFileSync(indexFile, "utf8");
    const newFavicon = `href="data:image/png;base64,${b64}"`;
    const updated = html.replace(/href="data:image\/x-icon;base64,[A-Za-z0-9+/=]+"/, newFavicon)
                        .replace(/href="data:image\/png;base64,[A-Za-z0-9+/=]+"/, newFavicon);
    if (updated !== html) {
      fs.writeFileSync(indexFile, updated, "utf8");
      log("replaced flowfuse base64 favicon with SmartBAS glyph");
    }
  }
}

// -----------------------------------------------------------------------------
// Run
// -----------------------------------------------------------------------------
log(`repo root: ${repoRoot}`);
if (!fs.existsSync(nodeModules)) {
  log(`node_modules not found at ${nodeModules} — run 'npm install' first`, "ERROR");
  process.exit(1);
}
patchNodeRedDashboard();
patchFlowfuseDashboard();
log("done.");
