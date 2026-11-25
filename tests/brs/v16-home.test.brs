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
