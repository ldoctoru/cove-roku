' v1.4 player: the Glass3D bottom block's focus order and geometry (PlayerNav)

sub test_controlIds()
    t_eq(PlayerNav_controlIds(true), ["prev", "jumpBack", "play", "jumpFwd", "next"], "an episode: previous and next around the jumps")
    t_eq(PlayerNav_controlIds(false), ["jumpBack", "play", "jumpFwd"], "a film: no previous / next")
end sub

sub test_toolList()
    t_eq(PlayerNav_toolList({}), ["quality"], "nothing known yet: Quality alone")
    all = { episodes: true, chapters: 5, subs: true, audio: 2, speed: true, info: true }
    t_eq(PlayerNav_toolList(all), ["episodes", "chapters", "chapPrev", "chapNext", "subs", "audio", "quality", "speed", "info"], "the Mac's order")
    t_eq(PlayerNav_toolList({ chapters: 1, audio: 1, info: true }), ["chapters", "quality", "info"], "one chapter: no previous / next chapter; one audio track: no Audio")
    t_eq(PlayerNav_toolList({ episodes: false, subs: false, speed: false }), ["quality"], "false flags leave the tools out")
end sub

sub test_rowList()
    t_eq(PlayerNav_rowList(false, ["subs", "quality"]), ["jumpBack", "play", "jumpFwd", "subs", "quality"], "controls, then tools")
    t_eq(PlayerNav_rowList(true, invalid), ["prev", "jumpBack", "play", "jumpFwd", "next"], "no tools")
end sub

sub test_indexOfId()
    ids = ["jumpBack", "play", "jumpFwd"]
    t_eq(PlayerNav_indexOfId(ids, "play"), 1, "found")
    t_eq(PlayerNav_indexOfId(ids, "next"), -1, "missing")
    t_eq(PlayerNav_indexOfId(invalid, "play"), -1, "no list")
end sub

sub test_stepIndex()
    t_eq(PlayerNav_stepIndex(2, 1, 8), 3, "Right")
    t_eq(PlayerNav_stepIndex(2, -1, 8), 1, "Left")
    t_eq(PlayerNav_stepIndex(0, -1, 8), 0, "stops at the first")
    t_eq(PlayerNav_stepIndex(7, 1, 8), 7, "stops at the last")
    t_eq(PlayerNav_stepIndex(12, 1, 8), 7, "an index past the end is clamped")
    t_eq(PlayerNav_stepIndex(3, 1, 0), 0, "an empty row")
end sub

sub test_carryIndex()
    before = PlayerNav_rowList(false, ["subs", "quality"])
    after = PlayerNav_rowList(true, ["episodes", "subs", "quality"])
    t_eq(PlayerNav_carryIndex(before, 1, after), 2, "play keeps the focus when previous / next join")
    t_eq(PlayerNav_carryIndex(before, 3, after), 6, "Subtitles keeps the focus when Episodes joins")
    t_eq(PlayerNav_carryIndex(["play", "audio"], 1, ["jumpBack", "play", "jumpFwd"]), 1, "a tool that went: play / pause")
    t_eq(PlayerNav_carryIndex(invalid, 0, after), 2, "no old row: play / pause")
    t_eq(PlayerNav_carryIndex(before, 9, after), 2, "a bad old index: play / pause")
end sub

sub test_controlGeometry()
    t_eq(PlayerNav_controlSize("play"), 90, "play / pause 90")
    t_eq(PlayerNav_controlSize("jumpFwd"), 69, "jumps 69")
    t_eq(PlayerNav_controlSize("prev"), 63, "previous / next 63")
    t_eq(PlayerNav_controlXs(PlayerNav_controlIds(true), 96), [96, 189, 288, 408, 507], "30 px apart from the 96 px keyline")
    t_eq(PlayerNav_controlXs(PlayerNav_controlIds(false), 96), [96, 195, 315], "a film")
end sub

sub test_toolsGeometry()
    t_eq(PlayerNav_toolsWidth(0), 0, "no tools")
    t_eq(PlayerNav_toolsWidth(1), 84, "one cell and the padding")
    t_eq(PlayerNav_toolsWidth(6), 454, "six cells, five dividers")
    t_eq(PlayerNav_toolCellX(0), 6, "first cell after the padding")
    t_eq(PlayerNav_toolCellX(2), 154, "72 px cells with 2 px dividers")
    ' the widest bar (9 tools) still ends at x 1824 without reaching the controls (which end at 570)
    t_ok(1824 - PlayerNav_toolsWidth(9) > 570 + 300, "room for the caption between the controls and the tools")
end sub
