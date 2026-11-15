// node --test tests/scripts
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("fs"), path = require("path"), os = require("os");
const sv = require("../../scripts/set-version.js");

const MANIFEST = "title=Cove\nmajor_version=0\nminor_version=9\nbuild_version=0\nui_resolutions=fhd\n";

test("parseVersion takes MAJOR.MINOR.PATCH with or without v", () => {
    assert.deepEqual(sv.parseVersion("v1.0.2"), { major: 1, minor: 0, patch: 2, text: "1.0.2" });
    assert.equal(sv.parseVersion("1.0.2").text, "1.0.2");
    for (const bad of ["1.0", "v1", "1.0.2-beta", "01.0.0", "1.0.2.3", "", undefined, "v1.0.x"]) {
        assert.equal(sv.parseVersion(bad), null, String(bad));
    }
});

test("buildNumber stays within 0..65535 and orders by patch", () => {
    assert.equal(sv.buildNumber(0, 0), 0);
    assert.equal(sv.buildNumber(0, 412), 412);
    assert.equal(sv.buildNumber(1, 412), 1412);
    assert.equal(sv.buildNumber(0, 12345), 345, "run number wraps at 1000");
    assert.ok(sv.buildNumber(1, 0) > sv.buildNumber(0, 999), "a higher patch is always a higher build");
    assert.equal(sv.buildNumber(sv.MAX_PATCH, 999), 64999);
    assert.ok(sv.buildNumber(sv.MAX_PATCH, 999) <= sv.BUILD_MAX);
    assert.throws(() => sv.buildNumber(sv.MAX_PATCH + 1, 0), /out of range/);
    assert.throws(() => sv.buildNumber(0, "12a"), /whole number/);
    assert.throws(() => sv.buildNumber(0, -1), /whole number/);
});

test("tagProblems: the tag must match package.json and the manifest", () => {
    assert.deepEqual(sv.tagProblems("v0.9.0", "0.9.0", MANIFEST), []);
    assert.deepEqual(sv.tagProblems("v0.9.3", "0.9.3", MANIFEST), []);
    assert.match(sv.tagProblems("v1.0.0", "0.9.0", MANIFEST).join("\n"), /doesn't match package.json/);
    assert.match(sv.tagProblems("v1.0.0", "1.0.0", MANIFEST).join("\n"), /src\/manifest says 0.9/);
    assert.match(sv.tagProblems("1.0.0", "1.0.0", MANIFEST)[0], /not vMAJOR/);
    assert.match(sv.tagProblems("v1.0", "1.0.0", MANIFEST)[0], /not vMAJOR/);
    assert.match(sv.tagProblems("v0.9.65", "0.9.65", MANIFEST).join("\n"), /doesn't fit build_version/);
});

test("writeManifest replaces the three version lines only", () => {
    const out = sv.writeManifest(MANIFEST, sv.parseVersion("1.2.3"), 3007);
    assert.equal(out, "title=Cove\nmajor_version=1\nminor_version=2\nbuild_version=3007\nui_resolutions=fhd\n");
    assert.throws(() => sv.writeManifest("title=x\n", sv.parseVersion("1.2.3"), 0), /no major_version/);
});

function sandbox(version) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "setver-"));
    fs.mkdirSync(path.join(dir, "src"));
    fs.writeFileSync(path.join(dir, "src", "manifest"), MANIFEST);
    fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({ name: "cove-roku", version }, null, 2) + "\n");
    fs.writeFileSync(path.join(dir, "package-lock.json"), JSON.stringify({ name: "cove-roku", version, lockfileVersion: 3, packages: { "": { name: "cove-roku", version } } }, null, 2) + "\n");
    return dir;
}

function quiet(fn) {
    const log = console.log, err = console.error;
    console.log = console.error = () => {};
    try { return fn(); } finally { console.log = log; console.error = err; }
}

test("version PR mode writes package.json, package-lock.json and the manifest", () => {
    const dir = sandbox("0.9.0");
    assert.equal(quiet(() => sv.main(["1.0.1"], dir)), 0);
    assert.equal(JSON.parse(fs.readFileSync(path.join(dir, "package.json"))).version, "1.0.1");
    const lock = JSON.parse(fs.readFileSync(path.join(dir, "package-lock.json")));
    assert.equal(lock.version, "1.0.1");
    assert.equal(lock.packages[""].version, "1.0.1");
    assert.deepEqual(sv.readManifest(fs.readFileSync(path.join(dir, "src", "manifest"), "utf8")), { major: "1", minor: "0", build: "1000" });
    assert.equal(quiet(() => sv.main(["1.0"], dir)), 2, "usage error");
    fs.rmSync(dir, { recursive: true });
});

test("--tag mode stamps the build, and fails (manifest untouched) on a forgotten bump", () => {
    const dir = sandbox("0.9.0");
    assert.equal(quiet(() => sv.main(["--tag", "v1.0.0", "321"], dir)), 1);
    assert.equal(fs.readFileSync(path.join(dir, "src", "manifest"), "utf8"), MANIFEST);
    assert.equal(quiet(() => sv.main(["--tag", "v0.9.0", "321"], dir)), 0);
    assert.equal(sv.readManifest(fs.readFileSync(path.join(dir, "src", "manifest"), "utf8")).build, "321");
    assert.equal(JSON.parse(fs.readFileSync(path.join(dir, "package.json"))).version, "0.9.0", "package.json untouched");
    fs.rmSync(dir, { recursive: true });
});

test("the repository's package.json and src/manifest agree", () => {
    const root = path.join(__dirname, "..", "..");
    const pkg = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"));
    const lock = JSON.parse(fs.readFileSync(path.join(root, "package-lock.json"), "utf8"));
    const v = sv.parseVersion(pkg.version);
    assert.ok(v, `package.json version ${pkg.version} is MAJOR.MINOR.PATCH`);
    assert.equal(lock.version, pkg.version, "package-lock.json version");
    const m = sv.readManifest(fs.readFileSync(path.join(root, "src", "manifest"), "utf8"));
    assert.equal(`${m.major}.${m.minor}`, `${v.major}.${v.minor}`, "src/manifest major.minor");
});
