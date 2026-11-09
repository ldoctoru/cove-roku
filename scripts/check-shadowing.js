// After `bsc`: fails if a namespace function name is used as a value instead of being called.
// BrighterScript compiles a parameter/local that has the same name as a sibling namespace function into that
// function (e.g. `tag` next to `function tag()` → `Items_tag = ""`), which crashes on the Roku at runtime
// ("Type Mismatch ... Function and String") without any compile error.
const fs = require("fs"), path = require("path");
const root = "build/staging";
const files = [];
(function walk(d) { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); fs.statSync(p).isDirectory() ? walk(p) : p.endsWith(".brs") && files.push(p); } })(root);
const defs = new Set();
for (const f of files) for (const m of fs.readFileSync(f, "utf8").matchAll(/^\s*(?:function|sub)\s+([A-Za-z]+_[A-Za-z0-9_]+)\s*\(/gmi)) defs.add(m[1].toLowerCase());
let bad = 0;
for (const f of files) {
  fs.readFileSync(f, "utf8").split("\n").forEach((line, i) => {
    if (/^\s*(function|sub)\s/i.test(line) || /^\s*'/.test(line)) return;
    for (const m of line.matchAll(/\b([A-Za-z]+_[A-Za-z0-9_]+)\b(?!\s*\()/g)) {
      if (defs.has(m[1].toLowerCase())) { console.error(`${f}:${i + 1}: '${m[1]}' is a function used as a value (a parameter shadows a namespace function?)\n    ${line.trim()}`); bad++; }
    }
  });
}
if (bad) { console.error(`${bad} problem(s)`); process.exit(1); }
console.log(`check-shadowing: ${files.length} files OK`);
