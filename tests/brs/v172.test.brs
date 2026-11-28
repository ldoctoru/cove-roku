' v1.7.2 Mac catch-up fixes: card progress from the position (F-1), the resume ring rule (F-2),
' wide episode pictures (F-3), Emby burn-in (F-4), new-episode notice dedupe

function v172_item(posSecs as integer, runMins as integer, pct as dynamic, played as boolean) as object
    ud = { Played: played, PlaybackPositionTicks: posSecs * 10000000& }
    if pct <> invalid then ud.PlayedPercentage = pct
    it = { Type: "Episode", UserData: ud }
    if runMins > 0 then it.RunTimeTicks = runMins * 600000000&
    return it
end function

sub test_progressFromPosition()
    ' 21 min of a 42 min episode, the server's percentage stale at 10 %
    t_eq(Int(Items_progress(v172_item(1260, 42, 10, false)) * 100 + 0.5), 50, "position ÷ runtime, not the stale %")
    t_eq(Int(Items_progress(v172_item(1260, 42, invalid, false)) * 100 + 0.5), 50, "no percentage sent: still from the position")
    t_eq(Int(Items_progress(v172_item(600, 0, 25, false)) * 100 + 0.5), 25, "length unknown: the server's %")
    t_eq(Items_progress(v172_item(600, 0, invalid, false)), 0, "length and % unknown: 0")
    t_eq(Items_progress(v172_item(3000, 42, invalid, false)), 1, "past the end clamps to 1")
    t_eq(Items_progress({ Type: "Movie" }), 0, "no UserData: 0")
    t_eq(Items_progress(v172_item(0, 42, invalid, true)), 0, "watched, no position: 0")
end sub

sub test_showsResume()
    t_eq(Items_showsResume(v172_item(1260, 42, invalid, false)), true, "halfway: ring")
    t_eq(Items_showsResume(v172_item(1260, 42, invalid, true)), true, "watched but resumable: ring (Resume button rule)")
    t_eq(Items_showsResume(v172_item(20, 42, invalid, false)), false, "20 s in: no ring (Resume needs > 30 s)")
    t_eq(Items_showsResume(v172_item(0, 42, invalid, true)), false, "watched, no position: no ring")
    t_eq(Items_showsResume(v172_item(2520, 42, invalid, false)), false, "at the end: no ring")
    t_eq(Items_showsResume(v172_item(600, 0, 25, false)), true, "length unknown, server % 25: ring")
end sub

sub test_timeLeftMatchesDetails()
    it = v172_item(1260, 42, invalid, false)
    t_eq(Items_timeLeft(it), "21m left", "21 min left")
    t_eq(DetailsHead_remainingLabel(it), "21m remaining", "details page says the same minutes")
    it = v172_item(1290, 42, invalid, false)
    t_eq(Items_timeLeft(it), "21m left", "20.5 min left rounds up as on the details page")
    t_eq(DetailsHead_remainingLabel(it), "21m remaining", "details page rounds up")
    t_eq(Items_timeLeft(v172_item(60, 121, invalid, false)), "2h left", "on the hour")
    t_eq(Items_timeLeft(v172_item(60, 126, invalid, false)), "2h 5m left", "hours and minutes")
    t_eq(Items_timeLeft(v172_item(20, 42, invalid, false)), "", "not started (≤ 30 s): nothing")
    t_eq(Items_timeLeft(v172_item(600, 0, 25, false)), "", "no runtime: nothing")
end sub
