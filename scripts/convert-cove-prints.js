#!/usr/bin/env node
// (v1.7 DIAG M-9) Turns `print "Cove: ..."` statements into `Log.line(...)`, so the line also lands in the
// Diagnostics ring buffer (source/Log.bs), and adds `import "pkg:/source/Log.bs"` to each changed .bs file.
//
//   node scripts/convert-cove-prints.js [--dry-run] <file.bs | dir> ...
//
// - `print "Cove: x "; n; " ms"`  →  `Log.line("Cove: x " + Util.toText(n) + " ms")`
//   (string literals stay as they are; any other part goes through Util.toText, which also keeps an invalid
//   value from stopping the app; Util.toText / Util.redact / formatJson parts are kept as they are)
// - single-line `if c then print "Cove: ..."` is converted too; a print followed by ` else ` on the same line,
//   a `,` (tab) separator or an unterminated string is left alone and listed as SKIPPED.
// - trailing `' comments` are kept.
// - source/Util.bs and source/Log.bs are never touched (Log.bs imports Util.bs).
// Exit code 0; with --dry-run nothing is written. Prints one line per file plus every skipped statement.
//
// The combine step runs it on the files the other agents own, then `npm run build` (check-shadowing catches
// a component that has a local or sub named like Log's functions).
"use strict";
const fs = require("fs");
const path = require("path");

const IMPORT = 'import "pkg:/source/Log.bs"';
const NEVER = new Set(["Util.bs", "Log.bs"]);

// Splits the text after `print ` into its parts at top-level `;` (outside strings and brackets).
// Returns { parts, comment } or { skip: reason }.
function splitPrint(rest) {
    const parts = [];
    let cur = "";
    let depth = 0;
    let i = 0;
    let comment = "";
    while (i < rest.length) {
        const c = rest[i];
        if (c === '"') {
            let j = i + 1;
            while (j < rest.length) {
                if (rest[j] === '"') {
                    if (rest[j + 1] === '"') { j += 2; continue; }
                    break;
                }
                j++;
            }
            if (j >= rest.length) return { skip: "unterminated string" };
            cur += rest.slice(i, j + 1);
            i = j + 1;
            continue;
        }
        if (c === "'" && depth === 0) { comment = rest.slice(i); break; }
        if (depth === 0 && /^\s+rem\s/i.test(rest.slice(i))) { comment = rest.slice(i).replace(/^\s+/, " "); break; }
        if (c === "(" || c === "[" || c === "{") depth++;
        if (c === ")" || c === "]" || c === "}") depth--;
        if (depth === 0 && c === ";") { parts.push(cur); cur = ""; i++; continue; }
        if (depth === 0 && c === ",") return { skip: "comma (tab) separator" };
        if (depth === 0 && /^\s+else(\s|$)/i.test(rest.slice(i))) return { skip: "else on the same line" };
        if (depth === 0 && c === ":" ) return { skip: "statement separator ':'" };
        cur += c;
        i++;
    }
    if (depth !== 0) return { skip: "unbalanced brackets" };
    parts.push(cur);
    const cleaned = parts.map((p) => p.trim()).filter((p) => p !== "");
    if (cleaned.length === 0) return { skip: "empty print" };
    return { parts: cleaned, comment: comment ? " " + comment.trim() : "" };
}

function isStringLiteral(p) {
    return /^"(?:[^"]|"")*"$/.test(p);
}

function asText(p) {
    if (isStringLiteral(p)) return p;
    if (/^(Util\.toText|Util\.redact|formatJson|Str|Stri|Util\.join)\s*\(/i.test(p) && balancedCall(p)) return p;
    return "Util.toText(" + p + ")";
}

// `f(a)(b)` or `f(a) + x` aren't a single call: only keep p as is when its first ( closes at the end
function balancedCall(p) {
    const open = p.indexOf("(");
    let depth = 0;
    let inStr = false;
    for (let i = open; i < p.length; i++) {
        const c = p[i];
        if (c === '"') inStr = !inStr;
        if (inStr) continue;
        if (c === "(") depth++;
        if (c === ")") { depth--; if (depth === 0) return i === p.length - 1; }
    }
    return false;
}

// One source line → { line, changed, skip }
function convertLine(src) {
    const re = /(^\s*|\bthen\s+)print\s+(?="Cove:)/i;
    const m = re.exec(src);
    if (!m) return { line: src, changed: false };
    const start = m.index + m[1].length;
    const head = src.slice(0, start);
    const after = src.slice(m.index + m[0].length);
    const sp = splitPrint(after);
    if (sp.skip) return { line: src, changed: false, skip: sp.skip };
    const expr = sp.parts.map(asText).join(" + ");
    return { line: head + "Log.line(" + expr + ")" + sp.comment, changed: true };
}

function addImport(text) {
    if (text.includes(IMPORT)) return text;
    const lines = text.split("\n");
    let last = -1;
    for (let i = 0; i < lines.length; i++) {
        const t = lines[i].trim();
        if (/^import\s+"/i.test(t)) { last = i; continue; }
        if (t === "" || t.startsWith("'")) { if (last >= 0) break; continue; }
        break;
    }
    lines.splice(last + 1, 0, IMPORT);
    return lines.join("\n");
}

function convertText(text) {
    const eol = text.includes("\r\n") ? "\r\n" : "\n";
    const lines = text.split(/\r?\n/);
    let count = 0;
    const skipped = [];
    const out = lines.map((l, i) => {
        const r = convertLine(l);
        if (r.changed) count++;
        if (r.skip) skipped.push({ lineNo: i + 1, reason: r.skip, text: l.trim() });
        return r.line;
    });
    let result = out.join("\n");
    if (count > 0) result = addImport(result);
    return { text: result.split("\n").join(eol), count, skipped };
}

function walk(p, acc) {
    const st = fs.statSync(p);
    if (st.isDirectory()) {
        for (const f of fs.readdirSync(p).sort()) walk(path.join(p, f), acc);
    } else if (p.endsWith(".bs")) {
        acc.push(p);
    }
    return acc;
}

function main(argv) {
    const dry = argv.includes("--dry-run");
    const targets = argv.filter((a) => a !== "--dry-run");
    if (targets.length === 0) {
        console.error("usage: node scripts/convert-cove-prints.js [--dry-run] <file.bs | dir> ...");
        return 2;
    }
    let total = 0;
    for (const f of targets.flatMap((t) => walk(t, []))) {
        if (NEVER.has(path.basename(f))) { console.log(`skip ${f} (never converted)`); continue; }
        const before = fs.readFileSync(f, "utf8");
        const r = convertText(before);
        for (const s of r.skipped) console.log(`SKIPPED ${f}:${s.lineNo} (${s.reason}): ${s.text}`);
        if (r.count === 0) continue;
        total += r.count;
        console.log(`${dry ? "would convert" : "converted"} ${r.count} in ${f}`);
        if (!dry) fs.writeFileSync(f, r.text);
    }
    console.log(`convert-cove-prints: ${total} print lines ${dry ? "to convert" : "converted"}`);
    return 0;
}

module.exports = { convertLine, convertText, splitPrint, addImport };
if (require.main === module) process.exit(main(process.argv.slice(2)));
