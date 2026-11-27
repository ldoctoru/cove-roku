// (v1.7 DIAG M-9) scripts/convert-cove-prints.js: print "Cove: ..." → Log.line(...)
"use strict";
const test = require("node:test");
const assert = require("node:assert");
const { convertLine, convertText } = require("../../scripts/convert-cove-prints.js");

test("a plain line", () => {
    assert.strictEqual(convertLine('    print "Cove: ignored a repeated deep link"').line, '    Log.line("Cove: ignored a repeated deep link")');
});

test("parts joined, non-strings through Util.toText", () => {
    const r = convertLine('    print "Cove: startup "; ms; " ms  "; label');
    assert.strictEqual(r.line, '    Log.line("Cove: startup " + Util.toText(ms) + " ms  " + Util.toText(label))');
});

test("calls with commas and semicolons inside strings / brackets", () => {
    const r = convertLine('print "Cove: a; b"; foo(x, y); "c, d"; Util.redact(z)');
    assert.strictEqual(r.line, 'Log.line("Cove: a; b" + Util.toText(foo(x, y)) + "c, d" + Util.redact(z))');
});

test("Util.toText / Util.redact kept, but not a longer expression starting with one", () => {
    assert.strictEqual(convertLine('print "Cove: "; Util.toText(a)').line, 'Log.line("Cove: " + Util.toText(a))');
    assert.strictEqual(convertLine('print "Cove: "; Util.toText(a) + b').line, 'Log.line("Cove: " + Util.toText(Util.toText(a) + b))');
});

test("single-line if and a trailing comment", () => {
    const r = convertLine('    if x then print "Cove: x "; n \' why');
    assert.strictEqual(r.line, '    if x then Log.line("Cove: x " + Util.toText(n)) \' why');
});

test("doubled quotes inside a string", () => {
    assert.strictEqual(convertLine('print "Cove: say ""hi"""').line, 'Log.line("Cove: say ""hi""")');
});

test("skipped: else on the same line, a comma separator, a ':' separator", () => {
    assert.ok(convertLine('if a then print "Cove: a" else b = 1').skip);
    assert.ok(convertLine('print "Cove: a", b').skip);
    assert.ok(convertLine('print "Cove: a" : b = 1').skip);
});

test("other prints untouched", () => {
    assert.strictEqual(convertLine('print "not cove"').changed, false);
    assert.strictEqual(convertLine("' print \"Cove: in a comment\"").changed, false);
});

test("the import goes after the last import", () => {
    const r = convertText('import "pkg:/source/Util.bs"\nimport "pkg:/source/Api.bs"\n\nsub a()\n    print "Cove: x"\nend sub\n');
    assert.strictEqual(r.count, 1);
    assert.ok(r.text.startsWith('import "pkg:/source/Util.bs"\nimport "pkg:/source/Api.bs"\nimport "pkg:/source/Log.bs"\n'));
    const again = convertText(r.text);
    assert.strictEqual(again.count, 0);
    assert.strictEqual(again.text, r.text);
});

test("no change: no import added", () => {
    const src = 'sub a()\n    print "x"\nend sub\n';
    assert.strictEqual(convertText(src).text, src);
});
