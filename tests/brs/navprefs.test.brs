' NavPrefs (source/NavPrefs.bs): the top bar / sidebar lists, the library Home row and the v1.5 migration
function n_libs() as object
    return [{ id: "m1", title: "Movies", collectionType: "movies" }, { id: "t1", title: "Shows", collectionType: "tvshows" }]
end function

' each case starts from an empty registry (the cases of one file share it)
sub n_clear()
    sec = createObject("roRegistrySection", "Cove")
    for each k in sec.getKeyList()
        sec.delete(k)
    end for
end sub

function n_ids(list as object) as object
    out = []
    for each e in list
        if e.on then out.push(e.id) else out.push("-" + e.id)
    end for
    return out
end function

sub test_places_and_defaults()
    n_clear()
    t_eq(NavPrefs_places(), ["top", "side"], "places")
    t_eq(NavPrefs_menuStyle(), "sidebar", "sidebar by default")
    NavPrefs_setMenuStyle("topbar")
    t_eq(NavPrefs_menuStyle(), "topbar", "top bar")
    t_eq(NavPrefs_activePlace(), "top", "top bar reads the top list")
    NavPrefs_setMenuStyle("anything")
    t_eq(NavPrefs_menuStyle(), "sidebar", "unknown style: sidebar")
    list = NavPrefs_entries("side", n_libs())
    t_eq(n_ids(list), ["search", "favorites", "nowplaying", "recent", "Lm1", "Lt1"], "everything on by default")
    t_eq(list[4].label, "Movies", "library label")
    t_ok(list[4].isLibrary and list[4].collectionType = "movies", "library kind")
    t_ok(not list[0].isLibrary, "page")
    t_eq(Util_readText("navside"), "", "reading writes nothing")
end sub

sub test_migration_from_old_switches()
    n_clear()
    ' before v1.5: Favorites hidden, Shows hidden from the sidebar
    Prefs_setFlag("showFavorites", false)
    Prefs_setLibrary("t1", "nav", false)
    for each place in NavPrefs_places()
        t_eq(n_ids(NavPrefs_entries(place, n_libs())), ["search", "-favorites", "nowplaying", "recent", "Lm1", "-Lt1"], place + ": as before")
    end for
    t_ok(not NavPrefs_isShown("top", "favorites", n_libs()), "isShown follows")
    t_ok(NavPrefs_isShown("top", "Lm1", n_libs()), "Movies shown")
    t_ok(not NavPrefs_isShown("top", "nope", n_libs()), "unknown id")
end sub

sub test_setShown_each_place_own()
    n_clear()
    libs = n_libs()
    NavPrefs_setShown("top", "recent", false, libs)
    t_ok(not NavPrefs_isShown("top", "recent", libs), "off in the top bar")
    t_ok(NavPrefs_isShown("side", "recent", libs), "still on in the sidebar")
    t_eq(Util_readText("navtop"), "search,favorites,nowplaying,-recent,Lm1,Lt1", "compact text")
    t_eq(Util_readText("navside"), "", "sidebar untouched")
    NavPrefs_setShown("top", "recent", true, libs)
    t_eq(Util_readText("navtop"), "", "back to the default: key deleted")
    NavPrefs_setShown("top", "nope", false, libs)
    t_eq(Util_readText("navtop"), "", "unknown id writes nothing")
end sub

sub test_moveEntry()
    n_clear()
    libs = n_libs()
    t_ok(not NavPrefs_moveEntry("side", "search", -1, libs), "first can't go up")
    t_ok(not NavPrefs_moveEntry("side", "Lt1", 1, libs), "last can't go down")
    t_ok(not NavPrefs_moveEntry("side", "nope", 1, libs), "unknown id")
    t_ok(not NavPrefs_moveEntry("side", "recent", 2, libs), "one step only")
    t_ok(NavPrefs_moveEntry("side", "Lt1", -1, libs), "moved up")
    t_ok(NavPrefs_moveEntry("side", "search", 1, libs), "moved down")
    t_eq(n_ids(NavPrefs_entries("side", libs)), ["favorites", "search", "nowplaying", "recent", "Lt1", "Lm1"], "new order")
    t_eq(n_ids(NavPrefs_entries("top", libs)), ["search", "favorites", "nowplaying", "recent", "Lm1", "Lt1"], "top bar unchanged")
end sub

sub test_library_added_and_removed()
    n_clear()
    libs = n_libs()
    NavPrefs_setShown("side", "Lm1", false, libs)
    NavPrefs_moveEntry("side", "recent", 1, libs)
    ' (search, favorites, nowplaying, -Lm1, recent, Lt1)
    ' a new library on the server: after the last library, on
    more = [{ id: "m1", title: "Movies" }, { id: "t1", title: "Shows" }, { id: "k1", title: "Kids", collectionType: "movies" }]
    t_eq(n_ids(NavPrefs_entries("side", more)), ["search", "favorites", "nowplaying", "-Lm1", "recent", "Lt1", "Lk1"], "new library at the end of the libraries")
    ' Movies gone (another server / profile): not listed, but its place and switch come back with it
    fewer = [{ id: "t1", title: "Shows" }]
    t_eq(n_ids(NavPrefs_entries("side", fewer)), ["search", "favorites", "nowplaying", "recent", "Lt1"], "missing library not listed")
    NavPrefs_setShown("side", "favorites", false, fewer)
    t_eq(Util_readText("navside"), "search,-favorites,nowplaying,-Lm1,recent,Lt1", "missing library kept in the text")
    t_eq(n_ids(NavPrefs_entries("side", libs)), ["search", "-favorites", "nowplaying", "-Lm1", "recent", "Lt1"], "back with its switch")
    ' no libraries known yet (Settings before Home loaded): nothing is lost either
    t_ok(NavPrefs_moveEntry("side", "nowplaying", -1, []), "move without libraries")
    t_eq(Util_readText("navside"), "search,nowplaying,-favorites,-Lm1,recent,Lt1", "libraries kept")
end sub

sub test_unknown_libraries_bounded()
    n_clear()
    toks = []
    for i = 1 to 30
        toks.push("Lold" + i.toStr())
    end for
    Util_writeText("navtop", Util_join(toks, ","))
    NavPrefs_setShown("top", "search", false, n_libs())
    saved = Util_readText("navtop").split(",")
    unknown = 0
    for each tk in saved
        if tk.left(4) = "Lold" then unknown = unknown + 1
    end for
    t_eq(unknown, NavPrefs_keepUnknown(), "at most keepUnknown missing libraries")
    t_eq(saved[0], "Lold7", "the first ones dropped")
    t_ok(not NavPrefs_isShown("top", "search", n_libs()), "the change itself saved")
end sub

sub test_saved_text_is_robust()
    n_clear()
    Util_writeText("navside", ",recent,,-,search,recent,-Lt1,bogus")
    t_eq(n_ids(NavPrefs_entries("side", n_libs())), ["recent", "search", "-Lt1", "Lm1", "favorites", "nowplaying"], "empty, duplicate and unknown tokens skipped")
end sub

sub test_library_on_home_and_migration()
    n_clear()
    ' m1: in the sidebar, on Home; t1: hidden from the sidebar but home = true (had no row before v1.5);
    ' k1: hidden from the sidebar and off Home
    Prefs_setLibrary("t1", "nav", false)
    Prefs_setLibrary("k1", "nav", false)
    Prefs_setLibrary("k1", "home", false)
    t_ok(NavPrefs_libraryOnHome("m1"), "m1 on Home")
    t_ok(not NavPrefs_libraryOnHome("t1"), "t1: no row, as before the update")
    t_ok(not NavPrefs_libraryOnHome("k1"), "k1 off")
    libs = [{ id: "m1" }, { id: "t1" }, { id: "k1" }]
    t_eq(NavPrefs_migrateHome(libs), 2, "t1 and k1 migrated")
    t_eq(Prefs_library("t1").home, false, "t1 home written false")
    t_eq(NavPrefs_migrateHome(libs), 0, "only once")
    t_ok(not NavPrefs_libraryOnHome("t1"), "still no row")
    ' now the Home switch is independent of the sidebar
    NavPrefs_setLibraryOnHome("t1", true)
    t_ok(NavPrefs_libraryOnHome("t1"), "row on, library still hidden from the sidebar")
    t_eq(NavPrefs_migrateHome(libs), 0, "the migration doesn't undo it")
    t_ok(NavPrefs_libraryOnHome("t1"), "still on")
    t_eq(Prefs_library("t1").nav, false, "sidebar switch untouched")
    NavPrefs_setLibraryOnHome("m1", false)
    t_ok(not NavPrefs_libraryOnHome("m1"), "m1 off")
    t_ok(NavPrefs_isShown("side", "Lm1", [{ id: "m1", title: "Movies" }]), "m1 still in the sidebar")
end sub

sub test_fingerprint()
    n_clear()
    a = NavPrefs_fingerprint("s1")
    t_eq(NavPrefs_fingerprint("s1"), a, "stable")
    NavPrefs_setShown("top", "recent", false, n_libs())
    b = NavPrefs_fingerprint("s1")
    t_ok(a <> b, "a list change shows")
    NavPrefs_setLibraryOnHome("m1", false)
    c = NavPrefs_fingerprint("s1")
    t_ok(b <> c, "a Home row change shows")
    NavPrefs_setMenuStyle("topbar")
    t_ok(NavPrefs_fingerprint("s1") <> c, "the menu style shows")
end sub

' (v1.5) Settings → Libraries → Set All Libraries
sub test_setAll_v15()
    n_clear()
    libs = n_libs()
    t_eq(NavPrefs_setAllActions().count(), 8, "eight actions")
    t_eq(NavPrefs_setAllLibraries("hide:side", libs), 2, "two libraries")
    t_eq(n_ids(NavPrefs_entries("side", libs)), ["search", "favorites", "nowplaying", "recent", "-Lm1", "-Lt1"], "sidebar libraries off, pages kept")
    t_ok(NavPrefs_isShown("top", "Lm1", libs), "top bar untouched")
    NavPrefs_setAllLibraries("show:side", libs)
    t_eq(Util_readText("navside"), "", "back to the default list: key deleted")
    NavPrefs_setAllLibraries("hide:home", libs)
    t_ok(not NavPrefs_libraryOnHome("m1") and not NavPrefs_libraryOnHome("t1"), "Home rows off")
    t_ok(NavPrefs_libraryInMyMedia("m1"), "My Media untouched")
    NavPrefs_setAllLibraries("hide:media", libs)
    t_ok(not NavPrefs_libraryInMyMedia("t1"), "My Media off")
    NavPrefs_setAllLibraries("show:media", libs)
    t_ok(NavPrefs_libraryInMyMedia("t1"), "My Media on")
    t_eq(NavPrefs_setAllLibraries("bogus", libs), 0, "unknown action")
    t_eq(NavPrefs_setAllLibraries("show:nowhere", libs), 0, "unknown place")
    t_eq(NavPrefs_setAllLibraries("show:top", []), 0, "no libraries")
end sub
