' Subs.parseSrt / srtTime (source/Subs.bs)
function t_srt(lines as object) as string
    return lines.join(chr(10))
end function

sub test_parseSrt_basic()
    cues = Subs_parseSrt(t_srt(["1", "00:00:01,000 --> 00:00:02,500", "Hello", "", "2", "00:01:02,250 --> 00:01:04,000", "Line one", "Line two", ""]))
    t_eq(cues.count(), 2, "two cues")
    t_eq(cues[0].s, 1, "start 1")
    t_eq(cues[0].e, 2.5, "end 1")
    t_eq(cues[0].t, "Hello", "text 1")
    t_eq(cues[1].s, 62.25, "start 2")
    t_eq(cues[1].t, "Line one" + chr(10) + "Line two", "two lines")
end sub

sub test_parseSrt_tagsAndCrLf()
    text = "1" + chr(13) + chr(10) + "00:00:05,000 --> 00:00:06,000 X1:10 X2:20" + chr(13) + chr(10) + "{\an8}<i>Up</i> <font color=" + chr(34) + "red" + chr(34) + ">here</font>" + chr(13) + chr(10)
    cues = Subs_parseSrt(text)
    t_eq(cues.count(), 1, "one cue")
    t_eq(cues[0].t, "Up here", "tags dropped")
    t_eq(cues[0].e, 6, "position hints after the time ignored")
end sub

sub test_parseSrt_noBlankLine()
    ' (a malformed file: the next number and timing line follow without a blank line)
    cues = Subs_parseSrt(t_srt(["1", "00:00:01,000 --> 00:00:02,000", "One", "2", "00:00:03,000 --> 00:00:04,000", "Two"]))
    t_eq(cues.count(), 2, "two cues")
    t_eq(cues[0].t, "One", "the number is not text")
    t_eq(cues[1].t, "Two", "second")
end sub

sub test_parseSrt_sortedAndFiltered()
    cues = Subs_parseSrt(t_srt(["2", "00:00:09,000 --> 00:00:10,000", "Later", "", "1", "00:00:01,000 --> 00:00:02,000", "Sooner", "", "3", "00:00:05,000 --> 00:00:04,000", "Backwards", "", "4", "00:00:06,000 --> 00:00:07,000", "<i></i>", ""]))
    t_eq(cues.count(), 2, "backwards and empty cues dropped")
    t_eq(cues[0].t, "Sooner", "sorted by start")
end sub

sub test_parseSrt_empty()
    t_eq(Subs_parseSrt(invalid), [], "invalid")
    t_eq(Subs_parseSrt(""), [], "empty")
    t_eq(Subs_parseSrt("no cues here"), [], "no timing lines")
end sub

sub test_srtTime()
    t_eq(Subs_srtTime("01:02:03,500"), 3723.5, "h:m:s,ms")
    t_eq(Subs_srtTime(" 00:00:07.25 "), 7.25, "dot and spaces")
    t_eq(Subs_srtTime("02:03"), 123, "m:s")
end sub
