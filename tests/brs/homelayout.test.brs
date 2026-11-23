' HomeLayout (source/HomeLayout.bs): Home row order and switches, saved in the registry (an in-memory mock)
function t_libs() as object
    return [{ id: "m1", collectionType: "movies" }, { id: "music", collectionType: "music" }, { id: "t1", collectionType: "tvshows" }]
end function

sub test_defaultIds()
    t_eq(HomeLayout_defaultIds(t_libs()), ["resume", "nextup", "upcoming", "favorites", "recent", "released", "Lm1", "Lt1", "libraries"], "music has no row")
end sub

sub test_state_roundTrip()
    st = { server: true, order: ["nextup", "resume", "recent"], flags: { resume: false, recent: true } }
    HomeLayout_writeState("s1", st)
    t_eq(Util_readText("homeRows:s1"), "@nextup,-resume,+recent", "saved text")
    back = HomeLayout_readState("s1")
    t_ok(back.server, "server layout flag")
    t_eq(back.order, ["nextup", "resume", "recent"], "order")
    t_eq(back.flags.resume, false, "resume off")
    t_eq(back.flags.recent, true, "recent on")
    t_ok(HomeLayout_useServerLayout("s1"), "useServerLayout")
    t_ok(not HomeLayout_useServerLayout("s2"), "other server")
end sub

sub test_orderedIds_default()
    t_eq(HomeLayout_orderedIds("new", t_libs()), HomeLayout_defaultIds(t_libs()), "nothing saved: default")
end sub

sub test_orderedIds_saved()
    ' a saved order with a removed library (Lgone) and without the new library t1
    Util_writeText("homeRows:s3", "libraries,Lgone,Lm1,resume")
    t_eq(HomeLayout_orderedIds("s3", t_libs()), ["libraries", "Lm1", "Lt1", "resume", "nextup", "upcoming", "favorites", "recent", "released"], "dropped and inserted")
end sub

sub test_move()
    libs = t_libs()
    t_ok(not HomeLayout_move("s4", libs, "resume", -1), "first row can't go up")
    t_ok(HomeLayout_move("s4", libs, "resume", 1), "moved down")
    t_eq(HomeLayout_orderedIds("s4", libs).slice(0, 2), ["nextup", "resume"], "new order")
    t_ok(not HomeLayout_move("s4", libs, "libraries", 1), "last row can't go down")
    t_ok(not HomeLayout_move("s4", libs, "nope", 1), "unknown row")
end sub

sub test_switches_and_reset()
    libs = t_libs()
    t_ok(HomeLayout_isOn("s5", "resume"), "resume on by default")
    t_ok(not HomeLayout_isOn("s5", "recent"), "recent off by default")
    HomeLayout_setOn("s5", libs, "recent", true)
    HomeLayout_setOn("s5", libs, "resume", false)
    t_ok(HomeLayout_isOn("s5", "recent"), "recent switched on")
    t_ok(not HomeLayout_isOn("s5", "resume"), "resume switched off")
    HomeLayout_move("s5", libs, "libraries", -1)
    HomeLayout_resetOrder("s5")
    t_eq(HomeLayout_orderedIds("s5", libs), HomeLayout_defaultIds(libs), "default order again")
    t_ok(HomeLayout_isOn("s5", "recent") and not HomeLayout_isOn("s5", "resume"), "switches kept")
    HomeLayout_forget("s5")
    t_eq(Util_readText("homeRows:s5"), "", "forgotten")
end sub

sub test_fromServer()
    t_eq(HomeLayout_fromServer(invalid, t_libs()), invalid, "request failed")
    t_eq(HomeLayout_fromServer({}, t_libs()), ["libraries", "resume", "nextup", "Lm1", "Lt1"], "web app defaults")
    dp = { CustomPrefs: { homesection0: "latestmedia", homesection1: "NextUp", homesection2: "livetv", homesection3: "librarybuttons", homesection4: "nextup" } }
    t_eq(HomeLayout_fromServer(dp, t_libs()), ["Lm1", "Lt1", "nextup", "libraries"], "custom order, Live TV skipped")
end sub

sub test_newRows_v110()
    libs = t_libs()
    ' an order saved before v1.1 gets Upcoming after Next Up and Recently Released after Recently Added
    Util_writeText("homeRows:s6", "recent,nextup,-resume,Lm1,libraries")
    t_eq(HomeLayout_orderedIds("s6", libs), ["recent", "released", "nextup", "upcoming", "favorites", "resume", "Lm1", "Lt1", "libraries"], "new rows placed")
    t_ok(HomeLayout_isOn("s6", "upcoming"), "upcoming on by default (hidden when empty)")
    t_ok(not HomeLayout_isOn("s6", "released"), "recently released off by default")
    HomeLayout_setOn("s6", libs, "released", true)
    HomeLayout_setOn("s6", libs, "upcoming", false)
    t_ok(HomeLayout_isOn("s6", "released") and not HomeLayout_isOn("s6", "upcoming"), "switched")
    HomeLayout_resetOrder("s6")
    t_eq(HomeLayout_orderedIds("s6", libs), HomeLayout_defaultIds(libs), "default order")
    t_ok(HomeLayout_isOn("s6", "released") and not HomeLayout_isOn("s6", "upcoming"), "new switches kept by reset")
end sub

sub test_fromServer_noNewRows()
    dp = { CustomPrefs: { homesection0: "nextup", homesection1: "latestmedia" } }
    out = HomeLayout_fromServer(dp, t_libs())
    t_eq(out, ["nextup", "Lm1", "Lt1"], "server layout: no upcoming / released")
end sub

sub test_rowQueries()
    t_eq(HomeLayout_unwatchedQuery(true), "&IsPlayed=false", "hide watched")
    t_eq(HomeLayout_unwatchedQuery(false), "", "show watched")
    t_eq(HomeLayout_nextUpQuery(false, true, "2026-01-01T00:00:00Z"), "", "Emby: nothing")
    t_eq(HomeLayout_nextUpQuery(true, false, ""), "", "Jellyfin defaults")
    t_eq(HomeLayout_nextUpQuery(true, true, ""), "&enableRewatching=true", "rewatching")
    t_eq(HomeLayout_nextUpQuery(true, true, "2026-08-19T10:00:00Z"), "&enableRewatching=true&nextUpDateCutoff=2026-08-19T10%3A00%3A00Z", "cutoff encoded")
    q = HomeLayout_releasedQuery("2026-11-17T10:00:00Z", true)
    t_ok(q.instr("SortBy=PremiereDate") >= 0 and q.instr("SortOrder=Descending") >= 0, "by premiere date")
    t_ok(q.instr("IncludeItemTypes=Movie,Episode") >= 0 and q.instr("IsMissing=false") >= 0, "movies and aired episodes")
    t_ok(q.instr("MaxPremiereDate=2026-11-17T10%3A00%3A00Z") >= 0, "nothing in the future")
    t_ok(q.instr("&IsPlayed=false") >= 0, "hide watched applies")
    t_ok(HomeLayout_releasedQuery("", false).instr("IsPlayed") < 0, "watched kept")
end sub

' (BG-5) the series Play paths (MainScene Play key, DetailsScreen loadNextUp) send no date cutoff
sub test_nextUpQuerySeriesPlay()
    t_eq(HomeLayout_nextUpQuery(false, true, ""), "", "Emby: nothing")
    t_eq(HomeLayout_nextUpQuery(true, true, ""), "&enableRewatching=true", "Jellyfin + rewatch, no cutoff")
    t_eq(HomeLayout_nextUpQuery(true, false, ""), "", "Jellyfin without rewatch")
end sub

' (v1.5) a library's Home row no longer depends on the sidebar
sub test_libraryRow_independent_of_sidebar()
    libs = t_libs()
    t_ok(HomeLayout_isOn("v15", "Lm1"), "on by default")
    ' switched off and on again: the sidebar switch is left alone
    Prefs_setLibrary("m1", "nav", false)
    HomeLayout_setOn("v15", libs, "Lm1", true)
    t_ok(HomeLayout_isOn("v15", "Lm1"), "row on while hidden from the sidebar")
    t_eq(Prefs_library("m1").nav, false, "setOn no longer puts it in the sidebar")
    HomeLayout_setOn("v15", libs, "Lm1", false)
    t_ok(not HomeLayout_isOn("v15", "Lm1"), "row off")
    t_ok(NavPrefs_isShown("side", "Lt1", libs), "Shows still in the sidebar")
    HomeLayout_setOn("v15", libs, "Lt1", false)
    t_ok(not HomeLayout_isOn("v15", "Lt1"), "Shows row off")
    t_ok(NavPrefs_isShown("side", "Lt1", libs), "and still in the sidebar")
end sub

' (v1.5 migration) hidden from the sidebar with home = true had no row before the update: still none after
sub test_libraryRow_migration()
    libs = [{ id: "a1", collectionType: "movies" }, { id: "b1", collectionType: "movies" }]
    Prefs_setLibrary("a1", "nav", false)
    t_eq(Prefs_library("a1").home, true, "saved home = true")
    t_ok(not HomeLayout_isOn("mig", "La1"), "no row before the migration ran")
    t_ok(HomeLayout_isOn("mig", "Lb1"), "the shown library keeps its row")
    t_eq(NavPrefs_migrateHome(libs), 1, "one library migrated")
    t_eq(Prefs_library("a1").home, false, "home set false once")
    t_ok(not HomeLayout_isOn("mig", "La1"), "still no row")
    HomeLayout_setOn("mig", libs, "La1", true)
    t_eq(NavPrefs_migrateHome(libs), 0, "not again")
    t_ok(HomeLayout_isOn("mig", "La1"), "switched on by the user: stays on")
end sub
