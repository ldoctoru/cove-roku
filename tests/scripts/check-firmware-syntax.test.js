// node --test tests/scripts: scripts/check-firmware-syntax.js (BG-2) on a small fake project
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs"), path = require("path"), os = require("os");
const { spawnSync } = require("child_process");

const SCRIPT = path.join(__dirname, "..", "..", "scripts", "check-firmware-syntax.js");

function run(files, bsconfig) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "fwsyntax-"));
    for (const [rel, text] of Object.entries(files)) {
        fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
        fs.writeFileSync(path.join(dir, rel), text);
    }
    fs.writeFileSync(path.join(dir, "bsconfig.json"), JSON.stringify(bsconfig || { rootDir: "src" }));
    const r = spawnSync(process.execPath, [SCRIPT], { cwd: dir, encoding: "utf8" });
    fs.rmSync(dir, { recursive: true });
    return r;
}

const LOOP_OK = "sub a(list)\n    for each x in list\n        if x then\n            print x\n        end if\n    end for\nend sub\n";

test("passes without continue", () => {
    const r = run({ "src/components/A.bs": LOOP_OK });
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /1 files OK/);
});

test("fails on continue for in src", () => {
    const r = run({ "src/components/A.bs": "sub a(list)\n    for each x in list\n        if x then continue for\n    end for\nend sub\n" });
    assert.equal(r.status, 1);
    assert.match(r.stderr, /A\.bs:3/);
});

test("fails on continue while in the staging output", () => {
    const r = run({ "src/source/B.bs": LOOP_OK, "build/staging/source/B.brs": "while true\n    Continue While\nend while\n" });
    assert.equal(r.status, 1);
    assert.match(r.stderr, /B\.brs:2/);
});

test("ignores comments and strings", () => {
    const r = run({ "src/source/C.bs": "' no continue for here\nsub c()\n    print \"continue for\" ' continue while\nend sub\n" });
    assert.equal(r.status, 0, r.stderr);
});

test("staging is skipped when bsconfig sets minFirmwareVersion (bsc transpiles it)", () => {
    const r = run({ "src/source/D.bs": LOOP_OK, "build/staging/source/D.brs": "goto x\ncontinue for\n" }, { minFirmwareVersion: "11.0" });
    assert.equal(r.status, 0, r.stderr);
});
