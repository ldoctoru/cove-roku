// Writes the version into src/manifest: `node scripts/set-version.js 0.2.0 [build]` (CI passes the tag and run number)
const fs = require("fs");
const [ver, build = "0"] = process.argv.slice(2);
const m = /^v?(\d+)\.(\d+)(?:\.(\d+))?$/.exec(ver || "");
if (!m) { console.error("usage: set-version.js <major.minor[.patch]> [build]"); process.exit(1); }
// Roku has major.minor.build; the patch number goes into build (patch * 10000 + build)
const b = Number(m[3] || 0) * 10000 + Number(build);
let t = fs.readFileSync("src/manifest", "utf8");
t = t.replace(/^major_version=.*$/m, `major_version=${m[1]}`)
     .replace(/^minor_version=.*$/m, `minor_version=${m[2]}`)
     .replace(/^build_version=.*$/m, `build_version=${b}`);
fs.writeFileSync("src/manifest", t);
console.log(`manifest: ${m[1]}.${m[2]}.${b}`);
