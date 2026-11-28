' v1.7 (Liviu): the banner searches the whole server when no library has a Home row
sub test_anyFilmsOrShows()
    t_ok(HomeBanner_anyFilmsOrShows([{ id: "1", collectionType: "music" }, { id: "2", collectionType: "movies" }]), "a film library")
    t_ok(HomeBanner_anyFilmsOrShows([{ id: "3", collectionType: "tvshows" }]), "a show library")
    t_ok(not HomeBanner_anyFilmsOrShows([{ id: "1", collectionType: "music" }, { id: "4", collectionType: "photos" }]), "music and photos only")
    t_ok(not HomeBanner_anyFilmsOrShows([]), "no libraries")
    t_ok(not HomeBanner_anyFilmsOrShows(invalid), "no list")
    q = HomeBanner_queries("newest", "u", [], {})
    t_eq(q.count(), 2, "the whole server: one films and one shows query")
    t_ok(q[0].instr("ParentId") < 0, "no library filter")
end sub
