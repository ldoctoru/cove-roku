// node --test tests/scripts: scripts/check-shadowing.js on a small fake build/staging
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs"), path = require("path"), os = require("os");
const { spawnSync } = require("child_process");

const SCRIPT = path.join(__dirname, "..", "..", "scripts", "check-shadowing.js");

function run(brs) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "shadow-"));
    fs.mkdirSync(path.join(dir, "build", "staging", "source"), { recursive: true });
    fs.writeFileSync(path.join(dir, "build", "staging", "source", "Items.brs"), brs);
    const r = spawnSync(process.execPath, [SCRIPT], { cwd: dir, encoding: "utf8" });
    fs.rmSync(dir, { recursive: true });
    return r;
}

test("passes when namespace functions are only called", () => {
    const r = run("function Items_tagOf(it)\n    return it.tag\nend function\n\nfunction Items_x()\n    return Items_tagOf({})\nend function\n");
    assert.equal(r.status, 0, r.stderr);
    assert.match(r.stdout, /1 files OK/);
});

test("fails when a namespace function name is used as a value", () => {
    // (what BrighterScript emits for a parameter `tag` next to a sibling `function tag()`)
    const r = run("function Items_tag(it)\n    return \"\"\nend function\n\nfunction Items_x(Items_tag)\n    Items_tag = \"x\"\n    return Items_tag\nend function\n");
    assert.equal(r.status, 1);
    assert.match(r.stderr, /'Items_tag' is a function used as a value/);
});

test("ignores comment lines", () => {
    const r = run("function Items_tag(it)\n    return \"\"\nend function\n' Items_tag is fine here\n");
    assert.equal(r.status, 0, r.stderr);
});
