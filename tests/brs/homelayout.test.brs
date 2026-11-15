' HomeLayout (source/HomeLayout.bs): Home row order and switches, saved in the registry (an in-memory mock)
function t_libs() as object
    return [{ id: "m1", collectionType: "movies" }, { id: "music", collectionType: "music" }, { id: "t1", collectionType: "tvshows" }]
end function

sub test_defaultIds()
    t_eq(HomeLayout_defaultIds(t_libs()), ["resume", "nextup", "favorites", "recent", "Lm1", "Lt1", "libraries"], "music has no row")
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
    t_eq(HomeLayout_orderedIds("s3", t_libs()), ["libraries", "Lm1", "Lt1", "resume", "nextup", "favorites", "recent"], "dropped and inserted")
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
