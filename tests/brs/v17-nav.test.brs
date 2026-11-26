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
