' v1.7.1 LIVE: reconnect / liveness, user-data filtering, the refresh plan and the newMedia writes (source/Live.bs)

sub test_v171RetrySecs()
    t_eq(Live_retrySecs(0), 2, "first retry after 2 s")
    t_eq(Live_retrySecs(4), 32, "then 32")
    t_eq(Live_retrySecs(5), 60, "then every minute")
    t_eq(Live_retrySecs(9), 60, "still a minute")
    t_eq(Live_retrySecs(10), 300, "then every 5 minutes, never off")
    t_eq(Live_retrySecs(500), 300, "and so on")
end sub

sub test_v171AfterClose()
    r = Live_afterClose(-1, 2, 1)
    t_eq(r.failures, 2, "never opened: one more failure")
    t_eq(r.attempt, 2, "the backoff goes on")
    r = Live_afterClose(3000, 4, 0)
    t_eq(r.failures, 1, "open 3 s then closed: a failure (LV-9)")
    t_eq(r.attempt, 4, "no fresh start")
    r = Live_afterClose(20000, 4, 2)
    t_eq(r.failures, 2, "open 20 s: failures as they were")
    t_eq(r.attempt, 4, "attempt as it was")
    r = Live_afterClose(30000, 7, 3)
    t_eq(r.failures, 0, "open 30 s: a fresh start")
    t_eq(r.attempt, 0, "backoff from 2 s again")
end sub

sub test_v171IsSilent()
    t_ok(not Live_isSilent(60000, 30000, true), "a minute while it answers: fine")
    t_ok(Live_isSilent(66000, 30000, true), "more than twice the keep-alive + 5 s: gone")
    t_ok(not Live_isSilent(300000, 30000, false), "a server that never answers: 5 minutes is fine")
    t_ok(Live_isSilent(600001, 30000, false), "10 silent minutes: gone")
end sub

sub test_v171UserDataKey()
    t_eq(Live_userDataKey({ Played: true, IsFavorite: false }), "p1f0b0", "watched")
    t_eq(Live_userDataKey({ Played: false, IsFavorite: true, PlayedPercentage: 42.5 }), "p0f1b1", "favourite, half way")
    t_eq(Live_userDataKey({ PlayedPercentage: 3 }), "p0f0b0", "under 5 %: not started")
    t_eq(Live_userDataKey({ PlayedPercentage: 95 }), "p0f0b2", "past 90 %")
    t_eq(Live_userDataKey({ PlaybackPositionTicks: 100000000 }), "p0f0b1", "a position without a percentage")
    t_eq(Live_userDataKey(invalid), "", "not an entry")
end sub

sub test_v171UserDataChanges()
    seen = {}
    d = { UserId: "U1", UserDataList: [{ ItemId: "a", PlayedPercentage: 20 }, { ItemId: "b", Played: true }] }
    t_eq(Live_userDataChanges(d, "u1", seen), ["a", "b"], "first sight: both count")
    d = { UserId: "U1", UserDataList: [{ ItemId: "a", PlayedPercentage: 40 }] }
    t_eq(Live_userDataChanges(d, "u1", seen), [], "progress in the same step: ignored (LV-8)")
    d = { UserId: "U1", UserDataList: [{ ItemId: "a", PlayedPercentage: 92 }] }
    t_eq(Live_userDataChanges(d, "u1", seen), ["a"], "crossed 90 %: counts")
    d = { UserId: "U1", UserDataList: [{ ItemId: "b", Played: true, IsFavorite: true }] }
    t_eq(Live_userDataChanges(d, "u1", seen), ["b"], "favourite added: counts")
    t_eq(Live_userDataChanges({ UserId: "other", UserDataList: [{ ItemId: "z" }] }, "u1", seen), [], "another user")
    t_eq(Live_userDataChanges("bad", "u1", seen), [], "a bad message")
    d = { UserDataList: [{ ItemId: "c" }, { ItemId: "c" }] }
    t_eq(Live_userDataChanges(d, "u1", seen), ["c"], "each id once")
end sub

sub test_v171DebounceFire()
    t_ok(not Live_debounceFire(3), "3 s after the first: keep waiting")
    t_ok(Live_debounceFire(10), "10 s after the first: refresh now")
end sub

sub test_v171UserDataPlan()
    t_eq(Live_userDataPlan("player", -1, -1, -1, false).act, "none", "the player reports itself")
    t_eq(Live_userDataPlan("details", 4, 100, -1, false).act, "none", "Cove's own mark coming back (LV-7)")
    t_eq(Live_userDataPlan("details", 20, -1, -1, false).act, "details", "another device: details refresh")
    t_eq(Live_userDataPlan("details", 20, 2, -1, false).act, "recent", "details refreshed 2 s ago")
    t_eq(Live_userDataPlan("home", -1, 5, -1, false).act, "recent", "Home loaded 5 s ago")
    t_eq(Live_userDataPlan("home", -1, 100, -1, false).act, "home", "Home reloads")
    p = Live_userDataPlan("home", -1, 100, 20, false)
    t_eq(p.act, "later", "at most one live Home reload a minute (CR-4)")
    t_eq(p.wait, 40, "the rest of the minute")
    t_eq(Live_userDataPlan("library", -1, -1, -1, true).act, "defer", "sidebar or picker open: when the focus returns (CR-3)")
    t_eq(Live_userDataPlan("favorites", -1, -1, -1, false).act, "page", "nothing open: reload now")
    p = Live_userDataPlan("seeall", -1, 10, -1, false)
    t_eq(p.act, "later", "a page reloaded 10 s ago waits")
    t_eq(p.wait, 20, "until 30 s have passed")
    t_eq(Live_userDataPlan("search", -1, -1, -1, false).act, "flag", "other pages: stale only")
end sub

sub test_v171EntryChanged()
    old = { k: "k", n: "2026-11-26T10:00:00", s: ["a"], u: ["x"], c: 1000 }
    t_ok(not Live_entryChanged(old, { k: "k", n: "2026-11-26T10:00:00", s: ["a"], u: ["x"], c: 1600 }), "nothing new: no write (LV-16)")
    t_ok(Live_entryChanged(old, { k: "k", n: "2026-11-26T10:00:00", s: ["a"], u: ["x"], c: 4700 }), "an hour later: the time is saved")
    t_ok(Live_entryChanged(old, { k: "k", n: "2026-11-26T10:00:00", s: ["a"], u: [], c: 1000 }), "read marks")
    t_ok(Live_entryChanged(old, { k: "k", n: "2026-11-26T11:00:00", s: ["b"], u: ["x"], c: 1000 }), "a new mark")
    t_ok(Live_entryChanged(invalid, { k: "k", n: "", s: [], u: [], c: 1 }), "no entry yet")
    t_eq(Live_listOrEmpty(invalid), [], "not a list")
end sub

sub test_v171ShortMarkIds()
    latest = [{ Id: "0123456789abcdef", Type: "Episode", Name: "Pilot", SeriesId: "s", DateCreated: "2026-11-26T10:00:00.000Z", UserData: {} }]
    d = Live_freshItems(invalid, latest, "k", 5000)
    t_eq(d.entry.s, ["01234567"], "ids at the mark kept as 8 characters (LV-10)")
    later = Live_freshItems(d.entry, latest, "k", 5100)
    t_eq(later.fresh.count(), 0, "the same title isn't new again")
    old = { k: "k", n: "2026-11-26T10:00:00", s: ["0123456789abcdef"], u: [], c: 5000 }
    t_eq(Live_freshItems(old, latest, "k", 5100).fresh.count(), 0, "a long id stored by v1.7.0 still matches")
end sub

sub test_v171SixProfiles()
    store = []
    for i = 1 to 7
        store = Live_withEntry(store, { k: "p" + i.toStr() }, 6)
    end for
    t_eq(store.count(), 6, "six profiles kept")
    t_eq(store[0].k, "p2", "the oldest went")
end sub

sub test_v171SessionKeys()
    a = [{ UserName: "Ann", DeviceName: "TV", Client: "Cove", NowPlayingItem: { Id: "i1" } }, "bad"]
    t_eq(Live_sessionKeysOf(a), "i1|Ann|TV|Cove", "item, user, device, client")
    t_eq(Live_sessionKeysOf([]), "", "none")
end sub
