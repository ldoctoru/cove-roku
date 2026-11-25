' v1.5.2 screens fixes (NavUtil / DetailsHead helpers)
sub test_buttonFocus_seriesSequence()
    ' (SC5-1) a series page opens: no Play yet (no Next Up), the flag must survive
    first = DetailsHead_headerButtonIds("Series", false, false, 0)
    b1 = []
    for each id in first
        b1.push({ id: id })
    end for
    r = NavUtil_buttonFocus(b1, "", true)
    t_eq(r.id, "", "no Play yet: nothing forced")
    t_eq(r.focusPlay, true, "flag kept until Play exists")
    ' Next Up answers: Play appears, the focus was left on watched (index 0)
    second = DetailsHead_headerButtonIds("Series", false, true, 0)
    b2 = []
    for each id in second
        b2.push({ id: id })
    end for
    r = NavUtil_buttonFocus(b2, "watched", r.focusPlay)
    t_eq(r.id, "play", "Play focused once it exists")
    t_eq(r.focusPlay, false, "flag cleared")
    ' a later rebuild (trailer answer) keeps the focus where it is
    r = NavUtil_buttonFocus(b2, "fav", r.focusPlay)
    t_eq(r.id, "fav", "no flag: previous id kept")
end sub

sub test_buttonFocus_film()
    b = [{ id: "play" }, { id: "watched" }]
    r = NavUtil_buttonFocus(b, "watched", true)
    t_eq(r.id, "play", "film: Play at once")
    t_eq(r.focusPlay, false, "cleared")
    r = NavUtil_buttonFocus(b, "watched", false)
    t_eq(r.id, "watched", "toggle keeps its focus")
end sub

sub test_headerSlidesBack()
    t_eq(NavUtil_headerSlidesBack("rows"), true, "rows")
    t_eq(NavUtil_headerSlidesBack("about"), true, "about")
    t_eq(NavUtil_headerSlidesBack("season"), true, "season bar (SC5-4)")
    t_eq(NavUtil_headerSlidesBack("buttons"), false, "buttons")
    t_eq(NavUtil_headerSlidesBack("media"), false, "media pills")
    t_eq(NavUtil_headerSlidesBack("overview"), false, "overview")
end sub
