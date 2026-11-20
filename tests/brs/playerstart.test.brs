' Playback (source/Playback.bs): v1.2 faster player start helpers (SP-13b item JSON from Details, SP-13c intros
' route, SP-14 neighbouring episodes only)

sub test_playerInfoOf()
    src = { Id: "m1", Type: "Movie", People: [{ Name: "A" }], MediaSources: [{ Id: "s1" }], Chapters: [], Trickplay: { s1: {} } }
    out = Playback_playerInfoOf(src)
    t_ok(out <> invalid, "an item with streams")
    t_eq(out.Id, "m1", "keeps the id")
    t_ok(out.doesExist("MediaSources") and out.doesExist("Chapters") and out.doesExist("Trickplay"), "keeps streams, chapters, trickplay")
    t_ok(not out.doesExist("People"), "drops the cast")
    t_ok(src.doesExist("People"), "the page's own item is left alone")
    t_ok(Playback_playerInfoOf({ Id: "x", Type: "Series" }) = invalid, "no MediaSources: nothing to hand over")
    t_ok(Playback_playerInfoOf(invalid) = invalid, "no item")
end sub

sub test_adjacentEpisodesPath()
    p = Playback_adjacentEpisodesPath("u1", "s9", "e5")
    t_ok(p.instr("/Shows/s9/Episodes?UserId=u1&AdjacentTo=e5&") = 0, "series route with AdjacentTo")
    t_ok(p.instr("Overview") < 0, "no Overview")
    t_ok(p.instr("EnableUserData=true") > 0, "watched state for the panel")
    t_ok(p.instr("OfficialRating") > 0, "rating for the limit checks")
    f = Playback_seriesEpisodesPath("u1", "s9")
    t_ok(f.instr("/Shows/s9/Episodes?UserId=u1&Fields=") = 0, "whole list, same fields")
    t_ok(f.instr("AdjacentTo") < 0, "whole list has no AdjacentTo")
end sub

sub test_introsPath()
    t_eq(Playback_introsPath("u1", "m1", false), "/Users/u1/Items/m1/Intros", "old route")
    t_eq(Playback_introsPath("u1", "m1", true), "/Items/m1/Intros?userId=u1", "Jellyfin 10.9+ route")
end sub
