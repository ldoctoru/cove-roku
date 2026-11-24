' MissingArt (source/MissingArt.bs): v1.5.1 admin Items without Poster / Backdrop, the pure helpers

sub test_missingFilter()
    t_ok(MissingArt_isMissing({ Id: "1", ImageTags: {} }, "poster"), "no Primary tag")
    t_ok(MissingArt_isMissing({ Id: "1" }, "poster"), "no ImageTags")
    t_ok(MissingArt_isMissing({ Id: "1", ImageTags: { Primary: "" } }, "poster"), "empty Primary tag")
    t_ok(not MissingArt_isMissing({ Id: "1", ImageTags: { Primary: "abc" } }, "poster"), "has a poster")
    t_ok(MissingArt_isMissing({ Id: "1", ImageTags: { Primary: "abc" }, BackdropImageTags: [] }, "backdrop"), "empty backdrop list")
    t_ok(MissingArt_isMissing({ Id: "1" }, "backdrop"), "no backdrop list")
    t_ok(not MissingArt_isMissing({ Id: "1", BackdropImageTags: ["x"] }, "backdrop"), "has a backdrop")
    t_ok(MissingArt_isMissing(invalid, "poster"), "invalid counts as missing")
    t_eq(MissingArt_kindOf("Backdrop"), "backdrop", "kind backdrop")
    t_eq(MissingArt_kindOf("anything"), "poster", "kind defaults to poster")
end sub

sub test_rowsOfPage()
    json = { TotalRecordCount: 4, Items: [{ Id: "a", Name: "Dune", Type: "Movie", ProductionYear: 2021, Path: "/m/Dune.mkv", ImageTags: {} }, { Id: "b", Name: "Alien", ImageTags: { Primary: "t" } }, { Id: "c", Type: "Series", ImageTags: {} }, "junk"] }
    pg = MissingArt_rowsOfPage(json, "poster")
    t_eq(pg.pageCount, 4, "page count = items sent")
    t_eq(pg.total, 4, "total")
    t_eq(pg.rows.count(), 2, "two without a poster")
    t_eq(pg.rows[0].id, "a", "first id")
    t_eq(pg.rows[0].year, 2021, "year")
    t_eq(pg.rows[0].path, "/m/Dune.mkv", "path")
    t_eq(pg.rows[1].name, "Untitled", "no name")
    t_eq(MissingArt_rowLabel(pg.rows[0]), "Dune (2021)", "label with year")
    t_eq(MissingArt_rowLabel(pg.rows[1]), "Untitled", "label without year")
    none = MissingArt_rowsOfPage({ Items: [] }, "backdrop")
    t_eq(none.total, -1, "no total from the server")
    t_eq(MissingArt_rowsOfPage(invalid, "poster").rows.count(), 0, "invalid page")
    t_ok(MissingArt_scanContinues(300, 300, 1250), "full page, more to come")
    t_ok(not MissingArt_scanContinues(120, 1250, 1250), "short page ends")
    t_ok(not MissingArt_scanContinues(300, 600, 600), "total reached")
    t_ok(MissingArt_scanContinues(300, 300, -1), "no total: next page")
end sub

sub test_queries()
    t_eq(MissingArt_scanPath("u1", "lib9", 300, 300), "/Users/u1/Items?ParentId=lib9&Recursive=true&IncludeItemTypes=Movie,Series,BoxSet&Fields=ProductionYear,Path&EnableImageTypes=Primary,Backdrop&EnableUserData=false&SortBy=SortName&SortOrder=Ascending&StartIndex=300&Limit=300", "scan page")
    t_eq(MissingArt_refreshMissingPath("x1"), "/Items/x1/Refresh?Recursive=true&MetadataRefreshMode=FullRefresh&ImageRefreshMode=FullRefresh&ReplaceAllMetadata=false&ReplaceAllImages=false", "refresh missing")
    t_eq(MissingArt_recordPath("u1", "x1"), "/Users/u1/Items/x1?Fields=DateLastRefreshed,Path,ProductionYear", "record")
    t_eq(MissingArt_pageSize(), 300, "pages of 300")
end sub

sub test_statusTexts()
    t_eq(MissingArt_statusText("poster", true, 0, -1, 0), "Checking 0 items...", "before the first page")
    t_eq(MissingArt_statusText("poster", true, 300, 1250, 4), "Checking 300 of 1250 items...", "scanning")
    t_eq(MissingArt_statusText("poster", false, 1250, 1250, 0), "Every item has a poster.", "none missing")
    t_eq(MissingArt_statusText("backdrop", false, 10, 10, 0), "Every item has a backdrop.", "none missing backdrop")
    t_eq(MissingArt_statusText("poster", false, 10, 10, 1), "1 item", "one")
    t_eq(MissingArt_statusText("poster", false, 10, 10, 12), "12 items", "many")
    t_eq(MissingArt_refreshingText(3, 12), "Refreshing 3 of 12...", "refreshing")
    t_eq(MissingArt_summaryText(5, 12, "poster"), "5 of 12 now have a poster", "summary")
    t_eq(MissingArt_summaryText(0, 2, "backdrop"), "0 of 2 now have a backdrop", "summary backdrop")
    t_eq(MissingArt_titleOf("poster"), "Items without Poster", "title")
    t_eq(MissingArt_titleOf("backdrop"), "Items without Backdrop", "title backdrop")
end sub

sub test_snapshotAndPill()
    a = { DateLastRefreshed: "2026-01-01", ImageTags: { Thumb: "t", Primary: "p" }, BackdropImageTags: ["b1"] }
    t_eq(MissingArt_snapshotOf(a), "2026-01-01|Primary=p;Thumb=t;Backdrop=b1,", "snapshot sorted")
    b = { DateLastRefreshed: "2026-01-01", ImageTags: { Thumb: "t" } }
    t_ok(MissingArt_snapshotOf(a) <> MissingArt_snapshotOf(b), "a new poster changes the snapshot")
    t_eq(MissingArt_snapshotOf(invalid), "", "invalid")
    t_ok(MissingArt_showsAdminPill(true, "movies"), "admin, movies")
    t_ok(MissingArt_showsAdminPill(true, ""), "admin, unknown kind")
    t_ok(MissingArt_showsAdminPill(true, invalid), "admin, no kind")
    t_ok(not MissingArt_showsAdminPill(true, "music"), "music library")
    t_ok(not MissingArt_showsAdminPill(false, "movies"), "not an admin")
    t_eq(MissingArt_adminKey("http://s", "u"), "http://s|u", "admin key")
end sub
