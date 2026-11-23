' SetRows (source/SetRows.bs): the v1.5 Mac-format Settings rows (focus, heights, scrolling, tabs, the choice
' list's place, labels, Audio Guide speech)

sub test_takesFocus()
    t_ok(not SetRows_takesFocus({ kind: "head", text: "Rows" }), "heading")
    t_ok(not SetRows_takesFocus({ kind: "note", text: "Help" }), "note")
    t_ok(SetRows_takesFocus({ kind: "switch", id: "x", label: "X", on: true }), "switch")
    t_ok(not SetRows_takesFocus({ kind: "switch", id: "x", label: "X", on: true, dim: true }), "dimmed switch")
    t_ok(SetRows_takesFocus({ kind: "keys", label: "OK", sub: "Play" }), "a remote key")
    t_ok(not SetRows_takesFocus({}), "no kind")
    t_ok(not SetRows_takesFocus({ kind: "cols", cols: ["Top Bar"] }), "table column titles")
    t_ok(SetRows_takesFocus({ kind: "lib", id: "1", label: "Movies" }), "a library line")
end sub

sub test_rowHeight()
    t_eq(SetRows_rowHeight({ kind: "link", label: "Home" }, 100), 72, "one-line row")
    t_eq(SetRows_rowHeight({ kind: "head", text: "Rows" }, 100), 70, "heading")
    t_eq(SetRows_rowHeight({ kind: "cols", cols: [] }, 100), 44, "column titles")
    t_eq(SetRows_rowHeight({ kind: "note", text: "Short." }, 100), 44, "one-line note")
    t_eq(SetRows_rowHeight({ kind: "server", label: "Emby", sub: "liviu  ·  http://10.0.0.2:8096" }, 100), 96, "two-line row")
    t_eq(SetRows_rowHeight({ kind: "info", label: "Version", value: "1.5.0", sub: "" }, 100), 72, "info without a second line")
    t_eq(SetRows_gapAfter({ kind: "head" }), 0, "no gap under a heading")
    t_eq(SetRows_gapAfter({ kind: "switch" }), 8, "gap under a row")
    t_eq(SetRows_charsFor(1384), 106, "characters in the wide column")
    t_eq(SetRows_charsFor(100), 30, "never under 30")
end sub

sub test_tabStep_popTop()
    t_eq(SetRows_tabStep(0, -1, 9), 0, "stays on the first tab")
    t_eq(SetRows_tabStep(3, 1, 9), 4, "next tab")
    t_eq(SetRows_tabStep(8, 1, 9), 8, "stays on the last tab")
    t_eq(SetRows_popTop(500, 72, 200, 40, 1040), 436, "centred on its row")
    t_eq(SetRows_popTop(1000, 72, 400, 40, 1040), 640, "kept above the bottom")
    t_eq(SetRows_popTop(20, 72, 400, 40, 1040), 40, "kept below the top")
    t_eq(SetRows_tabSpeech("Home", 1, 9), "Home, tab, 2 of 9", "tab speech")
end sub

sub test_scrollFor()
    t_eq(SetRows_scrollFor(0, 100, 84, 910, 2000, 90), 0, "already on screen")
    t_eq(SetRows_scrollFor(0, 900, 84, 910, 2000, 90), 164, "below: scrolls down to show it with the margin")
    t_eq(SetRows_scrollFor(500, 520, 84, 910, 2000, 90), 430, "above: scrolls up")
    t_eq(SetRows_scrollFor(0, 1900, 84, 910, 2000, 90), 1090, "never past the end")
    t_eq(SetRows_scrollFor(0, 900, 84, 910, 800, 90), 0, "a short page never scrolls")
end sub

sub test_titleCase()
    t_eq(SetRows_titleCase("Text size"), "Text Size", "two words")
    t_eq(SetRows_titleCase("Distance from bottom"), "Distance from Bottom", "small word stays")
    t_eq(SetRows_titleCase("of mice and men"), "Of Mice and Men", "first word always")
    t_eq(SetRows_titleCase(""), "", "empty")
end sub

sub test_libIcon_countOn()
    t_eq(SetRows_libIcon("movies"), "film", "movies")
    t_eq(SetRows_libIcon("TVShows"), "tv", "shows")
    t_eq(SetRows_libIcon("music"), "folder", "others")
    t_eq(SetRows_countOn([{ on: true }, { on: false }, { on: true }]), "2 of 3", "count")
    t_eq(SetRows_countOn([]), "0 of 0", "empty")
end sub

sub test_speech()
    t_eq(SetRows_speech({ kind: "switch", label: "Next Up", on: true }, false), "Next Up, switch, on", "switch on")
    t_eq(SetRows_speech({ kind: "switch", label: "Next Up", on: false }, false), "Next Up, switch, off", "switch off")
    t_eq(SetRows_speech({ kind: "choice", label: "Banner Shows", value: "Newest" }, false), "Banner Shows: Newest, menu button", "choice")
    t_eq(SetRows_speech({ kind: "link", label: "Home", value: "6 rows" }, false), "Home, 6 rows, button", "link with a value")
    t_eq(SetRows_speech({ kind: "link", label: "Remote", value: "" }, false), "Remote, button", "link")
    t_eq(SetRows_speech({ kind: "option", label: "Sidebar", checked: true }, false), "Sidebar, selected", "chosen value")
    t_eq(SetRows_speech({ kind: "move", label: "Movies", value: "" }, true), "Movies, moving. Press Up or Down to move it, then OK", "moving")
    t_eq(SetRows_speech({ kind: "move", label: "Movies", value: "Hidden" }, false), "Movies, Hidden, press OK to move it", "move row")
    t_eq(SetRows_speech({ kind: "info", label: "Version", value: "1.5.0", sub: "" }, false), "Version, 1.5.0", "info")
    t_eq(SetRows_speech({ kind: "lib", label: "Movies", value: "Sidebar · Home" }, false), "Movies, Sidebar · Home, button", "library line")
end sub

sub test_keyOf()
    t_eq(SetRows_keyOf({ kind: "switch", id: "home:resume", label: "Continue Watching" }), "switch|home:resume", "by id")
    t_eq(SetRows_keyOf({ kind: "info", id: "", label: "Version" }), "info||Version", "by label")
end sub
