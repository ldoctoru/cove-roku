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

sub test_theme_choice_default_off()
    d17_clear()
    t_eq(ThemeMusic_choice(), "off", "default Off")
    Util_writeText("themeMusic", "series")
    t_eq(ThemeMusic_choice(), "series", "Series")
    Util_writeText("themeMusic", "all")
    t_eq(ThemeMusic_choice(), "all", "Series and Movies")
    Util_writeText("themeMusic", "loud")
    t_eq(ThemeMusic_choice(), "off", "unknown = Off")
    t_eq(ThemeMusic_choices().count(), 3, "three choices")
    t_eq(ThemeMusic_choices()[0].id, "off", "Off first")
    d17_clear()
end sub

sub test_theme_playsFor()
    t_ok(not ThemeMusic_playsFor("off", "Series", false), "off")
    t_ok(ThemeMusic_playsFor("series", "Series", false), "series page")
    t_ok(ThemeMusic_playsFor("series", "Season", false), "season page")
    t_ok(not ThemeMusic_playsFor("series", "Movie", false), "movie not with Series")
    t_ok(ThemeMusic_playsFor("all", "Movie", false), "movie with Series and Movies")
    t_ok(not ThemeMusic_playsFor("all", "Episode", false), "never an episode page")
    t_ok(not ThemeMusic_playsFor("all", "BoxSet", false), "never a collection")
    t_ok(not ThemeMusic_playsFor("all", "Series", true), "never with the Audio Guide on")
end sub

sub test_theme_paths_and_stream()
    emby = { url: "https://emby.example.com", userId: "u1", token: "tokE", type: "emby" }
    jf = { url: "http://192.168.1.5:8096", userId: "u2", token: "tokJ", type: "jellyfin" }
    t_eq(ThemeMusic_songsPath(emby, "abc"), "/Items/abc/ThemeSongs?UserId=u1&InheritFromParent=true", "Emby path")
    t_eq(ThemeMusic_songsPath(jf, "abc"), "/Items/abc/ThemeSongs?userId=u2&inheritFromParent=true", "Jellyfin path")
    t_eq(ThemeMusic_firstSongId({ Items: [{ Id: "s1" }, { Id: "s2" }] }), "s1", "first song")
    t_eq(ThemeMusic_firstSongId({ Items: [] }), "", "none")
    t_eq(ThemeMusic_firstSongId(invalid), "", "no answer")
    t_eq(ThemeMusic_firstSongId({ Items: [{ Id: "../x" }, { Id: "s3" }] }), "s3", "unsafe id skipped")
    se = ThemeMusic_stream(emby, "s1")
    t_ok(se.url.startsWith("https://emby.example.com/Audio/s1/universal?"), "Emby universal URL")
    t_ok(se.url.instr("api_key=tokE") > 0, "Emby: token in the URL")
    t_eq(se.headers.count(), 0, "Emby: no header")
    t_ok(se.url.instr("Container=mp3") > 0, "MP3")
    sj = ThemeMusic_stream(jf, "s9")
    t_ok(sj.url.instr("api_key") < 0 and sj.url.instr("tokJ") < 0, "Jellyfin: no token in the URL")
    t_eq(sj.headers.count(), 1, "Jellyfin: one header")
    t_ok(sj.headers[0].startsWith("Authorization:MediaBrowser"), "Jellyfin: Authorization header")
    t_ok(sj.headers[0].instr("tokJ") > 0, "token in the header")
end sub
