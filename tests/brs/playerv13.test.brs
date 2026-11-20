' v1.3 player helpers: hold-to-seek steps (Playback), Rewind / Fast forward runs (NV-16), where Up Next shows
' in the credits, and Settings → Playback → Skip (Prefs, one registry key)

sub test_upNextStart()
    t_eq(Playback_upNextStart(1300.0, 1400.0), 1300.0, "the server's credits marker")
    t_eq(Playback_upNextStart(-1.0, 1400.0), 1370.0, "no marker: the last 30 s")
    t_eq(Playback_upNextStart(0.0, 1400.0), 1370.0, "a 0 marker counts as none")
    t_eq(Playback_upNextStart(1400.0, 1400.0), 1370.0, "a marker at the very end: the last 30 s")
    t_eq(Playback_upNextStart(-1.0, 100.0), -1.0, "a short clip: never")
    t_eq(Playback_upNextStart(500.0, 0.0), 500.0, "duration unknown yet: the marker")
end sub

sub test_segmentSkipDefaults()
    a = Prefs_segmentSkipAll()
    t_eq(a.intro, "auto", "intros skipped by default (v1.2 Skip intros on)")
    t_eq(a.recap, "ask", "recaps ask (v1.2 Skip recaps off)")
    t_eq(a.preview, "ask", "previews ask")
    t_eq(a.commercial, "ask", "ads ask")
    t_eq(a.credits, "ask", "credits ask")
    t_eq(Util_readText("segSkip"), "", "reading writes nothing")
    ' the v1.2 switches still count until a row is changed
    Prefs_setFlag("autoSkipIntro", false)
    Prefs_setFlag("autoSkipRecap", true)
    t_eq(Prefs_segmentSkipOf("intro"), "ask", "old Skip intros off: ask")
    t_eq(Prefs_segmentSkipOf("recap"), "auto", "old Skip recaps on: auto")
    t_eq(Prefs_segmentSkipOf("nonsense"), "ask", "an unknown kind asks")
end sub

sub test_segmentSkipWrite()
    ' (the registry is shared by the cases of one file: back to the v1.2 defaults)
    Prefs_setFlag("autoSkipIntro", true)
    Prefs_setFlag("autoSkipRecap", false)
    Prefs_setSegmentSkip("credits", "auto")
    Prefs_setSegmentSkip("preview", "off")
    t_eq(Prefs_segmentSkipOf("credits"), "auto", "credits saved")
    t_eq(Prefs_segmentSkipOf("preview"), "off", "previews saved")
    t_eq(Prefs_segmentSkipOf("intro"), "auto", "the rest keep their defaults")
    Prefs_setSegmentSkip("credits", "maybe")
    t_eq(Prefs_segmentSkipOf("credits"), "auto", "a bad value is ignored")
    Prefs_setSegmentSkip("bogus", "off")
    saved = ParseJson(Util_readText("segSkip"))
    t_ok(saved.bogus = invalid, "an unknown kind isn't stored")
    t_eq(saved.Count(), 2, "only the changed kinds are stored (one compact key)")
    t_ok(Len(Util_readText("segSkip")) < 80, "small")
    ' an old v1.2 switch no longer matters once its row is set
    Prefs_setSegmentSkip("intro", "ask")
    Prefs_setFlag("autoSkipIntro", true)
    t_eq(Prefs_segmentSkipOf("intro"), "ask", "the row wins over the old switch")
    ' a damaged key: defaults
    Util_writeText("segSkip", "not json")
    t_eq(Prefs_segmentSkipOf("credits"), "ask", "damaged JSON: defaults")
end sub

sub test_segmentName()
    t_eq(Tracks_segmentName("intro"), "Intro", "intro")
    t_eq(Tracks_segmentName("commercial"), "Ad", "ad")
    t_eq(Tracks_segmentName("credits"), "Credits", "credits")
    t_eq(Tracks_segmentName("x"), "Segment", "other")
end sub
