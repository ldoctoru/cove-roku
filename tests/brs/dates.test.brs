' Dates (source/Dates.bs): air-date labels for the Upcoming row
sub test_daysFrom1970()
    t_eq(Dates_daysFrom1970(1970, 1, 1), 0, "epoch")
    t_eq(Dates_daysFrom1970(2000, 3, 1), 11017, "2000-03-01")
    t_eq(Dates_daysFrom1970(2026, 11, 21) - Dates_daysFrom1970(2026, 11, 17), 4, "same month")
    t_eq(Dates_daysFrom1970(2027, 1, 1) - Dates_daysFrom1970(2026, 12, 31), 1, "new year")
    t_eq(Dates_daysFrom1970(2028, 3, 1) - Dates_daysFrom1970(2028, 2, 28), 2, "leap day")
end sub

sub test_weekdayAbbr()
    t_eq(Dates_weekdayAbbr(0), "Thu", "1970-01-01")
    t_eq(Dates_weekdayAbbr(Dates_daysFrom1970(2026, 11, 21)), "Sat", "2026-11-21")
    t_eq(Dates_weekdayAbbr(Dates_daysFrom1970(2026, 11, 20)), "Fri", "2026-11-20")
end sub

sub test_ymdOf()
    d = Dates_ymdOf("2026-11-21T00:00:00.0000000Z")
    t_ok(d <> invalid and d.y = 2026 and d.m = 11 and d.d = 21, "full ISO")
    t_eq(Dates_ymdOf(invalid), invalid, "missing")
    t_eq(Dates_ymdOf("soon"), invalid, "not a date")
    t_eq(Dates_ymdOf("2026-13-01"), invalid, "bad month")
end sub

sub test_airLabel()
    today = { y: 2026, m: 11, d: 17 }
    t_eq(Dates_airLabel("2026-11-17T00:00:00.0000000Z", today, false), "Today", "today")
    t_eq(Dates_airLabel("2026-11-18T00:00:00Z", today, false), "Tomorrow", "tomorrow")
    t_eq(Dates_airLabel("2026-11-16T00:00:00Z", today, false), "Yesterday", "yesterday")
    t_eq(Dates_airLabel("2026-11-20T00:00:00Z", today, false), "Fri 20 Nov", "24 h style")
    t_eq(Dates_airLabel("2026-11-20T00:00:00Z", today, true), "Fri Nov 20", "12 h / US style")
    t_eq(Dates_airLabel("2027-01-04T00:00:00Z", today, false), "Mon 4 Jan", "next year, no year shown")
    t_eq(Dates_airLabel("2027-12-01T00:00:00Z", today, true), "Wed Dec 1 2027", "far off: with the year")
    t_eq(Dates_airLabel("", today, false), "", "no date")
end sub

' (BG-3) a server that keeps its local midnight in UTC: the Roku's local date, not the UTC date part
sub test_ymdOfLocal()
    bucharest = 2 * 3600
    d = Dates_ymdOf("2026-11-20T22:00:00.0000000Z", bucharest)
    t_ok(d.y = 2026 and d.m = 11 and d.d = 21, "UTC+2 local midnight: Nov 21")
    d = Dates_ymdOf("2026-11-20T22:00:00.0000000Z", 0)
    t_ok(d.d = 20, "on a UTC Roku: Nov 20")
    d = Dates_ymdOf("2026-11-21T05:00:00Z", -8 * 3600)
    t_ok(d.d = 20, "05:00Z on a UTC-8 Roku: Nov 20")
    d = Dates_ymdOf("2026-11-21T00:00:00.0000000Z", -8 * 3600)
    t_ok(d.d = 21, "exact UTC midnight keeps its date west of UTC")
    d = Dates_ymdOf("2026-11-21", 9 * 3600)
    t_ok(d.d = 21, "date only keeps its date")
    d = Dates_ymdOf("2026-12-31T23:30:00Z", 3600)
    t_ok(d.y = 2027 and d.m = 1 and d.d = 1, "across New Year")
end sub

sub test_airLabelLocal()
    today = { y: 2026, m: 11, d: 19 }
    t_eq(Dates_airLabel("2026-11-20T22:00:00.0000000Z", today, false, 7200), "Sat 21 Nov", "UTC+2 server and Roku: not Tomorrow")
    t_eq(Dates_airLabel("2026-11-19T22:00:00.0000000Z", today, false, 7200), "Tomorrow", "UTC+2: tomorrow, not today")
    t_eq(Dates_airLabel("2026-11-20T00:00:00Z", today, false, 7200), "Tomorrow", "UTC midnight: date part as-is")
    t_eq(Dates_airLabel("2026-11-20T05:00:00Z", today, false, -8 * 3600), "Today", "05:00Z on a UTC-8 Roku")
end sub

sub test_airLabelNewYear()
    today = { y: 2026, m: 12, d: 30 }
    t_eq(Dates_airLabel("2027-01-02T00:00:00Z", today, false), "Sat 2 Jan", "across New Year, close: no year")
    t_eq(Dates_airLabel("2026-12-31T00:00:00Z", today, false), "Tomorrow", "New Year's Eve")
    t_eq(Dates_airLabel("2027-12-30T00:00:00Z", today, false), "Thu 30 Dec 2027", "a year off: with the year")
end sub

sub test_civilAndUtc()
    for each n in [0, 59, 60, 11016, 11017, 20412, -1]
        c = Dates_civilFromDays(n)
        t_eq(Dates_daysFrom1970(c.y, c.m, c.d), n, "round trip " + n.toStr())
    end for
    t_eq(Dates_utcSecsOf("1970-01-02T00:00:00Z"), 86400#, "one day")
    t_eq(Dates_utcSecsOf("1970-01-01T02:00:00+02:00"), 0#, "offset")
    t_eq(Dates_utcSecsOf("1970-01-01T00:00:01.9999999Z"), 1#, "fraction ignored")
    t_ok(Dates_utcSecsOf("soon") = invalid, "not a date")
end sub
