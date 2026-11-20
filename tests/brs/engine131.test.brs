' v1.3.1 engine fixes (review4 engine.md): the watched mark after the stop report (E-1)

sub test_needsPlayedMark()
    t_eq(Playback_needsPlayedMark(1300.0, 1400.0, -1.0), false, "93 %: the stop report marks it, no POST")
    t_eq(Playback_needsPlayedMark(1260.0, 1400.0, 1200.0), false, "exactly 90 % in the credits: the stop report")
    t_eq(Playback_needsPlayedMark(1220.0, 1400.0, 1200.0), true, "in the credits under 90 %: Cove marks it")
    t_eq(Playback_needsPlayedMark(1100.0, 1400.0, 1200.0), false, "before the credits: not watched")
    t_eq(Playback_needsPlayedMark(1220.0, 1400.0, 0.0), false, "no credits marker: never under 90 %")
    t_eq(Playback_needsPlayedMark(100.0, 0.0, 50.0), false, "duration unknown: nothing")
end sub

' (E-2) an external text subtitle before an embedded one of the same language (Cove for macOS bestTextSub)
function t_subItem() as object
    return { MediaSources: [{ Id: "src", MediaStreams: [
        { Type: "Video", Index: 0, Codec: "hevc" },
        { Type: "Subtitle", Index: 2, Codec: "subrip", Language: "eng", DisplayTitle: "English (SUBRIP)" },
        { Type: "Subtitle", Index: 3, Codec: "pgssub", Language: "rum", DisplayTitle: "Romanian (PGS)" },
        { Type: "Subtitle", Index: 4, Codec: "subrip", Language: "rum", DisplayTitle: "Romanian (SUBRIP)" },
        { Type: "Subtitle", Index: 5, Codec: "srt", Language: "eng", DisplayTitle: "English (SRT)", IsExternal: true },
        { Type: "Subtitle", Index: 6, Codec: "srt", Language: "rum", DisplayTitle: "Romanian - SRT - External", IsExternal: true },
        { Type: "Subtitle", Index: 7, Codec: "subrip", Language: "fre", DisplayTitle: "French (SUBRIP)", IsForced: true },
        { Type: "Subtitle", Index: 8, Codec: "srt", Language: "fre", DisplayTitle: "French (SRT)", IsForced: true, IsExternal: true },
        { Type: "Subtitle", Index: 9, Codec: "pgssub", Language: "ger", DisplayTitle: "German (PGS)", IsExternal: true }
    ] }] }
end function

sub test_externalSubFirst()
    t = Tracks_fromItem(t_subItem())
    t_eq(Tracks_findSub(t, 5).external, true, "IsExternal is kept")
    t_eq(Tracks_findSub(t, 2).external, false, "an embedded track")
    t_eq(Tracks_findSub(t, 5).label, "English (SRT)  ·  External", "External added to the label")
    t_eq(Tracks_findSub(t, 6).label, "Romanian - SRT - External", "no second External when the server says it")
    t_eq(Tracks_defaultSub(t, "eng"), 5, "defaultSub: the external English file")
    t_eq(Tracks_defaultSub(t, "rum"), 6, "defaultSub: external Romanian before embedded text and PGS")
    t_eq(Tracks_defaultSub(t, "ger"), 9, "only pictures: still found")
    t_eq(Tracks_defaultSub(t, ""), 8, "forced: the external file first")
    t_eq(Tracks_subForLanguage(t, "English"), 5, "Always load / Roku language: external first")
    t_eq(Tracks_subForLanguage(t, "Romanian"), 6, "by codes: external first")
    t_eq(Tracks_subKindOf(t, 6), "external", "kind: external")
    t_eq(Tracks_subKindOf(t, 4), "embedded", "kind: embedded")
    t_eq(Tracks_subKindOf(t, 3), "burned in", "kind: picture")
    t_eq(Tracks_subKindOf(t, -1), "none", "kind: none")
end sub

sub test_embeddedStillWithoutExternal()
    t = Tracks_fromItem({ MediaStreams: [
        { Type: "Subtitle", Index: 3, Codec: "pgssub", Language: "eng" },
        { Type: "Subtitle", Index: 4, Codec: "subrip", Language: "eng" }
    ] })
    t_eq(Tracks_defaultSub(t, "eng"), 4, "embedded text before pictures")
    t_eq(Tracks_subForLanguage(t, "English"), 4, "embedded text before pictures (Settings)")
end sub

' (E-3) subtitles in two parts: the first minutes, then the whole track; (E-10) the session copy's key
sub test_subtitlePieceUrl()
    srv = { url: "http://nas:8096" }
    t_eq(Playback_subtitleUrl(srv, "it1", "src1", 3), "http://nas:8096/Videos/it1/src1/Subtitles/3/Stream.srt", "the whole track")
    t_eq(Playback_subtitleUrl(srv, "it1", "src1", 3, 600.0), "http://nas:8096/Videos/it1/src1/Subtitles/3/0/Stream.srt?EndPositionTicks=6000000000", "up to 10 minutes")
end sub

sub test_cueStep()
    t_eq(Playback_cueStep(200, 40, true, false), "use", "first part came")
    t_eq(Playback_cueStep(200, 0, true, false), "askAll", "first part empty: the whole track")
    t_eq(Playback_cueStep(-1, 0, true, false), "askAll", "first part timed out: the whole track")
    t_eq(Playback_cueStep(404, 0, true, false), "askAll", "first-part route missing (older server): the whole track")
    t_eq(Playback_cueStep(200, 900, false, true), "use", "whole track came")
    t_eq(Playback_cueStep(-1, 0, false, true), "keep", "whole track timed out after the first part: keep it")
    t_eq(Playback_cueStep(500, 0, false, false), "burnIn", "the server can't send it as text: burn in")
    t_eq(Playback_cueStep(-1, 0, false, false), "failed", "no answer in time: a note, no burn-in")
end sub

sub test_subCacheKey()
    k = Playback_subCacheKey("abc123", "mediasource_77", 4)
    t_eq(k, "abc123_mediasource_77_4", "letters, digits and _")
    t_eq(Playback_subCacheKey("a/../b", "x y", 1), "ab_xy_1", "nothing that leaves tmp:/")
    t_eq(Playback_subCacheFile(k), "tmp:/cove-sub-abc123_mediasource_77_4.srt", "the file")
end sub

' (E-5) the real play method: from the stream URL, then from the server's TranscodingInfo
sub test_guessMethod()
    hls = "http://nas/videos/1/master.m3u8?DeviceId=x&MediaSourceId=a&VideoCodec=h264,hevc&AudioCodec=eac3,ac3,aac"
    t_eq(Playback_guessMethod("http://nas/Videos/1/stream?static=true&MediaSourceId=a"), "DirectPlay", "the file itself")
    t_eq(Playback_guessMethod(hls + "&TranscodeReasons=ContainerNotSupported", "ac3"), "DirectStream", "an H.264 MKV remux: Direct Stream")
    t_eq(Playback_guessMethod(hls, "dts"), "Transcode", "DTS not in AudioCodec: converted")
    t_eq(Playback_guessMethod(hls + "&AllowVideoStreamCopy=false", "aac"), "Transcode", "no video copy")
    t_eq(Playback_guessMethod(hls + "&allowaudiostreamcopy=false", "aac"), "Transcode", "no audio copy (any case)")
    t_eq(Playback_guessMethod(hls + "&SubtitleStreamIndex=3&SubtitleMethod=Encode", "aac"), "Transcode", "burned-in subtitle")
    t_eq(Playback_guessMethod(hls + "&TranscodeReasons=VideoCodecNotSupported%2CContainerNotSupported", "aac"), "Transcode", "a codec reason")
    t_eq(Playback_guessMethod(hls + "&TranscodeReasons=SubtitleCodecNotSupported", "aac"), "DirectStream", "a subtitle reason without burn-in")
    t_eq(Playback_guessMethod(hls, ""), "DirectStream", "source audio unknown: by the URL alone")
end sub

sub test_classifyMethod()
    hls = "http://nas/videos/1/master.m3u8?AudioCodec=aac"
    t_eq(Playback_classifyMethod(hls, { IsVideoDirect: true, IsAudioDirect: true }, "dts"), "DirectStream", "server: both copied")
    t_eq(Playback_classifyMethod(hls, { IsVideoDirect: true, IsAudioDirect: false }, "aac"), "Transcode", "server: audio converted")
    t_eq(Playback_classifyMethod(hls, { IsVideoDirect: false, IsAudioDirect: true }, "aac"), "Transcode", "server: video converted")
    t_eq(Playback_classifyMethod(hls, { IsVideoDirect: true }, "aac"), "DirectStream", "no audio field: nothing to convert")
    t_eq(Playback_classifyMethod(hls, {}, "dts"), "Transcode", "no TranscodingInfo fields: the URL guess")
    t_eq(Playback_classifyMethod(hls, invalid, "aac"), "DirectStream", "no session: the URL guess")
    t_eq(Playback_classifyMethod("http://nas/Videos/1/stream?static=true", { IsVideoDirect: false }, ""), "DirectPlay", "a static file stays Direct Play")
end sub

sub test_audioCodecOf()
    src = { MediaStreams: [{ Type: "Video", Index: 0, Codec: "h264" }, { Type: "Audio", Index: 1, Codec: "AC3" }, { Type: "Audio", Index: 2, Codec: "dts", IsDefault: true }] }
    t_eq(Playback_audioCodecOf(src, 1), "ac3", "the chosen track")
    t_eq(Playback_audioCodecOf(src, -1), "dts", "the file's default")
    t_eq(Playback_audioCodecOf(src, 9), "", "a track that isn't there")
    t_eq(Playback_audioCodecOf({}, -1), "", "no streams")
end sub
