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

function v172_caps() as object
    return { hevc: true, hevc4k: true, hevc10: true, hdr10: true, hlg: true, dolbyVision: true, eac3: true, ac3: true, dts: false, fourK: true }
end function

function v172_subMethod(body as string, fmt as string) as string
    dp = ParseJson(body).DeviceProfile
    for each p in dp.SubtitleProfiles
        if p.Format = fmt then return p.Method
    end for
    return ""
end function

sub test_embyBurnIn()
    emby = { id: "e1", type: "emby", url: "http://emby.lan:8096", token: "TOKE", userId: "u2" }
    jelly = { id: "j1", type: "jellyfin", url: "http://jf.lan:8096", token: "TOKJ", userId: "u1" }
    burn = { audio: -1, sub: 3, burn: true, maxBitrate: 0, defaultAudio: -1, sourceId: "" }
    plain = { audio: -1, sub: 3, burn: false, maxBitrate: 0, defaultAudio: -1, sourceId: "" }
    t_eq(Playback_burnsSub(burn), true, "burn + a track: burn-in")
    t_eq(Playback_burnsSub(plain), false, "text shown by the Roku: no burn-in")
    t_eq(Playback_burnsSub({ burn: true, sub: -1 }), false, "no track: no burn-in")
    ' PlaybackInfo body: Emby gets an Encode-only subtitle profile, Jellyfin and normal starts keep External text
    t_eq(v172_subMethod(Playback_infoBody(v172_caps(), burn, false), "srt"), "Encode", "Emby burn: srt Encode only")
    t_eq(v172_subMethod(Playback_infoBody(v172_caps(), burn, false), "ass"), "Encode", "Emby burn: ass Encode only")
    t_eq(v172_subMethod(Playback_infoBody(v172_caps(), burn, true), "srt"), "External", "Jellyfin burn: unchanged")
    t_eq(v172_subMethod(Playback_infoBody(v172_caps(), plain, false), "srt"), "External", "no burn: unchanged")
    t_eq(v172_subMethod(Playback_infoBody(v172_caps(), plain, false), "pgs"), "Encode", "image subs stay Encode")
    ' PlaybackInfo query: no video copy for an Emby burn-in
    q = Playback_infoQuery(emby, false, burn)
    t_ok(q.instr("AllowVideoStreamCopy=false") > 0, "Emby burn: AllowVideoStreamCopy=false")
    t_ok(q.instr("EnableDirectStream=false") > 0, "Emby burn: no direct stream")
    t_ok(q.instr("SubtitleStreamIndex=3") > 0, "Emby burn: the track")
    t_ok(Playback_infoQuery(jelly, false, burn).instr("AllowVideoStreamCopy") < 0, "Jellyfin burn: query unchanged")
    t_ok(Playback_infoQuery(emby, false, plain).instr("AllowVideoStreamCopy") < 0, "no burn: query unchanged")
    t_eq(Playback_infoQuery(emby, true, burn).split("AllowVideoStreamCopy").count(), 2, "forced + burn: the parameter once")
    ' the stream URL
    info = { PlaySessionId: "ps1", MediaSources: [{ Id: "src1", Container: "mkv", SupportsDirectPlay: false, TranscodingUrl: "/videos/it1/master.m3u8?MediaSourceId=src1&AllowVideoStreamCopy=true", MediaStreams: [{ Type: "Video", Codec: "h264" }] }] }
    s = Playback_streamFrom(emby, "it1", info, false, burn)
    t_ok(s.url.instr("AllowVideoStreamCopy=false") > 0, "Emby burn URL: video copy off")
    t_ok(s.url.instr("AllowVideoStreamCopy=true") < 0, "Emby burn URL: the server's copy=true replaced")
    t_ok(s.url.instr("SubtitleMethod=Encode") > 0, "Emby burn URL: SubtitleMethod=Encode kept")
    s = Playback_streamFrom(jelly, "it1", info, false, burn)
    t_ok(s.url.instr("AllowVideoStreamCopy=false") < 0, "Jellyfin burn URL: unchanged")
    t_ok(s.url.instr("SubtitleMethod=Encode") > 0, "Jellyfin burn URL: SubtitleMethod=Encode")
end sub
