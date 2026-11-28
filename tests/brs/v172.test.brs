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

function v172_ep(aspect as dynamic) as object
    it = { Id: "e1", Type: "Episode", SeriesId: "s1", ImageTags: { Primary: "p" }, UserData: { Played: true } }
    if aspect <> invalid then it.PrimaryImageAspectRatio = aspect
    return it
end function

sub test_episodeWidePicture()
    srv = { url: "http://srv" }
    t_eq(Items_isPortrait(0.67), true, "0.67 is a poster")
    t_eq(Items_isPortrait(1.78), false, "16:9 is wide")
    t_eq(Items_isPortrait(invalid), false, "missing counts as wide")
    t_eq(Items_isPortrait(0), false, "0 counts as wide")
    it = v172_ep(1.78)
    it.ImageTags.Thumb = "t"
    t_ok(Items_landscape(srv, it, 480).instr("/Items/e1/Images/Primary") > 0, "wide Primary: the episode's still as before")
    it = v172_ep(invalid)
    t_ok(Items_landscape(srv, it, 480).instr("/Items/e1/Images/Primary") > 0, "no aspect: the still as before")
    it = v172_ep(0.67)
    it.ImageTags.Thumb = "t"
    it.BackdropImageTags = ["b"]
    t_ok(Items_landscape(srv, it, 480).instr("/Items/e1/Images/Thumb") > 0, "portrait: the episode's Thumb first")
    it = v172_ep(0.67)
    it.BackdropImageTags = ["b"]
    it.ParentThumbItemId = "season1"
    it.ParentThumbImageTag = "st"
    t_ok(Items_landscape(srv, it, 480).instr("/Items/e1/Images/Backdrop") > 0, "then its own backdrop")
    it = v172_ep(0.67)
    it.ParentThumbItemId = "season1"
    it.ParentThumbImageTag = "st"
    it.SeriesThumbImageTag = "sht"
    t_ok(Items_landscape(srv, it, 480).instr("/Items/season1/Images/Thumb") > 0, "then the season's Thumb")
    it = v172_ep(0.67)
    it.ParentThumbItemId = "s1"
    it.ParentThumbImageTag = "st"
    it.SeriesThumbImageTag = "sht"
    t_ok(Items_landscape(srv, it, 480).instr("/Items/s1/Images/Thumb?maxWidth=480&quality=85&tag=sht") > 0, "ParentThumb is the series: the series' Thumb")
    it = v172_ep(0.67)
    it.ParentBackdropItemId = "s1"
    it.ParentBackdropImageTags = ["pb"]
    t_ok(Items_landscape(srv, it, 480).instr("/Items/s1/Images/Backdrop") > 0, "then the series' backdrop")
    it = v172_ep(0.67)
    t_ok(Items_landscape(srv, it, 480).instr("/Items/e1/Images/Primary") > 0, "nothing wide: the portrait Primary last")
end sub
