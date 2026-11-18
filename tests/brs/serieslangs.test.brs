' Prefs series languages (source/Prefs.bs, v1.1): subtitles and audio share one bounded registry key

sub test_seriesAudioLang_roundTrip()
    t_eq(Prefs_seriesAudioLang("s1"), "", "nothing yet")
    Prefs_setSeriesAudioLang("s1", "jpn")
    t_eq(Prefs_seriesAudioLang("s1"), "jpn", "kept")
    t_eq(Prefs_seriesSubLang("s1"), "", "no subtitle language")
    Prefs_setSeriesSubLang("s1", "eng")
    t_eq(Prefs_seriesAudioLang("s1"), "jpn", "audio kept beside the subtitles")
    t_eq(Prefs_seriesSubLang("s1"), "eng", "subtitles kept")
    t_eq(Prefs_seriesLangList().count(), 1, "one entry per series")
end sub

sub test_seriesLangs_clear()
    Prefs_setSeriesAudioLang("s2", "ger")
    Prefs_setSeriesSubLang("s2", "off")
    Prefs_setSeriesSubLang("s2", "")
    t_eq(Prefs_seriesAudioLang("s2"), "ger", "audio stays when the subtitles go back to automatic")
    Prefs_setSeriesAudioLang("s2", "")
    found = false
    for each e in Prefs_seriesLangList()
        if e.id = "s2" then found = true
    end for
    t_ok(not found, "an empty entry is dropped")
end sub

sub test_seriesLangs_bounded()
    for i = 1 to 60
        Prefs_setSeriesAudioLang("x" + i.toStr(), "eng")
    end for
    t_ok(Prefs_seriesLangList().count() <= 50, "at most 50 series")
    t_eq(Prefs_seriesAudioLang("x60"), "eng", "the newest kept")
    t_eq(Prefs_seriesAudioLang("x1"), "", "the oldest dropped")
end sub

sub test_defaultSpeed_175()
    Util_writeText("defaultSpeed", "1.75")
    t_eq(Prefs_defaultSpeed(), "1.75", "1.75x is a valid default speed")
end sub
