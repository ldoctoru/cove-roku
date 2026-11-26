' v1.7 DIAG: M-9 the Log ring buffer and the Diagnostics page's helpers, M-7 theme songs

sub d17_clear()
    sec = createObject("roRegistrySection", "Cove")
    for each k in sec.getKeyList()
        sec.delete(k)
    end for
    sec.flush()
end sub

sub test_log_keepLine_caps_the_ring()
    ring = []
    for i = 1 to 205
        Log_keepLine(ring, "Cove: line " + i.toStr(), 200)
    end for
    t_eq(ring.count(), 200, "200 kept")
    t_eq(ring[0], "Cove: line 6", "the oldest dropped first")
    t_eq(ring[199], "Cove: line 205", "the newest last")
    t_eq(Log_capacity(), 200, "capacity")
    small = Log_keepLine(["a", "b"], "c", 2)
    t_eq(small.count(), 2, "cap 2")
    t_eq(small[0], "b", "cap 2 keeps the newest")
end sub

sub test_log_lastOf()
    ring = ["a", "b", "c", "d"]
    t_eq(Log_lastOf(ring, 2).count(), 2, "two")
    t_eq(Log_lastOf(ring, 2)[0], "c", "oldest of the two first")
    t_eq(Log_lastOf(ring, 60).count(), 4, "fewer than asked")
    t_eq(Log_lastOf(invalid, 60).count(), 0, "no ring")
    t_eq(Log_lastOf(ring, 0).count(), 0, "none asked")
end sub

sub test_log_clockText()
    t_eq(Log_clockText(9, 5, 3, 7), "09:05:03.007", "padded")
    t_eq(Log_clockText(23, 59, 59, 999), "23:59:59.999", "end of day")
    dt = createObject("roDateTime")
    s = Log_stamped("Cove: x", dt)
    t_ok(s.endsWith(" Cove: x"), "stamp then the line: " + s)
    t_eq(s.len(), 12 + 1 + 7, "hh:mm:ss.mmm + space + line")
end sub

sub test_log_line_without_global_only_prints()
    ' (unit tests have no m.global and no main ring: printed, nothing kept, no crash)
    Log_line("Cove: test api_key=secret123 done")
    t_ok(true, "no crash")
    t_eq(Util_redact("Cove: test api_key=secret123 done"), "Cove: test api_key=*** done", "redacted as printed")
end sub

sub test_diag_connection_and_place()
    t_eq(Diag_connectionName("WiredConnection"), "Wired (Ethernet)", "wired")
    t_eq(Diag_connectionName("WiFiConnection"), "Wi-Fi", "wifi")
    t_eq(Diag_connectionName(""), "Not connected", "none")
    t_eq(Diag_connectionName("Other"), "Other", "unknown kept")
    t_ok(Diag_serverPlace("http://192.168.1.2:8096").startsWith("Home network"), "LAN")
    t_ok(Diag_serverPlace("https://emby.example.com").startsWith("Internet"), "WAN")
    t_eq(Diag_serverPlace(""), "No server", "no server")
    t_eq(Diag_addressOf("https://emby.example.com:8920/emby/web?api_key=abc"), "https://emby.example.com:8920", "origin only, no token")
    t_eq(Diag_serverLine("Emby", "4.9.1.80"), "Emby 4.9.1.80", "with version")
    t_eq(Diag_serverLine("Jellyfin", ""), "Jellyfin", "no version")
end sub

sub test_diag_playRows()
    none = Diag_playRows(invalid)
    t_eq(none.count(), 1, "nothing played: one row")
    t_eq(none[0].v, "Nothing played since Cove started", "nothing played text")
    t_eq(Diag_playRows({}).count(), 1, "empty lastPlay")
    lp = { title: "The Bear", subtitle: "S1:E2", method: "DirectStream", lines: [{ k: "Play method", v: "x" }, { k: "Why transcoding", v: "Audio codec" }, { k: "Audio", v: ["AAC 5.1", "AC3 2.0"] }] }
    rows = Diag_playRows(lp)
    t_eq(rows.count(), 4, "title, method, two lines (Play method skipped)")
    t_eq(rows[0].v, "The Bear  ·  S1:E2", "title and subtitle")
    t_eq(rows[1].v, "Direct Stream", "method name")
    t_eq(rows[2].k, "Why transcoding", "reason")
    t_eq(rows[3].v, "AAC 5.1  ·  AC3 2.0", "a list flattened")
    t_eq(Diag_methodName("DirectPlay"), "Direct Play", "direct play")
    t_eq(Diag_methodName("Transcode"), "Transcode", "transcode")
end sub

sub test_diag_spaceLine()
    t_eq(Diag_spaceLine(9812), "9812 bytes free of about 16 KB", "plenty")
    t_ok(Diag_spaceLine(1000).instr("low") > 0, "low warns")
end sub

sub test_diag_logRows_wraps_long_lines()
    rows = Diag_logRows(["short", "aaaa bbbb cccc dddd eeee ffff gggg hhhh"], 20)
    t_eq(rows[0].v, "short", "short line as is")
    t_eq(rows.count(), 4, "long line on three rows")
    t_eq(rows[1].v, "aaaa bbbb cccc dddd", "cut at the last space")
    t_ok(rows[2].v.startsWith("    "), "continuation indented")
    joined = ""
    for i = 1 to rows.count() - 1
        joined = joined + " " + rows[i].v.trim()
    end for
    t_eq(joined.trim(), "aaaa bbbb cccc dddd eeee ffff gggg hhhh", "nothing lost")
    ' (no space: cut hard at the width)
    hard = Diag_logRows([String(45, "x")], 20)
    t_eq(hard.count(), 3, "hard cut 20 + 16 + 9")
    t_eq(hard[0].v.len(), 20, "first piece full width")
    for each r in hard
        t_eq(r.kind, "log", "log rows")
    end for
end sub

sub test_diag_clampTop_and_position()
    t_eq(Diag_clampTop(0, -1, 100, 29), 0, "not above the top")
    t_eq(Diag_clampTop(0, 28, 100, 29), 28, "a page down")
    t_eq(Diag_clampTop(60, 28, 100, 29), 71, "last page stays full")
    t_eq(Diag_clampTop(5, 1, 10, 29), 0, "fewer rows than a page")
    t_eq(Diag_positionText(0, 29, 100), "Rows 1-29 of 100", "first page")
    t_eq(Diag_positionText(71, 29, 100), "Rows 72-100 of 100", "last page")
    t_eq(Diag_positionText(0, 29, 10), "Rows 1-10 of 10", "short")
    t_eq(Diag_positionText(0, 29, 0), "", "empty")
end sub
