' v1.7 LIVE: the live connection (M-5) and new-episode notices (M-3) helpers in source/Live.bs
sub t17_clearRegistry()
    sec = CreateObject("roRegistrySection", "Cove")
    for each k in sec.getKeyList()
        sec.delete(k)
    end for
end sub

sub test_liveSettings()
    t17_clearRegistry()
    t_ok(Live_liveOn(), "live connection on by default")
    sec = CreateObject("roRegistrySection", "Cove")
    sec.write("liveConn", "off")
    t_ok(not Live_liveOn(), "off when switched off")
    t_eq(Live_noticeMode(), "shows", "New Episodes: My Shows by default")
    sec.write("newEpisodes", "all")
    t_eq(Live_noticeMode(), "all", "Everything")
    sec.write("newEpisodes", "bogus")
    t_eq(Live_noticeMode(), "shows", "an unknown value is My Shows")
    t_eq(Live_noticeModeOptions().count(), 3, "three choices")
    t_ok(PrefScope_isPersonal("newEpisodes"), "New Episodes is a personal setting")
    t_ok(not PrefScope_isPersonal("liveConn"), "Live Connection is shared by the TV")
    t17_clearRegistry()
end sub

sub test_socketUrl()
    t_eq(Live_socketUrl("https://jf.example.com/", true, "TOKEN", "dev 1"), "wss://jf.example.com/socket?deviceId=dev%201", "Jellyfin wss, no token in the link")
    t_eq(Live_socketUrl("http://192.168.1.5:8096", true, "TOKEN", "d"), "ws://192.168.1.5:8096/socket?deviceId=d", "Jellyfin ws with a port")
    t_eq(Live_socketUrl("https://emby.example.com:8920/emby", false, "abc", "d"), "wss://emby.example.com:8920/emby/embywebsocket?api_key=abc&deviceId=d", "Emby with the path and api_key")
    t_eq(Live_socketUrl("http://h:8096", false, "", "d"), "", "Emby without a token: none")
    t_eq(Live_socketUrl("ftp://h", true, "t", "d"), "", "not http(s)")
    t_eq(Live_socketUrl("", true, "t", "d"), "", "no address")
end sub

sub test_parseFrame()
    f = Live_parseFrame("{""MessageType"":""ForceKeepAlive"",""Data"":60}")
    t_eq(f.type, "ForceKeepAlive", "type")
    t_eq(f.data, 60, "data")
    t_eq(Live_parseFrame("not json"), invalid, "not JSON")
    t_eq(Live_parseFrame("{""Data"":1}"), invalid, "no MessageType")
    t_eq(Live_parseFrame(invalid), invalid, "invalid")
    t_eq(Live_parseFrame("[1,2]"), invalid, "a list")
end sub

sub test_backoffAndKeepAlive()
    t_eq(Live_backoffSecs(0), 2, "first retry after 2 s")
    t_eq(Live_backoffSecs(1), 4, "then 4")
    t_eq(Live_backoffSecs(4), 32, "then 32")
    t_eq(Live_backoffSecs(5), 60, "at most 60")
    t_eq(Live_backoffSecs(40), 60, "still 60")
    t_eq(Live_backoffSecs(-3), 2, "negative attempt")
    t_ok(not Live_gaveUp(2), "two failures: keep trying")
    t_ok(Live_gaveUp(3), "three failures: polling")
    t_eq(Live_keepAliveMs(60), 30000, "half the server's timeout")
    t_eq(Live_keepAliveMs(4), 5000, "at least 5 s")
    t_eq(Live_keepAliveMs(invalid), 30000, "30 s without a number")
    t_eq(Live_keepAliveFrame(), "{""MessageType"":""KeepAlive""}", "KeepAlive text")
    t_eq(Live_sessionsFrame(true), "{""MessageType"":""SessionsStart"",""Data"":""0,1500""}", "SessionsStart")
    t_eq(Live_sessionsFrame(false), "{""MessageType"":""SessionsStop""}", "SessionsStop")
end sub

sub test_userDataAndLibrary()
    d = { UserId: "U1", UserDataList: [{ ItemId: "a" }, { ItemId: "b" }, { ItemId: "a" }, "x", {}] }
    t_eq(Live_userDataIds(d, "u1"), ["a", "b"], "ids once, user id in any case")
    t_eq(Live_userDataIds(d, "u2").count(), 0, "another user's change")
    t_eq(Live_userDataIds({ UserDataList: [{ ItemId: "c" }] }, "u1"), ["c"], "no user id in the message")
    t_eq(Live_userDataIds(invalid, "u1").count(), 0, "bad message")
    t_eq(Live_addedIds({ ItemsAdded: ["1", 2, ""], ItemsRemoved: ["9"] }), ["1", "2"], "added ids")
    t_eq(Live_addedIds({}).count(), 0, "nothing added")
    t_ok(Live_isRemoteCommand("Playstate"), "Playstate ignored")
    t_ok(Live_isRemoteCommand("GeneralCommand"), "GeneralCommand ignored")
    t_ok(Live_isRemoteCommand("Play"), "Play ignored")
    t_ok(not Live_isRemoteCommand("Sessions"), "Sessions used")
    t_eq(Live_countsText({ UserDataChanged: 1, Sessions: 12 }), "Sessions 12, UserDataChanged 1", "counts by name")
end sub

function t17_ep(id as string, created as string, series as string) as object
    return { Id: id, Type: "Episode", Name: "Pilot " + id, SeriesId: series, SeriesName: "Show " + series, ParentIndexNumber: 1, IndexNumber: 2, DateCreated: created, UserData: { Played: false, PlaybackPositionTicks: 0 } }
end function

sub test_freshItems_baseline()
    list = [t17_ep("e2", "2026-11-26T10:00:00.0000000Z", "s1"), t17_ep("e1", "2026-11-25T10:00:00.0000000Z", "s1")]
    d = Live_freshItems(invalid, list, "k", 1000)
    t_ok(d.baseline, "first look is a baseline")
    t_eq(d.fresh.count(), 0, "nothing announced on the first run")
    t_eq(d.entry.n, "2026-11-26T10:00:00", "mark = newest, to the second")
    t_eq(d.entry.s, ["e2"], "ids at the mark")
    t_eq(d.entry.c, 1000, "checked time")
    old = { k: "k", n: "2026-11-26T10:00:00", s: ["e2"], u: ["x"], c: 1000 }
    stale = Live_freshItems(old, list, "k", 1000 + 4 * 86400)
    t_ok(stale.baseline, "more than 3 days since the last look: a new baseline")
    t_eq(stale.entry.u, ["x"], "unread kept on a new baseline")
end sub

sub test_freshItems_new()
    old = { k: "k", n: "2026-11-26T10:00:00", s: ["e2"], u: [], c: 1000 }
    e3 = t17_ep("e3", "2026-11-26T12:00:00.1234567Z", "s1")
    e4 = t17_ep("e4", "2026-11-26T10:00:00Z", "s2")
    played = t17_ep("e5", "2026-11-26T13:00:00Z", "s1")
    played.UserData.Played = true
    tba = t17_ep("e6", "2026-11-26T13:00:00Z", "s1")
    tba.Name = "TBA"
    film = { Id: "m1", Type: "Movie", Name: "Dune", DateCreated: "2026-11-26T11:00:00Z" }
    season = { Id: "x1", Type: "Season", Name: "Season 2", DateCreated: "2026-11-26T14:00:00Z" }
    list = [season, played, tba, e3, film, t17_ep("e2", "2026-11-26T10:00:00Z", "s1"), e4, t17_ep("e0", "2026-11-20T10:00:00Z", "s1")]
    d = Live_freshItems(old, list, "k", 2000)
    t_ok(not d.baseline, "not a baseline")
    ids = []
    for each it in d.fresh
        ids.push(it.Id)
    end for
    t_eq(ids, ["e3", "m1", "e4"], "newer than the mark, or at it and not seen; not played, TBA, seasons, older")
    t_eq(d.entry.n, "2026-11-26T14:00:00", "the mark moves to the newest item")
    t_eq(d.entry.s, ["x1"], "the ids at the new mark")
    again = Live_freshItems(d.entry, list, "k", 3000)
    t_eq(again.fresh.count(), 0, "the same list again: nothing new (no repeat after a resume)")
end sub

sub test_wantedAndUnread()
    fresh = [t17_ep("e1", "x", "s1"), t17_ep("e2", "x", "s2"), { Id: "m1", Type: "Movie", Name: "Dune" }]
    followed = { s1: true }
    w = Live_wantedItems(fresh, "shows", followed)
    t_eq(w.count(), 1, "My Shows: only followed series")
    t_eq(w[0].Id, "e1", "the followed one")
    t_eq(Live_wantedItems(fresh, "all", {}).count(), 3, "Everything: episodes and films")
    t_eq(Live_wantedItems(fresh, "off", followed).count(), 0, "Off: none")
    t_eq(Live_seriesIdsOf(fresh), ["s1", "s2"], "series ids of episodes")
    t_eq(Live_mergeUnread(["a", "b"], ["c", "a"], 3), ["c", "a", "b"], "new first, each once")
    t_eq(Live_mergeUnread(invalid, ["a", "b", "c"], 2), ["a", "b"], "at most max")
    t_ok(Live_followsSeries({ IsFavorite: true }), "a favourite")
    t_ok(Live_followsSeries({ PlayedPercentage: 12.5 }), "started")
    t_ok(Live_followsSeries({ Played: true }), "watched")
    t_ok(not Live_followsSeries({ PlayedPercentage: 0, IsFavorite: false }), "not followed")
    t_ok(not Live_followsSeries(invalid), "no user data")
end sub

sub test_noticeTextAndStore()
    n = Live_noticeOf(t17_ep("e1", "x", "s1"))
    t_eq(n.title, "Show s1", "series name")
    t_eq(n.ep, "S1:E2", "season and episode")
    f = Live_noticeOf({ Id: "m1", Type: "Movie", Name: "Dune" })
    t_eq(f.ep, "", "a film has no episode")
    t_eq(Live_noticeToast([n]), "New: Show s1 · S1:E2  ·  See New in the menu", "one")
    t_eq(Live_noticeToast([n, f, f]), "New: Show s1 · S1:E2 and 2 more  ·  See New in the menu", "several")
    t_eq(Live_noticeToast([]), "", "none")
    t_eq(Live_dayTitle("Today"), "Added Today", "day row")
    t_eq(Live_dayTitle(""), "Added Earlier", "no date")
    t_eq(Live_noticeKey("0123456789", "abcdefghij"), "01234567:abcdefgh", "key")
    t_eq(Live_dateKeyOf("2026-11-26T10:00:00.0000000Z"), "2026-11-26T10:00:00", "date key")
    t_eq(Live_dateKeyOf("bad"), "", "bad date")
    store = [{ k: "a" }, { k: "b" }, { k: "c" }]
    out = Live_withEntry(store, { k: "d" }, 3)
    t_eq(out.count(), 3, "at most 3 profiles")
    t_eq(out[0].k, "b", "the oldest goes")
    t_eq(out[2].k, "d", "the newest last")
    out = Live_withEntry(out, { k: "b", u: ["1"] }, 3)
    t_eq(out[2].k, "b", "an update moves to the end")
    t_eq(out.count(), 3, "no duplicate")
    t_eq(Live_entryOf(out, "b").u, ["1"], "found")
    t_eq(Live_entryOf(invalid, "b"), invalid, "no store")
    t_ok(Live_isPlaceholderName("Episode 4"), "Episode 4")
    t_ok(Live_isPlaceholderName(" tba "), "TBA")
    t_ok(not Live_isPlaceholderName("The Episode"), "a real title")
end sub
