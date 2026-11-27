' v1.7 NAV: the sidebar on the other top-level pages (NavUtil overlay helpers, M-4)

sub test_overlayScreenIds()
    ids = NavUtil_overlayScreenIds()
    for each k in ["library", "favorites", "seeall", "nowplaying", "search", "notices"]
        t_ok(NavUtil_isOverlayPage(k), k + " is top-level")
    end for
    t_eq(ids.count(), 6, "one list")
    for each k in ["home", "details", "player", "person", "settings", "missingArt", "servers", "profiles", ""]
        t_ok(not NavUtil_isOverlayPage(k), k + " is not top-level")
    end for
end sub

sub test_sideOverlayOn()
    t_ok(NavUtil_sideOverlayOn(["home", "library"]), "a library over Home")
    t_ok(NavUtil_sideOverlayOn(["home", "favorites"]), "Favorites")
    t_ok(NavUtil_sideOverlayOn(["home", "seeall"]), "See All")
    t_ok(NavUtil_sideOverlayOn(["home", "nowplaying"]), "Now Playing")
    t_ok(NavUtil_sideOverlayOn(["home", "search"]), "Search")
    t_ok(NavUtil_sideOverlayOn(["home", "library", "library"]), "My Media tile then a folder: still top-level")
    t_ok(not NavUtil_sideOverlayOn(["home"]), "Home has its own")
    t_ok(not NavUtil_sideOverlayOn(["home", "library", "details"]), "a details page")
    t_ok(not NavUtil_sideOverlayOn(["home", "details", "player"]), "the player")
    t_ok(not NavUtil_sideOverlayOn(["home", "details", "library"]), "a genre page opened from a details page")
    t_ok(not NavUtil_sideOverlayOn(["home", "settings"]), "Settings")
    t_ok(not NavUtil_sideOverlayOn(["servers", "library"]), "no Home at the bottom")
    t_ok(not NavUtil_sideOverlayOn([]), "empty stack")
    t_ok(not NavUtil_sideOverlayOn(invalid), "no stack")
end sub

sub test_overlayCurrent()
    entries = [{ id: "home" }, { id: "search" }, { header: true, label: "My Media" }, { id: "recent" }, { id: "lib:0", libId: "m1" }, { id: "lib:1", libId: "t1" }]
    t_eq(NavUtil_overlayCurrent(entries, "favorites", invalid), "favorites", "Favorites")
    t_eq(NavUtil_overlayCurrent(entries, "search", invalid), "search", "Search")
    t_eq(NavUtil_overlayCurrent(entries, "nowplaying", invalid), "nowplaying", "Now Playing")
    t_eq(NavUtil_overlayCurrent(entries, "library", { id: "", feed: "recent" }), "recent", "Recently Added")
    t_eq(NavUtil_overlayCurrent(entries, "library", { id: "t1" }), "lib:1", "a library by its id")
    t_eq(NavUtil_overlayCurrent(entries, "library", { id: "zz" }), "", "a folder that isn't an entry")
    t_eq(NavUtil_overlayCurrent(entries, "library", { id: "", feed: "tag", tagKind: "Genre" }), "", "a genre page")
    t_eq(NavUtil_overlayCurrent(entries, "library", invalid), "", "no library yet")
    t_eq(NavUtil_overlayCurrent(invalid, "library", { id: "m1" }), "", "no entries")
    t_eq(NavUtil_overlayCurrent(entries, "seeall", invalid), "", "See All has no entry")
end sub

' (the Left path of every top-level page ends at the scene: grid column 0, the first pill, an empty page)
sub test_overlayKeyAction()
    t_eq(NavUtil_overlayKeyAction("left", true, false), "open", "Left on a page with the rail")
    t_eq(NavUtil_overlayKeyAction("left", false, false), "", "no rail (details, player, top bar)")
    t_eq(NavUtil_overlayKeyAction("right", true, false), "", "Right on the page is the page's")
    t_eq(NavUtil_overlayKeyAction("back", true, false), "", "Back on the page closes the page")
    t_eq(NavUtil_overlayKeyAction("right", true, true), "close", "Right closes")
    t_eq(NavUtil_overlayKeyAction("back", true, true), "close", "Back closes")
    t_eq(NavUtil_overlayKeyAction("options", true, true), "keep", "other keys stay with the open sidebar")
    t_eq(NavUtil_overlayKeyAction("play", true, true), "keep", "Play swallowed while open")
end sub

' ---------------------------------------------------------------- M-6 Because You Watched

sub t17_clearRegistry()
    sec = createObject("roRegistrySection", "Cove")
    for each k in sec.getKeyList()
        sec.delete(k)
    end for
end sub

function t17_libs() as object
    return [{ id: "m1", collectionType: "movies" }, { id: "t1", collectionType: "tvshows" }]
end function

sub test_because_layout()
    t17_clearRegistry()
    libs = t17_libs()
    defs = HomeLayout_defaultIds(libs)
    t_eq(HomeLayout_indexIn(defs, "because"), HomeLayout_indexIn(defs, "recent") + 1, "right after Recently Added")
    t_ok(not HomeLayout_isOn("b1", "because"), "off by default")
    ' a v1.6 default order written in full by a switch: still the (new) default
    Util_writeText("homeRows:b2", "resume,nextup,libraries,upcoming,favorites,+recent,released,Lm1,Lt1")
    t_eq(HomeLayout_orderedIds("b2", libs), defs, "saved v1.6 default order: the default, with because")
    ' a custom order: because after Recently Added wherever that is
    Util_writeText("homeRows:b3", "recent,Lm1,resume,nextup,libraries,upcoming,favorites,released,Lt1")
    got = HomeLayout_orderedIds("b3", libs)
    t_eq(HomeLayout_indexIn(got, "because"), HomeLayout_indexIn(got, "recent") + 1, "custom order: after Recently Added")
    t_eq(got.count(), defs.count(), "nothing lost")
    HomeLayout_setOn("b3", libs, "because", true)
    t_ok(HomeLayout_isOn("b3", "because"), "switched on")
    HomeLayout_resetOrder("b3")
    t_ok(HomeLayout_isOn("b3", "because"), "Default Order keeps the switch")
    t_eq(HomeLayout_orderedIds("b3", libs), defs, "default order")
end sub

sub test_becauseRows()
    t17_clearRegistry()
    t_eq(HomeLayout_becauseRows(), 1, "default 1")
    Util_writeText("becauseRows", "3")
    t_eq(HomeLayout_becauseRows(), 3, "3")
    Util_writeText("becauseRows", "7")
    t_eq(HomeLayout_becauseRows(), 1, "out of range: 1")
    Util_writeText("becauseRows", "x")
    t_eq(HomeLayout_becauseRows(), 1, "junk: 1")
    t_ok(PrefScope_isPersonal("becauseRows"), "personal setting")
    t_eq(HomeLayout_becauseTitle("Heat"), "Because You Watched Heat", "row title")
end sub

sub test_because_paths()
    p = HomeLayout_recommendationsPath("u1", "Fields=Overview")
    t_ok(p.startsWith("/Movies/Recommendations?UserId=u1&CategoryLimit=3&ItemLimit=12&"), "recommendations")
    t_eq(HomeLayout_similarPath("x9", "u1", "Fields=Overview"), "/Items/x9/Similar?UserId=u1&Limit=12&Fields=Overview", "similar")
    t_ok(HomeLayout_playedQuery().instr("SortBy=DatePlayed&SortOrder=Descending") >= 0, "last watched first")
end sub

sub test_becauseFromRecommendations()
    a = { Id: "a" }
    b = { Id: "b" }
    list = []
    list.push({ RecommendationType: "SimilarToRecentlyPlayed", BaselineItemName: "Heat", CategoryId: "h1", Items: [a, b] })
    list.push({ RecommendationType: "HasActorFromRecentlyPlayed", BaselineItemName: "Al Pacino", Items: [a] })
    list.push({ RecommendationType: "SimilarToRecentlyPlayed", BaselineItemName: "heat", Items: [b] })
    list.push({ RecommendationType: "SimilarToRecentlyPlayed", BaselineItemName: "Alien", Items: [] })
    list.push({ RecommendationType: "SimilarToRecentlyPlayed", BaselineItemName: "", Items: [a] })
    list.push({ RecommendationType: "BecauseYouWatched", BaselineItemName: "Ronin", Items: [b, "junk"] })
    list.push({ RecommendationType: "SimilarToLikedItem", BaselineItemName: "Up", Items: [a] })
    list.push({ RecommendationType: "SimilarToRecentlyPlayed", BaselineItemName: "Thief", Items: [a] })
    rows = HomeLayout_becauseFromRecommendations(list, 3)
    t_eq(rows.count(), 3, "three rows")
    t_eq(rows[0].name, "Heat", "server order")
    t_eq(rows[0].baseId, "h1", "baseline id")
    t_eq(rows[0].items.count(), 2, "items")
    t_eq(rows[1].name, "Ronin", "BecauseYouWatched kind, duplicate and empty ones skipped")
    t_eq(rows[1].items.count(), 1, "only objects")
    t_eq(rows[2].name, "Thief", "liked / actor kinds skipped")
    t_eq(HomeLayout_becauseFromRecommendations(list, 1).count(), 1, "row count kept")
    t_eq(HomeLayout_becauseFromRecommendations(invalid, 3).count(), 0, "failed request")
    t_eq(HomeLayout_becauseFromRecommendations({ Items: list }, 2).count(), 2, "a QueryResult")
end sub

sub test_becauseBaselines()
    played = []
    played.push({ Id: "e1", Type: "Episode", Name: "Pilot", SeriesId: "s1", SeriesName: "Lost" })
    played.push({ Id: "e2", Type: "Episode", Name: "Ep 2", SeriesId: "s1", SeriesName: "Lost" })
    played.push({ Id: "m1", Type: "Movie", Name: "Heat" })
    played.push({ Id: "m2", Type: "Movie", Name: "Ronin" })
    played.push({ Id: "e3", Type: "Episode", Name: "x", SeriesId: "", SeriesName: "" })
    played.push({ Id: "m3", Type: "Movie", Name: "Alien" })
    out = HomeLayout_becauseBaselines(played, { heat: true }, 3)
    t_eq(out.count(), 3, "three")
    t_eq(out[0].id, "s1", "an episode stands for its series")
    t_eq(out[0].name, "Lost", "series name")
    t_eq(out[1].name, "Ronin", "a name used by the recommendations skipped, one per series")
    t_eq(out[2].name, "Alien", "no series id skipped")
    t_eq(HomeLayout_becauseBaselines(played, {}, 0).count(), 0, "none wanted")
    t_eq(HomeLayout_becauseBaselines(invalid, {}, 2).count(), 0, "failed request")
end sub

sub test_lateRowIndex()
    shown = ["Continue Watching", "Next Up", "My Media", "Recently Added", "New in Movies"]
    t_eq(HomeLayout_lateRowIndex(shown, { "Continue Watching": true, "Next Up": true, "My Media": true, "Upcoming": true, "Favorites": true, "Recently Added": true }), 4, "after Recently Added")
    t_eq(HomeLayout_lateRowIndex(shown, { "Continue Watching": true, "Favorites": true }), 1, "rows before it that are empty don't count")
    t_eq(HomeLayout_lateRowIndex(shown, {}), 0, "first")
    t_eq(HomeLayout_lateRowIndex([], { "Next Up": true }), 0, "nothing shown")
end sub
