' NavUtil (source/NavUtil.bs): focus and layout helpers of the screens
sub test_indexOfId()
    btns = [{ id: "play" }, { id: "fav" }, { id: "trailer" }, { id: "tracks" }]
    t_eq(NavUtil_indexOfId(btns, "tracks"), 3, "found")
    t_eq(NavUtil_indexOfId(btns, "series"), -1, "missing")
    t_eq(NavUtil_indexOfId(btns, ""), -1, "empty id")
    t_eq(NavUtil_indexOfId(invalid, "play"), -1, "no list")
    t_eq(NavUtil_indexOfId([invalid, { id: "x" }], "x"), 1, "skips invalid entries")
end sub

sub test_clampIndex()
    t_eq(NavUtil_clampIndex(3, 2), 1, "list got shorter: the last one")
    t_eq(NavUtil_clampIndex(1, 4), 1, "kept")
    t_eq(NavUtil_clampIndex(0, 0), -1, "empty")
    t_eq(NavUtil_clampIndex(-1, 3), 0, "nothing focused yet")
end sub

sub test_seasonButtonText()
    t_eq(NavUtil_seasonButtonText("Season 2", 2), "Go to Season 2", "short name kept")
    t_eq(NavUtil_seasonButtonText("Specials", 0), "Go to Specials", "specials")
    t_eq(NavUtil_seasonButtonText("The Complete Director's Cut Season", 3), "Go to Season 3", "long name, number")
    long = NavUtil_seasonButtonText("The Complete Director's Cut Season", invalid)
    t_eq(long, "Go to The Complete Di...", "long name, no number: cut")
    t_ok(long.len() <= 24, "short enough")
end sub

sub test_buttonShift()
    t_eq(NavUtil_buttonShift(100, 400, 1728), 0, "fits")
    t_eq(NavUtil_buttonShift(1600, 1900, 1728), -172, "moves left until the right edge fits")
    t_eq(NavUtil_buttonShift(100, 2000, 1728), -100, "never past the row start")
end sub
