' SetRows (source/SetRows.bs): the v1.5 Settings rows (focus, heights, scrolling, labels, Audio Guide speech)

sub test_takesFocus()
    t_ok(not SetRows_takesFocus({ kind: "head", text: "Rows" }), "heading")
    t_ok(not SetRows_takesFocus({ kind: "note", text: "Help" }), "note")
    t_ok(SetRows_takesFocus({ kind: "switch", id: "x", label: "X", on: true }), "switch")
    t_ok(not SetRows_takesFocus({ kind: "switch", id: "x", label: "X", on: true, dim: true }), "dimmed switch")
    t_ok(SetRows_takesFocus({ kind: "keys", label: "OK", sub: "Play" }), "a remote key")
    t_ok(not SetRows_takesFocus({}), "no kind")
end sub

sub test_rowHeight()
    t_eq(SetRows_rowHeight({ kind: "link", label: "Home" }), 84, "one-line row")
    t_eq(SetRows_rowHeight({ kind: "head", text: "Rows" }), 62, "heading")
    t_eq(SetRows_rowHeight({ kind: "note", text: "Short." }), 48, "one-line note")
    t_eq(SetRows_rowHeight({ kind: "server", label: "Emby", sub: "liviu  ·  http://10.0.0.2:8096" }), 96, "two-line row")
    t_eq(SetRows_rowHeight({ kind: "info", label: "Version", value: "1.5.0", sub: "" }), 84, "info without a second line")
    t_eq(SetRows_gapAfter({ kind: "head" }), 0, "no gap under a heading")
    t_eq(SetRows_gapAfter({ kind: "switch" }), 14, "gap under a row")
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
    t_eq(SetRows_libIcon("music"), "grid", "others")
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
end sub

sub test_keyOf()
    t_eq(SetRows_keyOf({ kind: "switch", id: "home:resume", label: "Continue Watching" }), "switch|home:resume", "by id")
    t_eq(SetRows_keyOf({ kind: "info", id: "", label: "Version" }), "info||Version", "by label")
end sub
