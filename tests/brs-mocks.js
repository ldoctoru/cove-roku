// Stand-ins for the Roku components the pure namespaces use that the Node BrightScript interpreter
// (@rokucommunity/brs) doesn't have, plus one fix for a difference from the device:
// - roRegistrySection: an in-memory registry, emptied by reset() before each test file;
// - roEVPDigest: sha1 / sha256 / md5 through Node's crypto (setup, process, update, final);
// - roRegex.replaceAll / replace: Roku writes back-references as \1, brs's replaceAll passes them to
//   JavaScript unchanged (JavaScript expects $1), so Util.redact would print "\1\2***" instead of the key.
const crypto = require("crypto");
const T = require("@rokucommunity/brs").types;

let registry = new Map(); // section name → Map(key → value)

function reset() {
    registry = new Map();
}

function sectionOf(name) {
    if (!registry.has(name)) registry.set(name, new Map());
    return registry.get(name);
}

const str = (name) => new T.StdlibArgument(name, T.ValueKind.String);
const method = (name, args, returns, impl) => new T.Callable(name, { signature: { args, returns }, impl });

class RoRegistrySection extends T.BrsComponent {
    constructor(name) {
        super("roRegistrySection");
        this.kind = T.ValueKind.Object;
        const sec = () => sectionOf(name.value);
        this.registerMethods({
            ifRegistrySection: [
                method("read", [str("key")], T.ValueKind.String, (_, k) => new T.BrsString(sec().get(k.value) ?? "")),
                method("write", [str("key"), str("value")], T.ValueKind.Boolean, (_, k, v) => {
                    sec().set(k.value, v.value);
                    return T.BrsBoolean.True;
                }),
                method("delete", [str("key")], T.ValueKind.Boolean, (_, k) => T.BrsBoolean.from(sec().delete(k.value))),
                method("exists", [str("key")], T.ValueKind.Boolean, (_, k) => T.BrsBoolean.from(sec().has(k.value))),
                method("flush", [], T.ValueKind.Boolean, () => T.BrsBoolean.True),
                method("getKeyList", [], T.ValueKind.Object, () => new T.RoArray([...sec().keys()].map((k) => new T.BrsString(k)))),
            ],
        });
    }
    toString() {
        return "<Component: roRegistrySection>";
    }
}

class RoEVPDigest extends T.BrsComponent {
    constructor() {
        super("roEVPDigest");
        this.kind = T.ValueKind.Object;
        let hash = null, algo = "";
        const bytesOf = (ba) => Buffer.from(ba.elements ?? []);
        this.registerMethods({
            ifEVPDigest: [
                method("setup", [str("digestType")], T.ValueKind.Int32, (_, t) => {
                    algo = t.value.toLowerCase();
                    try { hash = crypto.createHash(algo); return new T.Int32(0); } catch { hash = null; return new T.Int32(1); }
                }),
                method("reinit", [], T.ValueKind.Int32, () => { hash = crypto.createHash(algo); return new T.Int32(0); }),
                method("update", [new T.StdlibArgument("bytes", T.ValueKind.Object)], T.ValueKind.Void, (_, ba) => {
                    hash.update(bytesOf(ba));
                    return T.BrsInvalid.Instance;
                }),
                method("final", [], T.ValueKind.String, () => {
                    const out = hash.digest("hex");
                    hash = crypto.createHash(algo);
                    return new T.BrsString(out);
                }),
                method("process", [new T.StdlibArgument("bytes", T.ValueKind.Object)], T.ValueKind.String, (_, ba) => {
                    hash.update(bytesOf(ba));
                    const out = hash.digest("hex");
                    hash = crypto.createHash(algo);
                    return new T.BrsString(out);
                }),
            ],
        });
    }
    toString() {
        return "<Component: roEVPDigest>";
    }
}

// roRegex with Roku-style \1 back-references in replace / replaceAll
function patchedRegex(_interpreter, expression, flags) {
    const re = new T.RoRegex(expression, flags ?? new T.BrsString(""));
    const js = (s) => s.replace(/\$/g, "$$$$").replace(/\\(\d)/g, "$$$1");
    for (const name of ["replace", "replaceall"]) {
        const orig = re.getMethod(name);
        if (!orig) continue;
        const sig = orig.signatures[0];
        const fixed = new T.Callable(name, {
            signature: sig.signature,
            impl: (interp, s, r) => sig.impl(interp, s, new T.BrsString(js(r.value))),
        });
        re.methods.set(name, fixed);
    }
    return re;
}

function install() {
    // (the third value is the number of CreateObject parameters, as in brs's own table)
    T.BrsObjects.set("roRegistrySection", (_, name) => new RoRegistrySection(name), 1);
    T.BrsObjects.set("roEVPDigest", () => new RoEVPDigest(), 0);
    T.BrsObjects.set("roRegex", patchedRegex, 2);
}

module.exports = { install, reset };
