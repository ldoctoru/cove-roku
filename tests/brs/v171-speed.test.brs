' v1.7.1 SPEED: film start diagnostics (SP6-1) and Start MKV Files as a Stream (SP6-3), source/Playback.bs

function sp_src(container as string, bitrate as dynamic) as object
    return {
        Id: "src1", Container: container, Bitrate: bitrate, SupportsDirectPlay: true,
        TranscodingUrl: "/videos/it1/master.m3u8?MediaSourceId=src1&VideoCodec=hevc",
        MediaStreams: [
            { Type: "Video", Codec: "HEVC", Width: 3840, Height: 2160, VideoRange: "HDR 10", RealFrameRate: 23.976 },
            { Type: "Audio", Codec: "TrueHD", Channels: 8, Index: 1 },
            { Type: "Audio", Codec: "EAC3", Channels: 6, Index: 2, IsDefault: true },
            { Type: "Audio", Codec: "AC3", Channels: 2, Index: 3 },
            { Type: "Subtitle", Codec: "srt", Index: 4 },
            { Type: "Subtitle", Codec: "pgssub", Index: 5 }
        ]
    }
end function

function sp_opts() as object
    return { audio: -1, sub: -1, burn: false, maxBitrate: 0, defaultAudio: -1, sourceId: "" }
end function

function sp_emby() as object
    return { id: "e1", type: "emby", url: "http://emby.lan:8096", token: "TOKE", userId: "u2" }
end function

sub test_noDirectOf()
    o = sp_opts()
    t_eq(Playback_noDirectOf(false, o), false, "nothing asks for the server: direct")
    t_eq(Playback_noDirectOf(true, o), true, "a forced conversion")
    o.remux = true
    t_eq(Playback_noDirectOf(false, o), true, "a large MKV started as a stream")
    o = sp_opts()
    o.audio = 3
    o.defaultAudio = 2
    t_eq(Playback_noDirectOf(false, o), true, "another audio track than the default")
    o.audio = 2
    t_eq(Playback_noDirectOf(false, o), false, "the default audio track")
    o = sp_opts()
    o.burn = true
    o.sub = 5
    t_eq(Playback_noDirectOf(false, o), true, "a burned-in subtitle")
end sub

sub test_sourceOf()
    info = { MediaSources: [{ Id: "a" }, { Id: "b" }] }
    t_eq(Playback_sourceOf(info, "b").Id, "b", "the chosen version")
    t_eq(Playback_sourceOf(info, "").Id, "a", "none chosen: the first")
    t_eq(Playback_sourceOf(info, "zz").Id, "a", "an unknown id: the first")
    t_eq(Playback_sourceOf({ MediaSources: [] }, ""), invalid, "no sources")
    t_eq(Playback_sourceOf(invalid, ""), invalid, "no info")
end sub

sub test_sourceBitrate()
    t_eq(Playback_sourceBitrate({ Bitrate: 62000000 }), 62000000, "the source's Bitrate")
    ' 45 GB over 2 h 28 min: about 40 Mbit/s
    t_eq(Int(Playback_sourceBitrate({ Size: 45000000000&, RunTimeTicks: 88800000000& }) / 1000000), 40, "from size and run time")
    t_eq(Playback_sourceBitrate({}), 0, "unknown")
    t_eq(Playback_sourceBitrate(invalid), 0, "no source")
end sub

sub test_wantsMkvStream()
    t_eq(Playback_wantsMkvStream(sp_src("mkv", 62000000), true), true, "a 62 Mbit/s MKV with the setting on")
    t_eq(Playback_wantsMkvStream(sp_src("mkv", 62000000), false), false, "the setting off (default): direct play as before")
    t_eq(Playback_wantsMkvStream(sp_src("mkv", 7000000), true), true, "a 7 Mbit/s MKV too (every MKV since v1.7.1)")
    t_eq(Playback_wantsMkvStream(sp_src("mkv", 7000000), false), false, "a 7 Mbit/s MKV, setting off: direct")
    t_eq(Playback_wantsMkvStream(sp_src("matroska,webm", 62000000), true), true, "matroska counts as MKV")
    t_eq(Playback_wantsMkvStream(sp_src("mp4", 62000000), true), false, "an MP4 stays direct")
    t_eq(Playback_wantsMkvStream(sp_src("mkv", invalid), true), true, "an MKV of unknown bitrate too")
    t_eq(Playback_wantsMkvStream(invalid, true), false, "no source")
end sub

sub test_mkvStreamSetting()
    sec = CreateObject("roRegistrySection", "Cove")
    sec.delete("mkvStream")
    t_eq(Playback_mkvStreamOn(), false, "default Off")
    Prefs_setFlag("mkvStream", true)
    t_eq(Playback_mkvStreamOn(), true, "On after the switch")
    Prefs_setFlag("mkvStream", false)
    t_eq(Playback_mkvStreamOn(), false, "Off again")
    t_eq(PrefScope_isPersonal("mkvStream"), false, "one key for the Roku, not per profile")
end sub

sub test_remuxQueryAndStream()
    o = sp_opts()
    o.remux = true
    q = Playback_infoQuery(sp_emby(), false, o)
    t_ok(q.instr("EnableDirectPlay=false") > 0, "remux: the server is asked not to direct play")
    t_ok(q.instr("AllowVideoStreamCopy=false") < 0, "remux: the video is still copied")
    t_ok(Playback_infoQuery(sp_emby(), false, sp_opts()).instr("EnableDirectPlay") < 0, "no remux: unchanged query")
    info = { PlaySessionId: "ps1", MediaSources: [sp_src("mkv", 62000000)] }
    s = Playback_streamFrom(sp_emby(), "it1", info, false, o)
    t_eq(s.streamFormat, "hls", "remux: the server's HLS stream")
    t_ok(s.url.instr("MaxWidth") < 0, "remux of HEVC: no 1080p cap")
    s = Playback_streamFrom(sp_emby(), "it1", info, false, sp_opts())
    t_eq(s.method, "DirectPlay", "no remux: the file itself")
    t_eq(s.streamFormat, "mkv", "no remux: mkv")
end sub

sub test_startDec()
    t_eq(Playback_startDec(23.976), "23.976", "three decimals")
    t_eq(Playback_startDec(24), "24", "a whole number")
    t_eq(Playback_startDec(0.5), "0.5", "trailing zeros dropped")
    t_eq(Playback_startDec(7.8999), "7.9", "rounded")
    t_eq(Playback_startDec("1.25"), "1.25", "from text")
    t_eq(Playback_startDec(invalid), "?", "missing")
    t_eq(Playback_startMbit(62400000), "62", "Mbit/s")
    t_eq(Playback_startMbit(0), "?", "unknown bitrate")
end sub

sub test_startFacts()
    f = Playback_startFacts(sp_src("mkv", 62000000), "mkv", "DirectPlay", -1, 0)
    t_eq(f, "mkv DirectPlay hevc 3840x2160 HDR 10 23.976 fps 62 Mbit/s audio eac3 6ch tracks a3 s2 resume 0 s", "the 4K film, default audio")
    f = Playback_startFacts(sp_src("mkv", 62000000), "hls", "DirectStream", 1, 3600.4)
    t_eq(f, "mkv DirectStream (hls) hevc 3840x2160 HDR 10 23.976 fps 62 Mbit/s audio truehd 8ch tracks a3 s2 resume 3600 s", "remuxed, track 1, resumed")
    jf = sp_src("mkv", 62000000)
    jf.MediaStreams[0].VideoRangeType = "HDR10"
    t_ok(Playback_startFacts(jf, "mkv", "DirectPlay", -1, 0).instr(" HDR10 ") > 0, "Jellyfin VideoRangeType wins")
    t_eq(Playback_startFacts(invalid, "mkv", "DirectPlay", -1, 12), "? DirectPlay (no source facts) resume 12 s", "no source facts")
end sub

sub test_startNet()
    t_eq(Playback_startNet({ type: "WiFiConnection", protocol: "802.11ac", signal: -52, expectedThroughput: 180 }), "WiFiConnection 802.11ac signal -52 expected 180", "Wi-Fi")
    t_eq(Playback_startNet({ type: "WiredConnection" }), "WiredConnection", "wired")
    t_eq(Playback_startNet(invalid), "unknown", "no info")
end sub

sub test_startPlayInfo()
    psi = { total_dur: 7.9, prebuf_dur: 5.25, prebuf_start: 0.3, manifest_dur: 0 }
    t_eq(Playback_startPlayInfo(psi, 7.95), "7.95 s · total 7.9 · prebuf 5.25 from 0.3 · manifest 0", "the breakdown")
    t_eq(Playback_startPlayInfo({}, invalid), "? s · no playStartInfo", "not given")
    t_eq(Playback_startStreamInfo({ streamBitrate: 62000000, measuredBitrate: 140000000 }, "hevc", "eac3"), "62000000 measured 140000000 · decodes hevc eac3", "stream info")
    t_eq(Playback_startStreamInfo(invalid, invalid, ""), "? · decodes ? ?", "nothing known")
end sub

sub test_startBufStep()
    t_eq(Playback_startBufStep(0), 0, "0 %")
    t_eq(Playback_startBufStep(39), 30, "39 % is the 30 % step")
    t_eq(Playback_startBufStep(40), 40, "40 %")
    t_eq(Playback_startBufStep(100), 100, "100 %")
    t_eq(Playback_startBufStep(130), 100, "capped")
    t_eq(Playback_startBufStep(invalid), 0, "missing")
end sub
