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
