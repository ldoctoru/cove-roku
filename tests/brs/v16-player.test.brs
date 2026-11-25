' v1.6 PLAYER: Q-2 chapter-name intro / credits (Tracks.chapterKind / fromChapterNames / segmentsReplaceChapters)

function t_ch(name as string, secs as integer) as object
    return { Name: name, StartPositionTicks: secs * 10000000& }
end function

function t_noMarks() as object
    return { introStart: -1.0, introEnd: -1.0, credits: -1.0, creditsEnd: -1.0, segs: [] }
end function

sub test_chapterKind_names()
    t_eq(Tracks_chapterKind("Intro"), "intro", "Intro")
    t_eq(Tracks_chapterKind("OPENING"), "intro", "any case")
    t_eq(Tracks_chapterKind("OP"), "intro", "OP")
    t_eq(Tracks_chapterKind("OP: Gurenge"), "intro", "OP with a song name")
    t_eq(Tracks_chapterKind("Opening 2"), "intro", "numbered")
    t_eq(Tracks_chapterKind("ED1"), "credits", "ED1")
    t_eq(Tracks_chapterKind("End Credits"), "credits", "End Credits")
    t_eq(Tracks_chapterKind("Ending - Song"), "credits", "Ending with a song name")
    t_eq(Tracks_chapterKind("Outro"), "credits", "Outro")
    t_eq(Tracks_chapterKind("Abspann"), "credits", "German")
    t_eq(Tracks_chapterKind("Previously On"), "recap", "Previously On")
    t_eq(Tracks_chapterKind("Recap"), "recap", "Recap")
    t_eq(Tracks_chapterKind("Next Episode Preview"), "preview", "preview")
end sub

sub test_chapterKind_falseMatches()
    t_eq(Tracks_chapterKind("Opening Night"), "", "Opening Night")
    t_eq(Tracks_chapterKind("The Intro of Doom"), "", "a word inside a name")
    t_eq(Tracks_chapterKind("Chapter 1"), "", "Chapter 1")
    t_eq(Tracks_chapterKind("Edward"), "", "ED as a prefix")
    t_eq(Tracks_chapterKind("Opera"), "", "OP as a prefix")
    t_eq(Tracks_chapterKind(""), "", "empty")
    t_eq(Tracks_chapterKind(invalid), "", "invalid")
end sub

sub test_fromChapterNames_introAndCredits()
    ch = [t_ch("Prologue", 0), t_ch("Opening", 90), t_ch("Part A", 180), t_ch("Part B", 700), t_ch("Ending", 1290), t_ch("Preview", 1380)]
    r = Tracks_fromChapterNames(ch, 1420.0, t_noMarks())
    t_eq(r.introStart, 90.0, "intro start")
    t_eq(r.introEnd, 180.0, "intro ends at the next chapter")
    t_eq(r.credits, 1290.0, "credits start")
    t_eq(r.creditsEnd, 1380.0, "credits end where the preview starts")
    t_eq(r.segs.count(), 1, "one other segment")
    t_eq(r.segs[0].kind, "preview", "the preview")
    t_eq(r.segs[0].e, 1420.0, "the last chapter runs to the end")
    t_ok(r.chapterMarks = true, "flagged as chapter marks")
end sub

sub test_fromChapterNames_creditsToEnd()
    r = Tracks_fromChapterNames([t_ch("Start", 0), t_ch("Credits", 5400)], 6000.0, t_noMarks())
    t_eq(r.credits, 5400.0, "credits")
    t_eq(r.creditsEnd, -1.0, "last chapter: to the end, no known end")
    t_eq(r.introStart, -1.0, "no intro")
end sub

sub test_fromChapterNames_gates()
    ' an "Intro" chapter in the middle and "Credits" early are ignored
    r = Tracks_fromChapterNames([t_ch("A", 0), t_ch("Credits", 300), t_ch("B", 400), t_ch("Intro", 3000), t_ch("C", 3100)], 6000.0, t_noMarks())
    t_eq(r.introStart, -1.0, "intro past 25 % ignored")
    t_eq(r.credits, -1.0, "credits before 70 % ignored")
    t_ok(not Util_flag(r, "chapterMarks"), "nothing found")
end sub

sub test_fromChapterNames_joinsAndRecap()
    r = Tracks_fromChapterNames([t_ch("Previously", 0), t_ch("OP", 60), t_ch("OP 2", 100), t_ch("Story", 150)], 1400.0, t_noMarks())
    t_eq(r.introStart, 60.0, "intro start")
    t_eq(r.introEnd, 150.0, "two adjacent intro chapters join")
    t_eq(r.segs.count(), 1, "recap segment")
    t_eq(r.segs[0].kind, "recap", "recap kind")
    t_eq(r.segs[0].e, 60.0, "recap ends at the intro")
end sub

sub test_fromChapterNames_serverWins()
    mk = t_noMarks()
    mk.introStart = 10.0
    mk.introEnd = 70.0
    r = Tracks_fromChapterNames([t_ch("Intro", 100), t_ch("Story", 190)], 1400.0, mk)
    t_eq(r.introStart, 10.0, "server marker kept")
    t_ok(not Util_flag(r, "chapterMarks"), "not flagged")
end sub

sub test_fromChapterNames_noData()
    r = Tracks_fromChapterNames(invalid, 1400.0, t_noMarks())
    t_eq(r.introStart, -1.0, "no chapters")
    r = Tracks_fromChapterNames([t_ch("Intro", 0), t_ch("A", 90)], 0.0, t_noMarks())
    t_eq(r.introStart, -1.0, "unknown runtime: nothing")
    r = Tracks_fromChapterNames([t_ch("Intro", 0), t_ch("A", 90)], 1400.0, invalid)
    t_eq(r.introStart, 0.0, "invalid marks start empty")
end sub

sub test_segmentsReplaceChapters()
    r = Tracks_fromChapterNames([t_ch("Intro", 0), t_ch("A", 90)], 1400.0, t_noMarks())
    t_eq(Tracks_segmentsReplaceChapters({ Items: [] }, r).introStart, 0.0, "empty answer keeps chapter marks")
    t_eq(Tracks_segmentsReplaceChapters(invalid, r).introStart, 0.0, "no answer keeps chapter marks")
    seg = { Items: [{ Type: "Intro", StartTicks: 50000000, EndTicks: 600000000 }] }
    cleared = Tracks_segmentsReplaceChapters(seg, r)
    t_eq(cleared.introStart, -1.0, "segments replace chapter marks")
    t_eq(Tracks_fromSegments(seg, cleared).introStart, 5.0, "then the server's intro")
end sub

' ---------------------------------------------------------------- M-1 Play Collection (Playback.collection*)

function t_box() as object
    return [
        { Id: "a", Name: "Alien", Type: "Movie", ProductionYear: 1979, UserData: { Played: true }, Overview: "long text" },
        { Id: "s", Name: "A Series", Type: "Series" },
        { Id: "b", Name: "Aliens", Type: "Movie", ProductionYear: 1986, UserData: { PlaybackPositionTicks: 6000000000& } },
        { Id: "c", Name: "Alien 3", Type: "Movie", ProductionYear: 1992 }
    ]
end function

sub test_collectionQueue_fromTarget()
    q = Playback_collectionQueue(t_box(), "b")
    t_eq(q.index, 1, "second playable film (the series is skipped)")
    t_eq(q.count, 3, "three films")
    t_eq(q.queue.count(), 1, "one film after it")
    t_eq(q.queue[0].Id, "c", "Alien 3 follows")
    t_eq(q.queue[0].collectionIndex, 2, "its place in the collection")
    t_ok(q.queue[0].Overview = invalid, "trimmed")
end sub

sub test_collectionQueue_first()
    q = Playback_collectionQueue(t_box(), "a")
    t_eq(q.index, 0, "first film")
    t_eq(q.queue.count(), 2, "two follow")
    t_eq(q.queue[0].Id, "b", "in the list's order")
    t_ok(q.queue[0].UserData <> invalid, "UserData kept for the resume point")
end sub

sub test_collectionQueue_missing()
    t_eq(Playback_collectionQueue(t_box(), "zz").index, -1, "unknown target")
    t_eq(Playback_collectionQueue(t_box(), "zz").queue.count(), 0, "nothing queued")
    t_eq(Playback_collectionQueue(invalid, "a").count, 0, "no list")
    t_eq(Playback_collectionQueue(t_box(), "s").index, -1, "a series isn't a playable target")
end sub

sub test_collectionSortBy()
    t_eq(Playback_collectionSortBy("SortName"), "SortName", "the server's name order")
    t_eq(Playback_collectionSortBy("PremiereDate"), "PremiereDate,ProductionYear,SortName", "release order")
    t_eq(Playback_collectionSortBy(invalid), "PremiereDate,ProductionYear,SortName", "default release order")
end sub

sub test_collectionUpNextStart()
    t_eq(Playback_collectionUpNextStart(6500.0, 7200.0), 6500.0, "credits marker in the second half")
    t_eq(Playback_collectionUpNextStart(-1.0, 7200.0), 6900.0, "no marker: 5 min before the end")
    t_eq(Playback_collectionUpNextStart(1000.0, 7200.0), 6900.0, "marker in the first half ignored")
    t_eq(Playback_collectionUpNextStart(-1.0, 800.0), 500.0, "short film: never before half")
    t_eq(Playback_collectionUpNextStart(-1.0, 400.0), -1.0, "under 10 min: no card")
    t_eq(Playback_collectionUpNextStart(-1.0, 0.0), -1.0, "unknown duration")
end sub

sub test_collectionHeadingAndTitle()
    t_eq(Playback_collectionHeading(1, 3), "Up Next · Film 2 of 3", "heading")
    t_eq(Playback_collectionHeading(-1, 3), "Up Next", "unknown place")
    t_eq(Playback_filmTitle({ Name: "The Two Towers", ProductionYear: 2002 }), "The Two Towers (2002)", "with year")
    t_eq(Playback_filmTitle({ Name: "Untitled" }), "Untitled", "no year")
end sub

sub test_collectionPlayable()
    t_ok(Playback_isCollectionPlayable({ Id: "1", Type: "Movie" }), "movie")
    t_ok(not Playback_isCollectionPlayable({ Id: "1", Type: "BoxSet" }), "nested collection")
    t_ok(not Playback_isCollectionPlayable({ Type: "Movie" }), "no id")
    t_ok(not Playback_isCollectionPlayable(invalid), "invalid")
end sub
