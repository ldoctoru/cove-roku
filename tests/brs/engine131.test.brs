' v1.3.1 engine fixes (review4 engine.md): the watched mark after the stop report (E-1)

sub test_needsPlayedMark()
    t_eq(Playback_needsPlayedMark(1300.0, 1400.0, -1.0), false, "93 %: the stop report marks it, no POST")
    t_eq(Playback_needsPlayedMark(1260.0, 1400.0, 1200.0), false, "exactly 90 % in the credits: the stop report")
    t_eq(Playback_needsPlayedMark(1220.0, 1400.0, 1200.0), true, "in the credits under 90 %: Cove marks it")
    t_eq(Playback_needsPlayedMark(1100.0, 1400.0, 1200.0), false, "before the credits: not watched")
    t_eq(Playback_needsPlayedMark(1220.0, 1400.0, 0.0), false, "no credits marker: never under 90 %")
    t_eq(Playback_needsPlayedMark(100.0, 0.0, 50.0), false, "duration unknown: nothing")
end sub
