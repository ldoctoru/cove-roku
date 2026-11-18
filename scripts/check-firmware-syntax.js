#!/usr/bin/env node
// (v1.1.1 BG-2) Fails the build on BrightScript syntax that older Roku OS versions can't compile.
// `continue for` / `continue while` exist only on Roku OS 11.5+, and BrighterScript keeps them as they are unless
// bsconfig.json sets "minFirmwareVersion" below 11.5 (then it rewrites them). Cove sets no minimum, so they
// must not appear in src/ (.bs / .brs) nor in build/staging (what ships). Comment lines and strings are ignored.
// Run from the project root (npm run build does it after bsc).
const fs = require("fs"), path = require("path");

const ROOT = process.cwd();
const PATTERN = /\bcontinue\s+(for|while)\b/i;

function minFirmwareSet() {
    try {
        const cfg = JSON.parse(fs.readFileSync(path.join(ROOT, "bsconfig.json"), "utf8"));
        return typeof cfg.minFirmwareVersion === "string" && cfg.minFirmwareVersion !== "";
    } catch (e) {
        return false;
    }
}

function walk(dir, out) {
    if (!fs.existsSync(dir)) return out;
    for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) walk(p, out);
        else if (/\.(bs|brs)$/i.test(e.name)) out.push(p);
    }
    return out;
}

// The code part of a line: no string literals, nothing after ' or a REM
function codeOf(line) {
    const noStrings = line.replace(/"(?:[^"]|"")*"/g, '""');
    const cut = noStrings.search(/'|\brem\b/i);
    return cut >= 0 ? noStrings.slice(0, cut) : noStrings;
}

const files = walk(path.join(ROOT, "src"), []);
if (!minFirmwareSet()) walk(path.join(ROOT, "build", "staging"), files);

const bad = [];
for (const f of files) {
    const lines = fs.readFileSync(f, "utf8").split(/\r?\n/);
    lines.forEach((line, i) => {
        if (PATTERN.test(codeOf(line))) bad.push(`${path.relative(ROOT, f)}:${i + 1}: ${line.trim()}`);
    });
}
if (bad.length) {
    console.error("check-firmware-syntax: `continue for` / `continue while` need Roku OS 11.5+; use an if/else block:");
    for (const b of bad) console.error("  " + b);
    process.exit(1);
}
console.log(`check-firmware-syntax: ${files.length} files OK`);
