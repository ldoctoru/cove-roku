' v1.6 HOME: Emby 4.10 Home sections (HomeLayout.fromSections), See All queries (SeeAll), What's New (WhatsNew)
function t16_libs() as object
    return [{ id: "m1", collectionType: "movies" }, { id: "t1", collectionType: "tvshows" }]
end function

sub test_hasHomeSections()
    t_ok(HomeLayout_hasHomeSections(false, "4.10.0.4"), "Emby 4.10")
    t_ok(HomeLayout_hasHomeSections(false, "4.11.1.0"), "Emby 4.11")
    t_ok(HomeLayout_hasHomeSections(false, "5.0.0.1"), "Emby 5")
    t_ok(not HomeLayout_hasHomeSections(false, "4.9.1.80"), "Emby 4.9")
    t_ok(not HomeLayout_hasHomeSections(false, "4.8.10.0"), "Emby 4.8 (8 < 10)")
    t_ok(not HomeLayout_hasHomeSections(true, "10.11.0"), "Jellyfin never")
    t_ok(not HomeLayout_hasHomeSections(false, ""), "no version")
end sub

sub test_sectionList()
    t_eq(HomeLayout_sectionList(invalid).count(), 0, "invalid")
    t_eq(HomeLayout_sectionList([{ Id: "1" }, "x", 3]).count(), 1, "only objects of a bare list")
    t_eq(HomeLayout_sectionList({ Items: [{ Id: "1" }, { Id: "2" }] }).count(), 2, "a QueryResult")
end sub

sub test_fromSections_mapping()
    list = []
    list.push({ Id: "a", SectionType: "Spotlight", Name: "Spotlight" })
    list.push({ Id: "b", SectionType: "resume", Name: "Continue Watching" })
    list.push({ Id: "c", SectionType: "librarytiles" })
    list.push({ Id: "d", SectionType: "NextUp" })
    list.push({ Id: "e", SectionType: "latestmedia", ParentId: "t1" })
    list.push({ Id: "f", SectionType: "items", CustomName: "Christmas Films", Name: "Collection", ImageType: "Thumb" })
    list.push({ Id: "g", SectionType: "livetv" })
    list.push({ Id: "h", SectionType: "latestmedia", ParentItem: { Id: "m1" } })
    list.push({ Id: "i", SectionType: "genre", Name: "Comedy" })
    list.push({ SectionType: "mystery" })
    out = HomeLayout_fromSections(list, t16_libs())
    t_eq(out.ids, ["resume", "libraries", "nextup", "Lt1", "S:f", "Lm1", "S:i"], "rows in the server's order")
    t_eq(out.spotlight, "a", "spotlight feeds the banner")
    t_eq(out.skipped, ["livetv", "mystery"], "unsupported and id-less kinds skipped")
    t_eq(out.rows["S:f"].title, "Christmas Films", "custom name")
    t_ok(out.rows["S:f"].landscape, "Thumb sections are wide")
    t_eq(out.rows["S:i"].title, "Comedy", "the name without a custom one")
    t_ok(not out.rows["S:i"].landscape, "posters by default")
    t_eq(out.rows["S:f"].sectionId, "f", "section id")
end sub

sub test_fromSections_latestAll_and_empty()
    out = HomeLayout_fromSections({ Items: [{ Id: "x", SectionType: "latestmedia" }, { Id: "y", SectionType: "resume" }, { Id: "z", SectionType: "resume" }] }, t16_libs())
    t_eq(out.ids, ["Lm1", "Lt1", "resume"], "latestmedia without a library: every library; resume once")
    t_eq(HomeLayout_fromSections([], t16_libs()), invalid, "no sections: legacy fallback")
    t_eq(HomeLayout_fromSections(invalid, t16_libs()), invalid, "failed: legacy fallback")
    t_eq(HomeLayout_fromSections([{ Id: "g", SectionType: "livetv" }], t16_libs()), invalid, "nothing usable: legacy fallback")
    out = HomeLayout_fromSections([{ Id: "l", SectionType: "latestmedia", ParentId: "gone" }], t16_libs())
    t_eq(out.ids, ["S:l"], "a latest section of a library Cove doesn't list: its own section row")
end sub

function t16_opts() as object
    return { uid: "u1", isJellyfin: false, rewatch: false, cutoff: "", hideWatched: false, nowIso: "", fields: "Fields=X" }
end function

sub test_seeAll_requests()
    o = t16_opts()
    r = SeeAll_request({ kind: "resume" }, o)
    t_eq(r.path, "/Users/u1/Items/Resume?MediaTypes=Video&Fields=X", "resume")
    t_eq(r.fallback, "/UserItems/Resume?userId=u1&MediaTypes=Video&Fields=X", "resume, newer Jellyfin route")
    t_eq(SeeAll_request({ kind: "nextup" }, o).path, "/Shows/NextUp?UserId=u1&Fields=X", "next up on Emby")
    o.isJellyfin = true
    o.rewatch = true
    t_eq(SeeAll_request({ kind: "nextup" }, o).path, "/Shows/NextUp?UserId=u1&enableRewatching=true&Fields=X", "next up keeps the rewatch option (Jellyfin)")
    t_eq(SeeAll_request({ kind: "upcoming" }, o).path, "/Shows/Upcoming?UserId=u1&Fields=X", "upcoming")
    t_eq(SeeAll_request({ kind: "section", sectionId: "42" }, o).path, "/Users/u1/Sections/42/Items?Fields=X", "Emby section")
    fav = SeeAll_request({ kind: "favorites" }, o)
    t_eq(fav.path, "/Users/u1/Items?Filters=IsFavorite&Recursive=true&IncludeItemTypes=Movie,Series,Episode,Video&SortBy=SortName&Fields=X", "favorites")
    t_eq(fav.fallback, "/Items?userId=u1&Filters=IsFavorite&Recursive=true&IncludeItemTypes=Movie,Series,Episode,Video&SortBy=SortName&Fields=X", "favorites fallback")
    o.hideWatched = true
    t_eq(SeeAll_request({ kind: "recent" }, o).path, "/Users/u1/Items?Recursive=true&IncludeItemTypes=Movie,Series&SortBy=DateCreated,SortName&SortOrder=Descending&IsPlayed=false&Fields=X", "recent, hide watched")
    rel = SeeAll_request({ kind: "released" }, o).path
    t_ok(Instr(1, rel, "Limit=") = 0, "released: no row limit")
    t_ok(Instr(1, rel, "IsPlayed=false") > 0, "released: hide watched")
    t_eq(SeeAll_request({ kind: "nope" }, o).path, "", "unknown kind")
    t_eq(SeeAll_request(invalid, o).path, "", "no preset")
end sub

sub test_seeAll_library()
    o = t16_opts()
    lib = SeeAll_request({ kind: "library", libId: "m1", collectionType: "movies", style: "latest" }, o)
    t_eq(lib.path, "/Users/u1/Items?ParentId=m1&Recursive=true&SortBy=DateCreated,SortName&SortOrder=Descending&IncludeItemTypes=Movie&Fields=X", "films, newest first, no limit")
    t_ok(lib.paged, "paged")
    tv = SeeAll_request({ kind: "library", libId: "t1", collectionType: "tvshows", style: "latest" }, o)
    t_ok(Instr(1, tv.path, "SortBy=DateLastContentAdded,SortName") > 0, "shows by their newest episode")
    rnd = SeeAll_request({ kind: "library", libId: "m1", collectionType: "movies", style: "random" }, o)
    t_ok(not rnd.paged, "random: one page")
    t_ok(Instr(1, SeeAll_request({ kind: "library", libId: "m1", collectionType: "movies", style: "az" }, o).path, "SortBy=SortName&SortOrder=Ascending") > 0, "A-Z")
end sub

sub test_seeAll_helpers()
    t_eq(SeeAll_withoutLimit("a=1&Limit=20&b=2"), "a=1&b=2", "limit taken out")
    t_eq(SeeAll_pagePath("/x?a=1", 36, 96), "/x?a=1&StartIndex=36&Limit=96", "page")
    t_eq(SeeAll_pagePath("/x", 0, 36), "/x?StartIndex=0&Limit=36", "page without a query")
    t_eq(SeeAll_pagePath("", 0, 36), "", "no path")
    t_eq(SeeAll_columns(true), 4, "wide columns")
    t_eq(SeeAll_columns(false), 7, "poster columns")
    t_eq(SeeAll_countText(1), "1 title", "one")
    t_eq(SeeAll_countText(24), "24 titles", "many")
end sub

sub test_whatsNew_decide()
    t_eq(WhatsNew_notes().version, "1.7", "notes version")
    t_ok(WhatsNew_notes().lines.count() >= 3, "notes lines")
    t_eq(WhatsNew_decide("", "1.7.2000", false), "store", "fresh install: remember only")
    t_eq(WhatsNew_decide("", "1.7.2000", true), "show", "update from a version without the key")
    t_eq(WhatsNew_decide("", "1.6.2000", true), "show", "a dev build still numbered 1.6 shows the 1.7 notes")
    t_eq(WhatsNew_decide("1.7", "1.7.3001", true), "none", "already shown (a patch release too)")
    t_eq(WhatsNew_decide("1.6", "1.7.0", true), "show", "older seen version")
    t_eq(WhatsNew_decide("1.8", "1.8.0", true), "none", "seen a newer version")
    t_eq(WhatsNew_decide("", "1.8.0", true), "store", "an app newer than its notes: nothing old shown")
    t_eq(WhatsNew_decide("1.5", "1.10.0", true), "store", "1.10 is newer than 1.7")
end sub

sub test_whatsNew_helpers()
    t_eq(WhatsNew_versionOf("1.6.2000"), "1.6", "app version")
    t_eq(WhatsNew_versionOf("2.0"), "2.0", "short")
    t_eq(WhatsNew_versionOf("x"), "", "not a version")
    t_ok(WhatsNew_isOlder("1.9", "1.10"), "1.9 < 1.10")
    t_ok(not WhatsNew_isOlder("1.6", "1.6"), "same")
    t_ok(WhatsNew_isOlder("1.6", "2.0"), "major")
    WhatsNew_markSeen()
    t_eq(Util_readText("whatsNewSeen"), "1.7", "seen saved")
    t_ok(Instr(1, WhatsNew_spoken(), "Continue, button") > 0, "Audio Guide text")
end sub
