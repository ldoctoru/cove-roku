' DetailsHead (source/DetailsHead.bs): the v1.5 Emby-style details header's pure helpers

sub test_runtimeAndRemaining()
    t_eq(DetailsHead_runtimeLabel(103200000000&), "2h 52m", "2h 52m")
    t_eq(DetailsHead_runtimeLabel(25200000000&), "42m", "42m")
    t_eq(DetailsHead_runtimeLabel(72000000000&), "2h", "whole hours")
    t_eq(DetailsHead_runtimeLabel(invalid), "", "no runtime")
    film = { RunTimeTicks: 103200000000&, UserData: { PlaybackPositionTicks: 15000000000& } }
    ' 172 min - 25 min = 147 min
    t_eq(DetailsHead_remainingLabel(film), "2h 27m remaining", "remaining")
    t_ok(DetailsHead_isStarted(film), "started")
    p = DetailsHead_playedPart(film)
    t_ok(p > 0.14 and p < 0.15, "played part 25/172")
    fresh = { RunTimeTicks: 103200000000&, UserData: { PlaybackPositionTicks: 0 } }
    t_eq(DetailsHead_remainingLabel(fresh), "", "not started: nothing")
    t_ok(not DetailsHead_isStarted(fresh), "not started")
    t_ok(not DetailsHead_isStarted({ RunTimeTicks: 1 }), "no user data")
    ' 20 s from the end rounds up to a minute
    endish = { RunTimeTicks: 6000000000&, UserData: { PlaybackPositionTicks: 5800000000& } }
    t_eq(DetailsHead_remainingLabel(endish), "1m remaining", "under a minute left")
end sub

sub test_mediaLine()
    src = { MediaStreams: [{ Type: "Video", Codec: "h264", Width: 1920, Height: 1080 }, { Type: "Audio", Codec: "eac3" }] }
    t_eq(DetailsHead_videoLabel(src), "1080p H264", "1080p H264")
    uhd = { MediaStreams: [{ Type: "Video", Codec: "hevc", Width: 3840, Height: 2160, VideoRange: "HDR 10" }] }
    t_eq(DetailsHead_videoLabel(uhd), "4K HEVC HDR10", "4K HDR")
    scope = { MediaStreams: [{ Type: "Video", Codec: "h264", Width: 1920, Height: 800 }] }
    t_eq(DetailsHead_videoLabel(scope), "1080p H264", "scope 1920x800 is 1080p")
    t_eq(DetailsHead_videoLabel({ MediaStreams: [] }), "", "no video")
    t_eq(DetailsHead_videoLabel(invalid), "", "no source")
    t_eq(DetailsHead_resolutionOf(1280, 720), "720p", "720p")
    t_eq(DetailsHead_resolutionOf(720, 576), "576p", "576p")
    t_eq(DetailsHead_resolutionOf(640, 480), "480p", "480p")
    t_eq(DetailsHead_trackPill("Romanian (SRT)  ·  External", 30), "Romanian (SRT)", "external note dropped")
    t_eq(DetailsHead_trackPill("English PGS  (burned in)", 30), "English PGS", "burned-in note dropped")
    t_eq(DetailsHead_trackPill("English EAC3 5.1 (Default) Director's commentary track", 30), "English EAC3 5.1 (Default)...", "cut")
    t_ok(DetailsHead_hasMediaLine("Movie"), "film")
    t_ok(DetailsHead_hasMediaLine("Episode"), "episode")
    t_ok(not DetailsHead_hasMediaLine("Series"), "series")
    t_ok(not DetailsHead_hasMediaLine("BoxSet"), "collection")
end sub

sub test_infoSegments()
    film = { Type: "Movie", CommunityRating: 8.36, CriticRating: 96, ProductionYear: 2026, RunTimeTicks: 103200000000&, OfficialRating: "R", Genres: ["Adventure", "Drama", "War", "History"] }
    s = DetailsHead_infoSegments(film, "12:53 AM", "")
    t_eq(s.count(), 7, "seven pieces")
    t_eq(s[0].kind, "star", "star first")
    t_eq(s[0].text, "8.4", "score rounded")
    t_eq(s[1].kind, "critic", "tomato")
    t_eq(s[1].text, "96%", "critic %")
    t_ok(s[1].fresh, "fresh")
    t_eq(s[2].text, "2026", "year")
    t_eq(s[3].text, "2h 52m", "runtime")
    t_eq(s[4].kind, "rating", "rating box")
    t_eq(s[5].text, "Adventure, Drama, War", "three genres")
    t_eq(s[6].text, "Ends at 12:53 AM", "ends at")
    ep = { Type: "Episode", ProductionYear: 2026, RunTimeTicks: 25200000000&, Genres: ["Drama"], CriticRating: 40 }
    e = DetailsHead_infoSegments(ep, "11:14 PM", "Nov 22, 2026")
    t_eq(e[0].kind, "critic", "episode critic")
    t_ok(not e[0].fresh, "rotten")
    t_eq(e[1].text, "Nov 22, 2026", "air date instead of the year")
    t_eq(e[2].text, "42m", "episode runtime")
    t_eq(e[3].text, "Ends at 11:14 PM", "no genres on an episode")
    show = { Type: "Series", ProductionYear: 2019, Status: "Continuing", RunTimeTicks: 25200000000&, Genres: ["Comedy"] }
    sr = DetailsHead_infoSegments(show, "9:00 PM", "")
    t_eq(sr.count(), 2, "series: years and genres only")
    t_eq(sr[0].text, "2019 – Present", "running series")
    t_eq(DetailsHead_infoSegments({ Type: "Movie" }, "", "").count(), 0, "empty item")
end sub

sub test_textLines()
    ep = { Type: "Episode", Name: "Under the Influence", ParentIndexNumber: 2, IndexNumber: 7 }
    t_eq(DetailsHead_episodeLine(ep), "S2:E7 - Under the Influence", "episode line")
    t_eq(DetailsHead_episodeLine({ Name: "Pilot" }), "Pilot", "no numbers")
    t_eq(DetailsHead_episodeLine({ IndexNumber: 3 }), "E3", "number only")
    film = { Type: "Movie", People: [{ Name: "A", Type: "Actor" }, { Name: "Christopher Nolan", Type: "Director" }] }
    t_eq(DetailsHead_creditLine(film), "Director: Christopher Nolan", "director")
    two = { Type: "Movie", People: [{ Name: "A", Type: "Director" }, { Name: "B", Type: "Director" }] }
    t_eq(DetailsHead_creditLine(two), "Directors: A, B", "two directors")
    show = { Type: "Series", People: [{ Name: "D", Type: "Director" }] }
    t_eq(DetailsHead_creditLine(show), "", "series without a creator")
    show2 = { Type: "Series", People: [{ Name: "Vince Gilligan", Type: "Creator" }] }
    t_eq(DetailsHead_creditLine(show2), "Created by: Vince Gilligan", "creator")
    t_eq(DetailsHead_taglineOf({ Taglines: ["Defy the gods."] }), "Defy the gods.", "tagline")
    t_eq(DetailsHead_taglineOf({ Taglines: [] }), "", "no tagline")
    t_eq(DetailsHead_taglineOf({}), "", "missing")
end sub

sub test_headerButtons()
    t_eq(Util_join(DetailsHead_headerButtonIds("Movie", false, true, 0), ","), "play,watched,fav,more", "film, not started")
    t_eq(Util_join(DetailsHead_headerButtonIds("Movie", true, true, 1), ","), "play,restart,trailer,watched,fav,more", "film started, trailer")
    t_eq(Util_join(DetailsHead_headerButtonIds("Episode", true, true, 0), ","), "play,restart,watched,fav,more", "episode started")
    t_eq(Util_join(DetailsHead_headerButtonIds("Series", false, true, 0), ","), "play,playall,shuffle,watched,fav,more", "series")
    t_eq(Util_join(DetailsHead_headerButtonIds("Series", false, false, 0), ","), "watched,fav,more", "series before its episodes answer")
    t_eq(Util_join(DetailsHead_headerButtonIds("BoxSet", false, true, 2), ","), "play,watched,fav,more", "collection: no trailer")
end sub

sub test_moreEntries()
    film = DetailsHead_moreEntries({ itemType: "Movie", isFav: false, played: false, isAdmin: false, collections: 0, versions: 1 })
    ids = []
    for each e in film
        ids.push(e.id)
    end for
    t_eq(Util_join(ids, ","), "addcoll,addlist,fav,watched,info,quality", "film, not an admin")
    t_eq(film[2].label, "Add to Favorites", "add favourite")
    t_eq(film[3].label, "Mark Played", "mark played")
    t_ok(film[4].divider, "a line above Playback Info")
    adm = DetailsHead_moreEntries({ itemType: "Movie", isFav: true, played: true, isAdmin: true, collections: 2, versions: 2 })
    ids = []
    for each e in adm
        ids.push(e.id)
    end for
    t_eq(Util_join(ids, ","), "addcoll,addlist,fav,watched,info,version,quality,gocoll,refresh", "admin, in two collections, two files")
    t_eq(adm[2].label, "Remove from Favorites", "remove favourite")
    t_eq(adm[3].label, "Mark Unplayed", "mark unplayed")
    t_eq(adm[7].label, "Go to Collections", "several collections")
    ep = DetailsHead_moreEntries({ itemType: "Episode", hasSeries: true, hasSeason: true, seasonLabel: "Season 2" })
    ids = []
    for each e in ep
        ids.push(e.id + "=" + e.label)
    end for
    t_eq(ids[ids.count() - 2], "series=Go to Series", "episode: Go to Series")
    t_eq(ids[ids.count() - 1], "season=Go to Season 2", "episode: Go to Season 2")
    show = DetailsHead_moreEntries({ itemType: "Series" })
    ids = []
    for each e in show
        ids.push(e.id)
    end for
    t_eq(Util_join(ids, ","), "addcoll,addlist,fav,watched", "series: no media entries")
    coll = DetailsHead_moreEntries({ itemType: "BoxSet" })
    t_eq(coll[0].id, "addlist", "collection: no Add to Collection")
    for each e in adm
        t_ok(e.id <> "delete" and e.id <> "download" and e.id <> "edit", "never delete / download / edit")
    end for
end sub

sub test_paths()
    t_eq(DetailsHead_urlEncode("Films & Co"), "Films%20%26%20Co", "space and ampersand")
    t_eq(DetailsHead_urlEncode("a-b_c.d~e"), "a-b_c.d~e", "unreserved kept")
    t_eq(DetailsHead_addToCollectionPath("c1", "i9"), "/Collections/c1/Items?Ids=i9", "add to collection")
    t_eq(DetailsHead_newCollectionPath("My Films", "i9"), "/Collections?Name=My%20Films&Ids=i9", "new collection")
    t_eq(DetailsHead_addToPlaylistPath("p1", "i9", "u1"), "/Playlists/p1/Items?Ids=i9&UserId=u1", "add to playlist")
    t_eq(DetailsHead_newPlaylistPath("Late", "i9", "u1"), "/Playlists?Name=Late&Ids=i9&UserId=u1&MediaType=Video", "new playlist")
    t_ok(DetailsHead_refreshPath("i9").instr("/Items/i9/Refresh?Recursive=true&MetadataRefreshMode=Default&ImageRefreshMode=Default") = 0, "refresh")
    t_ok(DetailsHead_isAdminUser({ Policy: { IsAdministrator: true } }), "admin")
    t_ok(not DetailsHead_isAdminUser({ Policy: { IsAdministrator: false } }), "not admin")
    t_ok(not DetailsHead_isAdminUser({}), "no policy")
    t_ok(not DetailsHead_isAdminUser(invalid), "no answer")
end sub
