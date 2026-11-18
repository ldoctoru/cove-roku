' Tracks.capForcesEncode (source/Tracks.bs, PL-11)
function t_info() as object
    return { MediaSources: [{ Id: "a", Bitrate: 60000000 }, { Id: "b", Bitrate: 8000000 }] }
end function

sub test_capForcesEncode_auto()
    t_ok(not Tracks_capForcesEncode(t_info(), "", 0), "automatic quality")
end sub

sub test_capForcesEncode_below()
    t_ok(Tracks_capForcesEncode(t_info(), "", 20000000), "first file above the cap")
    t_ok(Tracks_capForcesEncode(t_info(), "a", 20000000), "chosen file above the cap")
end sub

sub test_capForcesEncode_within()
    t_ok(not Tracks_capForcesEncode(t_info(), "b", 20000000), "chosen file within the cap")
    t_ok(not Tracks_capForcesEncode(t_info(), "", 120000000), "cap above the file")
end sub

sub test_capForcesEncode_missing()
    t_ok(not Tracks_capForcesEncode(invalid, "", 20000000), "no answer")
    t_ok(not Tracks_capForcesEncode({ MediaSources: [] }, "", 20000000), "no files")
    t_ok(not Tracks_capForcesEncode({ MediaSources: [{ Id: "a" }] }, "", 20000000), "no bitrate")
end sub

' (v1.1) commentary tracks and the audio to start with (Tracks.startAudio / wantedAudio)
function t_audioTracks() as object
    return { sourceId: "", subs: [], audio: [
        { index: 1, label: "English - Commentary - AC3", language: "eng", isDefault: true },
        { index: 2, label: "English - AC3 5.1", language: "eng", isDefault: false },
        { index: 3, label: "Japanese - AAC", language: "jpn", isDefault: false },
        { index: 4, label: "German - Kommentar", language: "ger", isDefault: false }
    ] }
end function

sub test_isCommentary()
    t_ok(Tracks_isCommentary("English - Director's Commentary - AC3"), "English")
    t_ok(Tracks_isCommentary("Deutsch  ·  KOMMENTAR"), "German, any case")
    t_ok(Tracks_isCommentary("Français - commentaire audio"), "French")
    t_ok(Tracks_isCommentary("Español (comentario)"), "Spanish")
    t_ok(Tracks_isCommentary("Italiano - Commento"), "Italian")
    t_ok(not Tracks_isCommentary("English - AC3 5.1"), "a normal track")
end sub

sub test_startAudio_skipsCommentaryDefault()
    t_eq(Tracks_defaultAudio(t_audioTracks()), 1, "the file's default is the commentary")
    t_eq(Tracks_startAudio(t_audioTracks(), []), 2, "starts on the same language's other track")
end sub

sub test_startAudio_language()
    t_eq(Tracks_startAudio(t_audioTracks(), ["jpn"]), 3, "the series' language")
    t_eq(Tracks_startAudio(t_audioTracks(), ["ja"]), 3, "a two-letter code")
    t_eq(Tracks_startAudio(t_audioTracks(), ["fre", "jpn"]), 3, "the first language with a track")
    t_eq(Tracks_startAudio(t_audioTracks(), ["ger"]), 2, "only a commentary in that language: the default's language")
end sub

sub test_startAudio_plainDefault()
    t = { sourceId: "", subs: [], audio: [{ index: 0, label: "English", language: "eng", isDefault: false }, { index: 5, label: "French", language: "fre", isDefault: true }] }
    t_eq(Tracks_startAudio(t, []), 5, "the file's default")
    t_eq(Tracks_startAudio({ sourceId: "", subs: [], audio: [] }, ["eng"]), -1, "no audio")
    only = { sourceId: "", subs: [], audio: [{ index: 7, label: "Commentary", language: "eng", isDefault: true }] }
    t_eq(Tracks_startAudio(only, []), 7, "a commentary only: still played")
end sub

sub test_wantedAudio()
    t = t_audioTracks()
    t_eq(Tracks_wantedAudio(t, "jpn", invalid).count(), 1, "series language only")
    w = Tracks_wantedAudio(t, "", { lang: "jpn", playDefault: false })
    t_eq(w.count(), 1, "account language")
    t_eq(w[0], "jpn", "account language value")
    t_eq(Tracks_wantedAudio(t, "", { lang: "jpn", playDefault: true }).count(), 0, "default track regardless of language")
    noFlag = { sourceId: "", subs: [], audio: [{ index: 0, label: "English", language: "eng", isDefault: false }] }
    t_eq(Tracks_wantedAudio(noFlag, "", { lang: "jpn", playDefault: true }).count(), 1, "no flagged track: the language counts")
    w = Tracks_wantedAudio(t, "ger", { lang: "jpn", playDefault: false })
    t_eq(w[0], "ger", "series first")
    t_eq(w[1], "jpn", "account second")
end sub

sub test_codesOfLanguage()
    t_eq(Tracks_codesOfLanguage("ja").count(), 2, "Japanese codes")
    t_eq(Tracks_codesOfLanguage("xyz")[0], "xyz", "an unknown code")
    t_eq(Tracks_codesOfLanguage("").count(), 0, "none")
end sub
