// Unit tests for the pure BrightScript namespaces, run on the BUILD OUTPUT (build/staging/source/*.brs, what
// ships in the zip) with the Node BrightScript interpreter @rokucommunity/brs. Run `npm run build` first;
// `npm test` does both.
//
// Each tests/brs/*.test.brs holds `sub test_<name>()` cases that call the t_* asserts in tests/brs/assert.brs.
// The runner loads every source file except main.brs, the asserts and one test file, and generates a Main that
// runs each test_ sub in order. Each test file gets a fresh interpreter and an empty registry (brs-mocks.js).
// A runtime error stops that file and counts as a failure.
const fs = require("fs"), path = require("path"), os = require("os");
const { Writable } = require("stream");
const brs = require("@rokucommunity/brs");
const mocks = require("./brs-mocks");

const ROOT = path.join(__dirname, "..");
const STAGING = path.join(ROOT, "build", "staging");
const SOURCE = path.join(STAGING, "source");
const TESTS = path.join(__dirname, "brs");

if (!fs.existsSync(SOURCE)) {
    console.error("tests: build/staging/source is missing; run `npm run build` first");
    process.exit(1);
}
mocks.install();

const sources = fs.readdirSync(SOURCE).filter((f) => f.endsWith(".brs") && f !== "main.brs").sort().map((f) => path.join(SOURCE, f));
const only = process.argv[2]; // optional: a part of a test file name
const files = fs.readdirSync(TESTS).filter((f) => f.endsWith(".test.brs") && (!only || f.includes(only))).sort();
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "cove-tests-"));
// (the interpreter's root holds only the manifest, so it doesn't scan the SceneGraph components)
fs.copyFileSync(path.join(STAGING, "manifest"), path.join(tmp, "manifest"));

function capture() {
    let text = "";
    const stream = new Writable({ write(chunk, _enc, done) { text += chunk.toString(); done(); } });
    return { stream, text: () => text };
}

async function runFile(file) {
    const src = fs.readFileSync(path.join(TESTS, file), "utf8");
    const cases = [...src.matchAll(/^\s*sub\s+(test_[A-Za-z0-9_]+)\s*\(\s*\)/gim)].map((m) => m[1]);
    const main = ["sub Main()", `    t_begin("${file}")`]
        .concat(cases.flatMap((c) => [`    t_case("${c}")`, `    ${c}()`]))
        .concat(["    t_end()", "end sub", ""]).join("\n");
    const mainFile = path.join(tmp, file.replace(/\.test\.brs$/, ".main.brs"));
    fs.writeFileSync(mainFile, main);
    mocks.reset();
    const out = capture(), err = capture();
    let crash = "";
    try {
        await brs.execute([...sources, path.join(TESTS, "assert.brs"), path.join(TESTS, file), mainFile],
            { root: tmp, stdout: out.stream, stderr: err.stream, noColor: true });
    } catch (e) {
        crash = e && e.message ? e.message : String(e);
    }
    const lines = out.text().split("\n");
    const result = lines.map((l) => /^RESULT (\d+) (\d+)$/.exec(l.trim())).find(Boolean);
    const fails = lines.filter((l) => l.startsWith("FAIL "));
    const errText = (err.text() + (crash ? "\n" + crash : "")).trim();
    if (!result || errText) {
        const last = lines.filter((l) => l.startsWith("CASE ")).pop();
        return { file, pass: Number(result ? result[1] : 0), fail: fails.length + 1, cases: cases.length, report: [`FAIL ${file}: stopped${last ? " in " + last.slice(5) : ""}`, ...fails, errText].filter(Boolean) };
    }
    return { file, pass: Number(result[1]), fail: Number(result[2]), cases: cases.length, report: fails };
}

(async () => {
    let pass = 0, fail = 0;
    for (const f of files) {
        const r = await runFile(f);
        pass += r.pass;
        fail += r.fail;
        console.log(`${r.fail ? "FAIL" : "ok  "} ${f}: ${r.cases} cases, ${r.pass} checks passed${r.fail ? `, ${r.fail} failed` : ""}`);
        for (const line of r.report) console.log("    " + line.replace(/\n/g, "\n    "));
    }
    fs.rmSync(tmp, { recursive: true, force: true });
    if (!files.length) { console.error("tests: no test files"); process.exit(1); }
    console.log(`brs tests: ${pass} checks passed, ${fail} failed (${files.length} files, ${sources.length} source files)`);
    process.exit(fail ? 1 : 0);
})();
