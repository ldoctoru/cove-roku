// Version stamping for Cove for Roku. Roku versions are major.minor.build (src/manifest); the semver patch
// is folded into build_version.
//
//   node scripts/set-version.js 1.0.1
//       Version PR: writes 1.0.1 into package.json, package-lock.json and src/manifest (build = 1000).
//   node scripts/set-version.js --tag v1.0.1 <run number>     (CI, tag builds)
//       Fails unless the tag is exactly the package.json version (a forgotten version PR breaks the tag build
//       instead of shipping a mislabelled zip) and src/manifest has the same major.minor; then stamps
//       build_version = patch * 1000 + run number % 1000 into src/manifest.
//
// build_version: Roku documents it only as an integer (sample "00150") with no stated maximum, so this keeps it
// within 5 digits and 16 bits (0..65535): patch 0..64. A higher patch always gives a higher build; the run
// number part only tells CI builds of the same version apart.
const fs = require("fs");
const path = require("path");

const BUILD_MAX = 65535;
const MAX_PATCH = Math.floor(BUILD_MAX / 1000) - 1; // 64: 64 * 1000 + 999 = 64999

function parseVersion(text) {
    const m = /^v?(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})\.(0|[1-9]\d{0,3})$/.exec(String(text || "").trim());
    if (!m) return null;
    return { major: Number(m[1]), minor: Number(m[2]), patch: Number(m[3]), text: `${m[1]}.${m[2]}.${m[3]}` };
}

function buildNumber(patch, run = 0) {
    if (!Number.isInteger(patch) || patch < 0 || patch > MAX_PATCH) {
        throw new Error(`patch ${patch} is out of range: build_version = patch * 1000 + run must stay <= ${BUILD_MAX}, so patch <= ${MAX_PATCH}`);
    }
    const r = Number(run);
    if (!/^\d+$/.test(String(run)) || !Number.isSafeInteger(r)) throw new Error(`run number "${run}" is not a whole number`);
    return patch * 1000 + (r % 1000);
}

function readManifest(text) {
    const get = (k) => { const m = new RegExp(`^${k}=(.*)$`, "m").exec(text); return m ? m[1].trim() : null; };
    return { major: get("major_version"), minor: get("minor_version"), build: get("build_version") };
}

function writeManifest(text, v, build) {
    for (const k of ["major_version", "minor_version", "build_version"]) {
        if (!new RegExp(`^${k}=`, "m").test(text)) throw new Error(`src/manifest has no ${k}= line`);
    }
    return text.replace(/^major_version=.*$/m, `major_version=${v.major}`)
        .replace(/^minor_version=.*$/m, `minor_version=${v.minor}`)
        .replace(/^build_version=.*$/m, `build_version=${build}`);
}

// Problems that should stop a tag build: [] when the tag, package.json and the manifest agree
function tagProblems(tag, pkgVersion, manifestText) {
    const t = parseVersion(tag);
    if (!t || !/^v/.test(tag)) return [`tag "${tag}" is not vMAJOR.MINOR.PATCH`];
    const out = [];
    if (t.text !== pkgVersion) out.push(`tag ${tag} doesn't match package.json version ${pkgVersion}: merge the version PR (node scripts/set-version.js ${t.text}) before tagging`);
    const m = readManifest(manifestText);
    if (m.major !== String(t.major) || m.minor !== String(t.minor)) {
        out.push(`src/manifest says ${m.major}.${m.minor}, the tag says ${t.major}.${t.minor}: run node scripts/set-version.js ${t.text} in the version PR`);
    }
    if (t.patch > MAX_PATCH) out.push(`patch ${t.patch} > ${MAX_PATCH} doesn't fit build_version (<= ${BUILD_MAX})`);
    return out;
}

function main(argv, root) {
    const file = (p) => path.join(root, p);
    const manifestPath = file("src/manifest");
    const pkg = JSON.parse(fs.readFileSync(file("package.json"), "utf8"));
    if (argv[0] === "--tag") {
        const [, tag, run = "0"] = argv;
        const manifest = fs.readFileSync(manifestPath, "utf8");
        const problems = tagProblems(tag || "", pkg.version, manifest);
        if (problems.length) {
            for (const p of problems) console.error(`::error::${p}`);
            return 1;
        }
        const v = parseVersion(tag);
        const build = buildNumber(v.patch, run);
        fs.writeFileSync(manifestPath, writeManifest(manifest, v, build));
        console.log(`manifest: ${v.major}.${v.minor}.${build} (tag ${tag}, run ${run})`);
        return 0;
    }
    const v = parseVersion(argv[0]);
    if (!v || argv.length !== 1) {
        console.error("usage: node scripts/set-version.js MAJOR.MINOR.PATCH        (version PR)\n" +
            "       node scripts/set-version.js --tag vMAJOR.MINOR.PATCH RUN (CI tag build)");
        return 2;
    }
    const build = buildNumber(v.patch, 0);
    fs.writeFileSync(manifestPath, writeManifest(fs.readFileSync(manifestPath, "utf8"), v, build));
    // package.json and package-lock.json: only the "version" fields
    for (const p of ["package.json", "package-lock.json"]) {
        if (!fs.existsSync(file(p))) continue;
        const json = JSON.parse(fs.readFileSync(file(p), "utf8"));
        json.version = v.text;
        if (json.packages && json.packages[""]) json.packages[""].version = v.text;
        fs.writeFileSync(file(p), JSON.stringify(json, null, 2) + "\n");
    }
    console.log(`version ${v.text}: package.json, package-lock.json, src/manifest (${v.major}.${v.minor}.${build})`);
    return 0;
}

module.exports = { parseVersion, buildNumber, readManifest, writeManifest, tagProblems, main, BUILD_MAX, MAX_PATCH };

if (require.main === module) {
    try {
        process.exit(main(process.argv.slice(2), path.join(__dirname, "..")));
    } catch (e) {
        console.error(`::error::${e.message}`);
        process.exit(1);
    }
}
