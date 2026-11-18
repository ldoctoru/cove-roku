'  Clock.formatHm (source/Clock.bs, v1.1): the Roku's 12 / 24 hour clock format

sub test_formatHm_24h()
    t_eq(Clock_formatHm(22, 41, true), "22:41", "evening")
    t_eq(Clock_formatHm(9, 5, true), "09:05", "morning, padded")
    t_eq(Clock_formatHm(0, 0, true), "00:00", "midnight")
end sub

sub test_formatHm_12h()
    t_eq(Clock_formatHm(22, 41, false), "10:41 PM", "evening")
    t_eq(Clock_formatHm(9, 5, false), "9:05 AM", "morning")
    t_eq(Clock_formatHm(0, 5, false), "12:05 AM", "after midnight")
    t_eq(Clock_formatHm(12, 0, false), "12:00 PM", "noon")
end sub

' (review3 test 9) the edges of the day
sub test_formatHm_edges()
    t_eq(Clock_formatHm(0, 0, false), "12:00 AM", "midnight, 12 h")
    t_eq(Clock_formatHm(12, 59, false), "12:59 PM", "noon hour")
    t_eq(Clock_formatHm(23, 59, false), "11:59 PM", "last minute, 12 h")
    t_eq(Clock_formatHm(23, 59, true), "23:59", "last minute, 24 h")
    t_eq(Clock_formatHm(13, 0, false), "1:00 PM", "one in the afternoon")
end sub

' (v1.1.2) the launch timing lines: milliseconds between two { secs, ms } stamps
sub test_msBetween()
    t_eq(Clock_msBetween({ secs: 100, ms: 250 }, { secs: 102, ms: 750 }), 2500, "whole and part seconds")
    t_eq(Clock_msBetween({ secs: 100, ms: 900 }, { secs: 101, ms: 100 }), 200, "across a second")
    t_eq(Clock_msBetween({ secs: 1795000000, ms: 0 }, { secs: 1795000000, ms: 0 }), 0, "same moment")
    t_eq(Clock_msBetween(invalid, { secs: 1, ms: 0 }), -1, "no launch stamp")
    t_eq(Clock_msBetween({ secs: 1 }, { secs: 2, ms: 0 }), -1, "half a stamp")
end sub
