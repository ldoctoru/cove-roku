' QuickPlay (source/QuickPlay.bs): what the Play key on a card plays (v1.1 U-1)
sub test_playKind()
    t_eq(QuickPlay_playKind("Movie"), "play", "movie")
    t_eq(QuickPlay_playKind("Episode"), "play", "episode")
    t_eq(QuickPlay_playKind("Series"), "series", "series")
    t_eq(QuickPlay_playKind("Season"), "season", "season")
    t_eq(QuickPlay_playKind("BoxSet"), "box", "collection")
    t_eq(QuickPlay_playKind("Person"), "", "person")
    t_eq(QuickPlay_playKind("CollectionFolder"), "", "library")
    t_eq(QuickPlay_playKind(""), "", "empty")
end sub

sub test_cardActionNoNode()
    t_ok(QuickPlay_cardAction(invalid) = invalid, "no card")
    t_ok(QuickPlay_cardAction({ itemId: "1", itemType: "Movie" }) = invalid, "not a node")
end sub

sub test_startSecs()
    t_eq(QuickPlay_startSecs({ UserData: { PlaybackPositionTicks: 6000000000& } }), 600.0, "resume point")
    t_eq(QuickPlay_startSecs({ UserData: { PlaybackPositionTicks: 200000000 } }), 0.0, "under 30 s: the beginning")
    t_eq(QuickPlay_startSecs({ Name: "x" }), 0.0, "no user data")
    t_eq(QuickPlay_startSecs(invalid), 0.0, "nothing")
end sub

sub test_pickEpisode()
    sp = { Id: "s1", Type: "Episode", ParentIndexNumber: 0, IndexNumber: 1, UserData: { Played: false } }
    e1 = { Id: "e1", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 1, UserData: { Played: true } }
    e2 = { Id: "e2", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 2, UserData: { Played: false } }
    t_eq(QuickPlay_pickEpisode([sp, e1, e2]).Id, "e2", "first unwatched, specials skipped")
    e2w = { Id: "e2", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 2, UserData: { Played: true } }
    t_eq(QuickPlay_pickEpisode([sp, e1, e2w]).Id, "e1", "all watched: the first regular episode")
    t_eq(QuickPlay_pickEpisode([sp]).Id, "s1", "only specials")
    t_eq(QuickPlay_pickEpisode([{ Id: "n", Type: "Episode" }]).Id, "n", "no season number, no user data")
    t_ok(QuickPlay_pickEpisode([]) = invalid, "empty")
    t_ok(QuickPlay_pickEpisode(invalid) = invalid, "no list")
end sub

sub test_pickTitle()
    a = { Id: "a", Type: "Movie", UserData: { Played: true } }
    s = { Id: "s", Type: "Series", UserData: { Played: false } }
    b = { Id: "b", Type: "Movie", UserData: { Played: false } }
    t_eq(QuickPlay_pickTitle([a, s, b]).Id, "b", "first unwatched film, the series skipped")
    t_eq(QuickPlay_pickTitle([a, s]).Id, "a", "all watched: the first film")
    t_ok(QuickPlay_pickTitle([s]) = invalid, "nothing playable")
end sub

sub test_playerItem()
    ep = { Id: "e", Type: "Episode", Name: "Pilot", SeriesName: "Show", ParentIndexNumber: 1, IndexNumber: 1, UserData: { PlaybackPositionTicks: 0 } }
    p = QuickPlay_playerItem(ep)
    t_eq(p.title, "Show", "series name as title")
    t_eq(p.subtitle, "S1:E1  ·  Pilot", "episode line")
    t_eq(p.start, 0.0, "from the start")
    mv = QuickPlay_playerItem({ Id: "m", Type: "Movie", Name: "Dune", UserData: { PlaybackPositionTicks: 12000000000& } })
    t_eq(mv.title, "Dune", "movie")
    t_eq(mv.subtitle, "", "no subtitle")
    t_eq(mv.start, 1200.0, "resume")
end sub

sub test_isUnaired()
    now = "2026-11-18T12:00:00"
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: "Virtual", PremiereDate: "2026-11-20T00:00:00.0000000Z" }, now), "future episode, no file")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: "Virtual", PremiereDate: "2026-11-01T00:00:00.0000000Z" }, now), "aired episode")
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: "Virtual", PremiereDate: "2026-11-19" }, now), "date only, tomorrow")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: "Virtual", PremiereDate: "2026-11-18" }, now), "date only, today")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: "Virtual" }, now), "no date")
    t_ok(not QuickPlay_isUnaired({ Type: "Movie", LocationType: "Virtual", PremiereDate: "2027-01-01T00:00:00Z" }, now), "a movie is never unaired")
    t_ok(not QuickPlay_isUnaired(invalid, now), "nothing")
    t_eq(QuickPlay_nowStamp().len(), 19, "now stamp length")
end sub

' (BG-1) a file on disk plays whatever its date says; only the server's "no media" makes it unaired
sub test_isUnairedNeedsNoMedia()
    now = "2026-11-18T12:00:00"
    future = "2026-11-20T00:00:00.0000000Z"
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: "FileSystem", PremiereDate: future }, now), "on disk, future date: playable")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", PremiereDate: future }, now), "no LocationType: not by date alone")
    t_ok(QuickPlay_isUnaired({ Type: "Episode", IsMissing: true, PremiereDate: future }, now), "IsMissing")
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: "FileSystem", MediaSources: [], PremiereDate: future }, now), "no media sources")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", MediaSources: [{ Id: "m" }], PremiereDate: future }, now), "a media source")
    t_ok(QuickPlay_hasNoMedia({ LocationType: "Virtual" }), "virtual")
    t_ok(not QuickPlay_hasNoMedia({ LocationType: "FileSystem", IsMissing: false }), "file system")
    t_ok(not QuickPlay_hasNoMedia(invalid), "nothing")
end sub

' (BG-1 / BG-3) fractional seconds, zone offsets and a local midnight kept in UTC
sub test_isUnairedTimes()
    v = "Virtual"
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: v, PremiereDate: "2026-11-18T12:00:01.5000000Z" }, "2026-11-18T12:00:00"), "one second ahead, fractional")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: v, PremiereDate: "2026-11-18T13:00:00+02:00" }, "2026-11-18T12:00:00"), "+02:00 offset: 11:00 UTC, aired")
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: v, PremiereDate: "2026-11-18T08:00:00-05:00" }, "2026-11-18T12:00:00"), "-05:00 offset: 13:00 UTC, not yet")
    t_ok(not QuickPlay_isUnaired({ Type: "Episode", LocationType: v, PremiereDate: "2026-11-20T22:00:00.0000000Z" }, "2026-11-20T22:30:00"), "local midnight in UTC, passed")
    t_ok(QuickPlay_isUnaired({ Type: "Episode", LocationType: v, PremiereDate: "2026-11-20T22:00:00.0000000Z" }, "2026-11-20T21:30:00"), "local midnight in UTC, not yet")
end sub

sub test_pickEpisodeSkipsUnaired()
    e1 = { Id: "e1", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 1, UserData: { Played: true }, PremiereDate: "2026-10-01T00:00:00Z", LocationType: "FileSystem" }
    e2 = { Id: "e2", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 2, UserData: { Played: false }, PremiereDate: "2026-12-01T00:00:00Z", LocationType: "Virtual" }
    t_eq(QuickPlay_pickEpisode([e1, e2], "2026-11-18T12:00:00").Id, "e1", "only unaired regulars unwatched: the first aired")
    t_eq(QuickPlay_pickEpisode([e1, e2]).Id, "e2", "no time given: as before")
    e2f = { Id: "e2", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 2, UserData: { Played: false }, PremiereDate: "2026-12-01T00:00:00Z", LocationType: "FileSystem" }
    t_eq(QuickPlay_pickEpisode([e1, e2f], "2026-11-18T12:00:00").Id, "e2", "(BG-1) on disk with a future date: picked")
end sub

' (BG-7) a Specials season: the first unwatched special, not the first one
sub test_pickEpisodeSpecialsOnly()
    s1 = { Id: "s1", Type: "Episode", ParentIndexNumber: 0, IndexNumber: 1, UserData: { Played: true } }
    s2 = { Id: "s2", Type: "Episode", ParentIndexNumber: 0, IndexNumber: 2, UserData: { Played: false } }
    t_eq(QuickPlay_pickEpisode([s1, s2]).Id, "s2", "first unwatched special")
    s2w = { Id: "s2", Type: "Episode", ParentIndexNumber: 0, IndexNumber: 2, UserData: { Played: true } }
    t_eq(QuickPlay_pickEpisode([s1, s2w]).Id, "s1", "all watched: the first special")
    e1 = { Id: "e1", Type: "Episode", ParentIndexNumber: 1, IndexNumber: 1, UserData: { Played: true } }
    t_eq(QuickPlay_pickEpisode([s2, e1]).Id, "e1", "regulars all watched: the first regular, not the special")
end sub

' (BG-11) a trailer plays as a trailer
sub test_playerItemTrailer()
    p = QuickPlay_playerItem({ Id: "t", Type: "Trailer", Name: "Dune Trailer", UserData: { PlaybackPositionTicks: 12000000000& } })
    t_ok(p.trailer = true, "trailer flag")
    t_eq(p.start, 0.0, "from the start")
    t_eq(p.title, "Dune Trailer", "title")
    t_ok(QuickPlay_playerItem({ Id: "m", Type: "Movie", Name: "Dune" }).trailer = invalid, "a movie isn't a trailer")
end sub
