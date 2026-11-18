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
