' v1.5.2 player fixes (review 5 P5-n): Playback / Tracks helpers

sub test_resumeAtOf()
    t_eq(Playback_resumeAtOf({ UserData: { PlaybackPositionTicks: 12000000000&, Played: false } }), 1200.0, "20:00 resume point")
    t_eq(Playback_resumeAtOf({ UserData: { PlaybackPositionTicks: 250000000 } }), 0.0, "under 30 s: from the start")
    t_eq(Playback_resumeAtOf({ UserData: { PlaybackPositionTicks: 12000000000&, Played: true } }), 0.0, "watched: from the start")
    t_eq(Playback_resumeAtOf({ UserData: {} }), 0.0, "no position")
    t_eq(Playback_resumeAtOf({}), 0.0, "no UserData")
    t_eq(Playback_resumeAtOf(invalid), 0.0, "invalid")
    t_eq(Playback_resumeAtOf({ UserData: { PlaybackPositionTicks: "600000000" } }), 60.0, "ticks as text")
end sub

sub test_isMissingEpisode()
    t_ok(Playback_isMissingEpisode({ Id: "1", LocationType: "Virtual" }), "virtual")
    t_ok(Playback_isMissingEpisode({ Id: "1", IsMissing: true }), "IsMissing")
    t_ok(not Playback_isMissingEpisode({ Id: "1", LocationType: "FileSystem" }), "on disk")
    t_ok(not Playback_isMissingEpisode({ Id: "1" }), "no fields: playable")
    t_ok(not Playback_isMissingEpisode(invalid), "invalid")
end sub

sub test_episodePathsSkipMissing()
    t_ok(Playback_adjacentEpisodesPath("u1", "s9", "e5").instr("IsMissing=false") >= 0, "adjacent: IsMissing=false")
    t_ok(Playback_seriesEpisodesPath("u1", "s9").instr("IsMissing=false") >= 0, "series: IsMissing=false")
end sub

sub test_errorResumeAt()
    t_eq(Playback_errorResumeAt(3300.0, 3290.0, 600.0), 3300.0, "the Video node's position")
    t_eq(Playback_errorResumeAt(0.0, 3290.0, 600.0), 3290.0, "position 0 after the error: the last one seen")
    t_eq(Playback_errorResumeAt(0.0, 0.0, 600.0), 600.0, "nothing seen: the start")
end sub

sub test_endedEarly()
    t_ok(Playback_endedEarly(2400.0, 5400.0, -1.0), "40:00 of 1:30:00")
    t_ok(not Playback_endedEarly(5370.0, 5400.0, -1.0), "the last minute: the end")
    t_ok(not Playback_endedEarly(5100.0, 5400.0, 5000.0), "in the credits: the end")
    t_ok(Playback_endedEarly(4000.0, 5400.0, 5000.0), "before the credits: early")
    t_ok(not Playback_endedEarly(10.0, 0.0, -1.0), "unknown duration: the end")
end sub

function v152_subs() as object
    return [
        { index: 2, language: "eng", label: "English (SUBRIP)", isText: true, external: false },
        { index: 3, language: "rum", label: "Romanian (PGS)  (burned in)", isText: false, external: false }
    ]
end function

sub test_rematch()
    old = v152_subs()
    t_eq(Tracks_rematch(old, old, 2), 2, "same list: same index")
    shifted = [
        { index: 2, language: "fre", label: "French (SUBRIP)  ·  External", isText: true, external: true },
        { index: 3, language: "eng", label: "English (SUBRIP)", isText: true, external: false },
        { index: 4, language: "rum", label: "Romanian (PGS)  (burned in)", isText: false, external: false }
    ]
    t_eq(Tracks_rematch(old, shifted, 2), 3, "renumbered: follows the track")
    t_eq(Tracks_rematch(old, shifted, 3), 4, "renumbered burned-in track")
    t_eq(Tracks_rematch(old, [], 2), -1, "gone")
    t_eq(Tracks_rematch(old, shifted, -1), -1, "none chosen")
    t_eq(Tracks_rematch(old, shifted, 9), -1, "unknown index")
end sub

sub test_addedTracks()
    old = v152_subs()
    fresh = [
        { index: 2, language: "eng", label: "English (SUBRIP)  ·  External", isText: true, external: true },
        { index: 3, language: "eng", label: "English (SUBRIP)", isText: true, external: false },
        { index: 4, language: "rum", label: "Romanian (PGS)  (burned in)", isText: false, external: false }
    ]
    added = Tracks_addedTracks(old, fresh)
    t_eq(added.count(), 1, "one new track, though the indexes moved")
    t_eq(added[0].index, 2, "the external one")
    t_eq(Tracks_addedTracks(invalid, fresh).count(), 3, "no list before: all new")
    t_eq(Tracks_addedTracks(old, old).count(), 0, "nothing new")
end sub

sub test_downloadedSub()
    list = [
        { index: 5, language: "rum", label: "Romanian (PGS)", isText: false, external: false },
        { index: 6, language: "eng", label: "English (SUBRIP)", isText: true, external: false },
        { index: 1, language: "eng", label: "English (SUBRIP)  ·  External", isText: true, external: true }
    ]
    t_eq(Tracks_downloadedSub(list).index, 1, "external text first")
    t_eq(Tracks_downloadedSub([list[0], list[1]]).index, 6, "else the first text one")
    t_ok(Tracks_downloadedSub([list[0]]) = invalid, "image only: none")
end sub
