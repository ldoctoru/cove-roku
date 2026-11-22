' HomeBanner (source/HomeBanner.bs): Settings → Home → Banner shows / Refresh banner helpers
function hb_it(id as string, kind as string, created as string, lastAdded = "" as string, played = false as boolean, art = true as boolean) as object
    tags = []
    if art then tags = ["t" + id]
    return { Id: id, Name: "Title " + id, Type: kind, DateCreated: created, DateLastContentAdded: lastAdded, BackdropImageTags: tags, UserData: { Played: played } }
end function

function hb_ids(list as object) as object
    out = []
    for each it in list
        out.push(it.Id)
    end for
    return out
end function

sub test_pref_defaultsAndRoundTrip()
    d = HomeBanner_decodePref("")
    t_eq(d.source, "newest", "default source newest")
    t_eq(d.minutes, 0, "default only when Home loads")
    t_eq(HomeBanner_encodePref("random", 30), "random,30", "encoded")
    b = HomeBanner_decodePref("favorites,60")
    t_eq(b.source, "favorites", "source back")
    t_eq(b.minutes, 60, "minutes back")
    bad = HomeBanner_decodePref("weird,7")
    t_eq(bad.source, "newest", "unknown source -> default")
    t_eq(bad.minutes, 0, "unknown minutes -> 0")
    Prefs_setBannerPref("rows", 15)
    t_eq(Util_readText("banner"), "rows,15", "one compact key")
    t_eq(Prefs_bannerPref().minutes, 15, "read back")
end sub

sub test_labels()
    t_eq(HomeBanner_sourceOptions()[0].label, "From Home Rows", "rows label")
    t_eq(HomeBanner_sourceOptions()[2].label, "Random Picks", "random label")
    t_eq(HomeBanner_refreshOptions()[3].label, "Every Hour", "hour label")
end sub

sub test_newestFirst_mergesFilmsAndShows()
    list = [hb_it("m1", "Movie", "2026-11-01T00:00:00Z"), hb_it("m2", "Movie", "2026-11-10T00:00:00Z"), hb_it("s1", "Series", "2020-01-01T00:00:00Z", "2026-11-05T00:00:00Z"), hb_it("s2", "Series", "2026-11-20T00:00:00Z")]
    t_eq(hb_ids(HomeBanner_newestFirst(list)), ["s2", "m2", "s1", "m1"], "a show's new episode counts; no DateLastContentAdded uses DateCreated")
end sub

sub test_newestFirst_stableOnTies()
    list = [hb_it("a", "Movie", "2026-01-01"), hb_it("b", "Movie", "2026-01-01"), hb_it("c", "Movie", "2026-01-02")]
    t_eq(hb_ids(HomeBanner_newestFirst(list)), ["c", "a", "b"], "equal dates keep order")
end sub

sub test_pickTitles_filtersAndCaps()
    list = [hb_it("e1", "Episode", "x"), hb_it("m1", "Movie", "x", "", false, false), hb_it("m2", "Movie", "x")]
    t_eq(hb_ids(HomeBanner_pickTitles(list)), ["m2"], "no episodes, no titles without a backdrop")
    many = []
    for i = 1 to 12
        many.push(hb_it("m" + i.toStr(), "Movie", "x"))
    end for
    many.push(hb_it("m3", "Movie", "x"))
    t_eq(HomeBanner_pickTitles(many).count(), 8, "8 at most")
end sub

sub test_preferUnwatched()
    list = [hb_it("w1", "Movie", "x", "", true), hb_it("u1", "Movie", "x"), hb_it("u2", "Series", "x"), hb_it("u3", "Movie", "x"), hb_it("u4", "Movie", "x")]
    t_eq(hb_ids(HomeBanner_preferUnwatched(list)), ["u1", "u2", "u3", "u4"], "4 unwatched: only those")
    few = [hb_it("w1", "Movie", "x", "", true), hb_it("u1", "Movie", "x"), hb_it("u2", "Movie", "x")]
    t_eq(HomeBanner_preferUnwatched(few).count(), 3, "fewer than 4 unwatched: everything")
end sub

sub test_fallback()
    t_eq(HomeBanner_resolveTitles("newest", invalid), invalid, "failed request -> rows")
    t_eq(HomeBanner_fallbackReason("newest", invalid), "request failed", "reason failed")
    t_eq(HomeBanner_resolveTitles("favorites", []), invalid, "no favorites -> rows")
    t_eq(HomeBanner_fallbackReason("favorites", [hb_it("e", "Episode", "x")]), "no titles", "only episodes -> no titles")
    t_eq(HomeBanner_resolveTitles("rows", [hb_it("m", "Movie", "x")]), invalid, "From Home Rows ignores fetched")
    t_eq(hb_ids(HomeBanner_resolveTitles("random", [hb_it("m", "Movie", "x")])), ["m"], "fetched kept")
end sub

sub test_avoidingPrevious()
    list = [hb_it("a", "Movie", "x"), hb_it("b", "Movie", "x"), hb_it("c", "Movie", "x")]
    t_eq(hb_ids(HomeBanner_avoidingPrevious(list, ["a"])), ["b", "c", "a"], "previous last")
end sub

sub test_queries()
    q = HomeBanner_queries("newest", "u1", ["L1", "L2"], { L1: "movies", L2: "tvshows" })
    t_eq(q.count(), 2, "movies lib: films only; shows lib: shows only")
    t_ok(q[0].instr("ParentId=L1") > 0 and q[0].instr("IncludeItemTypes=Movie&SortBy=DateCreated") > 0, "films by date added")
    t_ok(q[1].instr("IncludeItemTypes=Series&SortBy=DateLastContentAdded") > 0, "shows by latest content")
    t_eq(HomeBanner_queries("newest", "u1", ["L3"], { L3: "mixed" }).count(), 2, "mixed: both")
    t_ok(HomeBanner_queries("favorites", "u1", [], {})[0].instr("Filters=IsFavorite") > 0, "favorites filter")
    t_ok(HomeBanner_queries("random", "u1", [], {})[0].instr("SortBy=Random") > 0, "random sort")
    t_eq(HomeBanner_queries("rows", "u1", [], {}).count(), 0, "rows: no request")
end sub

sub test_refreshDue()
    t_ok(not HomeBanner_refreshDue(0, 0, 99999), "off")
    t_ok(not HomeBanner_refreshDue(15, 1000, 1000 + 899), "not yet")
    t_ok(HomeBanner_refreshDue(15, 1000, 1000 + 900), "due")
end sub
