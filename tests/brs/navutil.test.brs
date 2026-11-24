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

' (BG-8 / review3 test 7) the stack cap and page reuse, over plain arrays
sub test_capDropIndex()
    k = ["home", "details", "person", "details", "library", "details", "details", "person", "details", "library", "details"]
    t_eq(NavUtil_capDropIndex(k, 12), -1, "11 screens: fits")
    k.push("details")
    t_eq(NavUtil_capDropIndex(k, 12), 1, "12 screens: the oldest page above Home")
    t_eq(NavUtil_capDropIndex(["home", "settings", "details", "player"], 4), 2, "settings is kept, the page goes")
    t_eq(NavUtil_capDropIndex(["home", "settings", "player"], 3), -1, "nothing droppable, the top kept")
    t_eq(NavUtil_capDropIndex(["home", "details"], 2), -1, "the top page is never dropped")
    t_eq(NavUtil_capDropIndex(invalid, 12), -1, "no stack")
end sub

sub test_pageKey()
    t_eq(NavUtil_pageKey("details", "abc", invalid, invalid), "abc", "details: item id")
    t_eq(NavUtil_pageKey("person", invalid, { id: "p1", name: "Ann" }, invalid), "p1", "person: id")
    t_eq(NavUtil_pageKey("library", invalid, invalid, { feed: "tag", tagKind: "Genre", tagId: "g7", tagName: "Comedy" }), "Genre:g7", "genre page: id")
    t_eq(NavUtil_pageKey("library", invalid, invalid, { feed: "tag", tagKind: "Studio", tagId: "", tagName: "A24" }), "Studio:A24", "studio without id: name")
    t_eq(NavUtil_pageKey("library", invalid, invalid, { feed: "", id: "lib1" }), "", "a normal library is never reused")
    t_eq(NavUtil_pageKey("search", invalid, invalid, invalid), "", "other pages")
    t_eq(NavUtil_tagPageKey("Genre", "g7", "Comedy"), "Genre:g7", "same key as the pill opens")
    t_eq(NavUtil_tagPageKey("Genre", "", ""), "", "nothing to match")
end sub

' (v1.2 NV-7) the sidebar / top bar wrap round
sub test_wrapStep()
    t_eq(NavUtil_wrapStep(0, 5, -1), 4, "before the first: the last")
    t_eq(NavUtil_wrapStep(4, 5, 1), 0, "past the last: the first")
    t_eq(NavUtil_wrapStep(2, 5, 1), 3, "down one")
    t_eq(NavUtil_wrapStep(2, 5, -1), 1, "up one")
    t_eq(NavUtil_wrapStep(0, 1, 1), 0, "one entry stays")
    t_eq(NavUtil_wrapStep(0, 0, 1), -1, "empty menu")
end sub

sub test_nextEntry()
    ' Home, Search, [Library], Recently Added, Movies, [ ], Profile, Settings
    h = [false, false, true, false, false, true, false, false]
    t_eq(NavUtil_nextEntry(h, 0, -1), 7, "Up on Home: Settings")
    t_eq(NavUtil_nextEntry(h, 7, 1), 0, "Down on Settings: Home")
    t_eq(NavUtil_nextEntry(h, 1, 1), 3, "Down skips the section title")
    t_eq(NavUtil_nextEntry(h, 6, -1), 4, "Up skips the blank section title")
    t_eq(NavUtil_nextEntry([true, false, true], 1, 1), 1, "only entry: stays")
    t_eq(NavUtil_nextEntry([true, false], 1, -1), 1, "a title first: wraps to the only entry")
    t_eq(NavUtil_nextEntry([true, true], 0, 1), -1, "no entries")
    t_eq(NavUtil_nextEntry(invalid, 0, 1), -1, "no list")
end sub

' (v1.2 NV-6) the sidebar opens on the entry last opened from it
sub test_openEntry()
    menu = [{ id: "home", label: "Home" }, { header: true, label: "Library" }, { id: "lib:0", label: "Movies" }, { id: "lib:1", label: "TV Shows" }, { id: "settings", label: "Settings" }]
    t_eq(NavUtil_openEntry(menu, "lib:1", "TV Shows", "home"), 3, "the last opened library")
    t_eq(NavUtil_openEntry(menu, "lib:1", "Kids", "home"), 0, "that index is another library now: the current page")
    t_eq(NavUtil_openEntry(menu, "", "", "home"), 0, "nothing opened yet: the current page")
    t_eq(NavUtil_openEntry(menu, "search", "Search", "home"), 0, "entry hidden since: the current page")
    t_eq(NavUtil_openEntry(menu, "", "", ""), -1, "nothing to open on (top bar keeps its place)")
    t_eq(NavUtil_openEntry(invalid, "home", "Home", "home"), -1, "no menu")
end sub

' (v1.3.1) after Home playback: the page to open (Cove for macOS returnAfterPlay / openPage)
sub test_returnPage()
    ep = { id: "e1", type: "Episode", seriesId: "s1", seasonId: "se2" }
    r = NavUtil_returnPage({ itemId: "e1", itemType: "Episode" }, ep)
    t_eq(r.itemId, "s1", "an episode: its series")
    t_eq(r.itemType, "Series", "a series page")
    t_eq(r.seasonId, "se2", "on that episode's season")
    r = NavUtil_returnPage({ itemId: "e1", itemType: "" }, ep)
    t_eq(r.itemId, "s1", "type unknown on the card: from the player")
    r = NavUtil_returnPage({ itemId: "e1", itemType: "Episode" }, invalid)
    t_eq(r.itemId, "e1", "series unknown (left during loading): the episode's page")
    t_eq(r.itemType, "Episode", "its own page")
    r = NavUtil_returnPage({ itemId: "m1", itemType: "Movie" }, { id: "m1", type: "Movie", seriesId: "", seasonId: "" })
    t_eq(r.itemId, "m1", "a film: its page")
    r = NavUtil_returnPage({ itemId: "s9", itemType: "Series" }, { id: "e5", type: "Episode", seriesId: "s9", seasonId: "x" })
    t_eq(r.itemId, "s9", "the Play key on a series card: the series page")
    t_eq(r.seasonId, invalid, "no season for a series card")
    t_eq(NavUtil_returnPage({ itemId: "e2", itemType: "" }, ep), invalid, "nothing known: nothing opens")
    t_eq(NavUtil_returnPage(invalid, ep), invalid, "not from Home")
    t_eq(NavUtil_returnPage({}, ep), invalid, "an empty returnTo field")
end sub

' (v1.5) the top bar: what fits in 1920 px, the rest behind More
sub test_topBarFit()
    pins = [true, false, false, false, true, true]
    t_eq(NavUtil_topBarFit([100, 100, 100, 100, 100, 100], pins, 80, 1000, 6), [0, 1, 2, 3, 4, 5], "everything fits")
    ' 6 x 106 = 636 > 600: pinned 3 x 106 + More 86 = 404; 100 + 6 fits once (510), twice 616 doesn't
    t_eq(NavUtil_topBarFit([100, 100, 100, 100, 100, 100], pins, 80, 600, 6), [0, 1, -1, 4, 5], "two cut behind More")
    ' a wide entry stops the run: the next ones go behind More too (the order stays)
    t_eq(NavUtil_topBarFit([100, 50, 400, 50, 100, 100], pins, 80, 600, 6), [0, 1, -1, 4, 5], "order kept")
    t_eq(NavUtil_topBarFit([100, 900, 100, 100], [true, false, true, true], 80, 600, 6), [0, -1, 2, 3], "nothing but More")
end sub
