' NavUtil (source/NavUtil.bs): v1.1.1 NV-13 Rewind / Fast Forward paging along a row
sub test_pageColumn()
    t_eq(NavUtil_pageColumn(0, 20, 1770, 276, 1), 6, "posters: 6 a screen")
    t_eq(NavUtil_pageColumn(18, 20, 1770, 276, 1), 19, "clamped to the last card")
    t_eq(NavUtil_pageColumn(5, 20, 1770, 396, -1), 1, "landscape: 4 a screen back")
    t_eq(NavUtil_pageColumn(2, 20, 1770, 396, -1), 0, "clamped to the first card")
    t_eq(NavUtil_pageColumn(0, 0, 1770, 276, 1), -1, "empty row")
    t_eq(NavUtil_pageColumn(0, 9, 1770, 0, 1), 1, "unknown width: one card")
end sub

sub test_rowCardWidth()
    t_eq(NavUtil_rowCardWidth([[396, 246], [276, 466]], 1), 276, "row 1")
    t_eq(NavUtil_rowCardWidth([[396, 246]], 3), 396, "last entry covers the rest")
    t_eq(NavUtil_rowCardWidth(invalid, 0), 0, "none")
end sub
