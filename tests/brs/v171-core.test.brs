' v1.7.1 CORE: Home focus across reloads (NV6-1), Because cache (NV6-13), the sidebar's kept entry (NV6-10),
' the New page mark (CR-9 / NV6-8), Log batching (NV6-2 / CR-11), Diagnostics (NV6-11 / NV6-14)

sub test_lateFocusRow()
    ' Because rows at 4-5 (2), focus on Movies (6)
    t_eq(NavUtil_lateFocusRow(2, 4, 2, 0), 2, "a row above the insert stays")
    t_eq(NavUtil_lateFocusRow(4, 4, 2, 0), 6, "the row at the insert point moves down by n")
    t_eq(NavUtil_lateFocusRow(6, 4, 2, 2), 6, "replaced in place: a row below stays")
    t_eq(NavUtil_lateFocusRow(5, 4, 2, 2), 5, "replaced in place: the focused Because row stays")
    t_eq(NavUtil_lateFocusRow(6, 4, 1, 2), 5, "fewer rows: a row below moves up")
    t_eq(NavUtil_lateFocusRow(6, 4, 3, 2), 7, "more rows: a row below moves down")
    t_eq(NavUtil_lateFocusRow(5, 4, 1, 2), 4, "the focused Because row went: the last one left")
    t_eq(NavUtil_lateFocusRow(5, 4, 0, 2), 4, "all Because rows went: the row now there")
    t_eq(NavUtil_lateFocusRow(7, 4, 0, 2), 5, "all went: a row below moves up by 2")
    t_eq(NavUtil_lateFocusRow(0, 0, 0, 0), 0, "nothing changed")
end sub

sub test_rowIndexByTitle()
    titles = ["Continue Watching", "Next Up", "Because You Watched Heat", "Movies"]
    t_eq(NavUtil_rowIndexByTitle(titles, "Movies", 1), 3, "found by title")
    t_eq(NavUtil_rowIndexByTitle(titles, "Gone", 1), 1, "not found: the old index")
    t_eq(NavUtil_rowIndexByTitle(titles, "", 9), 3, "old index past the end: the last row")
    t_eq(NavUtil_rowIndexByTitle(titles, "Gone", -1), 0, "negative: the first row")
    t_eq(NavUtil_rowIndexByTitle([], "Movies", 0), -1, "no rows")
    t_eq(NavUtil_rowIndexByTitle(invalid, "Movies", 0), -1, "invalid")
end sub

sub test_titlesBefore_and_rowIndexAfter()
    old = ["Continue Watching", "Next Up", "Because You Watched Heat", "Because You Watched Alien", "Movies"]
    before = NavUtil_titlesBefore(old, [false, false, true, true, false])
    t_eq(before.count(), 2, "two rows above the Because block")
    t_ok(before.doesExist("Next Up"), "Next Up above")
    t_ok(not before.doesExist("Movies"), "Movies below")
    fresh = ["Continue Watching", "Next Up", "Movies"]
    t_eq(NavUtil_rowIndexAfter(fresh, before), 2, "back after Next Up")
    t_eq(NavUtil_rowIndexAfter(["Next Up", "Movies"], before), 1, "Continue Watching gone: still after Next Up")
    t_eq(NavUtil_rowIndexAfter(fresh, {}), 0, "first")
    t_eq(NavUtil_titlesBefore(old, []).count(), 5, "no flags: all rows")
    ' the same rule as HomeLayout.lateRowIndex
    t_eq(NavUtil_rowIndexAfter(fresh, before), HomeLayout_lateRowIndex(fresh, before), "same as lateRowIndex")
end sub

sub test_becauseStillFresh()
    t_ok(HomeLayout_becauseStillFresh(30, "a1", "a1"), "young, same last watched")
    t_ok(not HomeLayout_becauseStillFresh(30, "b2", "a1"), "something else watched since")
    t_ok(not HomeLayout_becauseStillFresh(600, "a1", "a1"), "10 minutes old")
    t_ok(not HomeLayout_becauseStillFresh(-1, "a1", "a1"), "no rows carried over")
    t_ok(HomeLayout_becauseStillFresh(0, "", ""), "nothing watched either time")
end sub

sub test_keptEntryIndex()
    before = [{ id: "home" }, { id: "search" }, { id: "lib:0" }, { id: "lib:1" }]
    after = [{ id: "home" }, { id: "new" }, { id: "search" }, { id: "lib:0" }, { id: "lib:1" }]
    t_eq(NavUtil_keptEntryIndex(before, after, 2), 3, "New put in above Movies: Movies keeps the highlight")
    t_eq(NavUtil_keptEntryIndex(after, before, 3), 2, "New gone")
    t_eq(NavUtil_keptEntryIndex(before, [{ id: "home" }], 3), 3, "entry gone: the old index (clamped by the caller)")
    t_eq(NavUtil_keptEntryIndex(invalid, after, 1), 1, "first build")
    t_eq(NavUtil_keptEntryIndex(before, after, 9), 9, "index past the old list")
end sub

sub test_overlayCurrent_marks_new()
    t_eq(NavUtil_overlayCurrent([], "notices", invalid), "new", "the New page")
    t_eq(NavUtil_overlayCurrent([], "search", invalid), "search", "unchanged for Search")
end sub
