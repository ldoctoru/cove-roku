' Ratings (source/Ratings.bs): the kids limit
sub test_levelOf_scale()
    t_eq(Ratings_levelOf(""), 0, "empty")
    t_eq(Ratings_levelOf("G"), 1, "G")
    t_eq(Ratings_levelOf("TV-Y7"), 2, "TV-Y7")
    t_eq(Ratings_levelOf("PG-13"), 3, "PG-13")
    t_eq(Ratings_levelOf("R"), 4, "R")
    t_eq(Ratings_levelOf("TV-MA"), 4, "TV-MA")
    t_eq(Ratings_levelOf("NC-17"), 5, "NC-17")
end sub

sub test_levelOf_spelling()
    t_eq(Ratings_levelOf(" pg-13 "), 3, "lower case with spaces")
    t_eq(Ratings_levelOf("PG 13"), 3, "space for dash")
    t_eq(Ratings_levelOf("tv-14"), 3, "tv-14")
end sub

sub test_levelOf_countryPrefix()
    t_eq(Ratings_levelOf("US/PG-13"), 3, "US/PG-13")
    t_eq(Ratings_levelOf("DE-12"), 3, "DE-12")
    t_eq(Ratings_levelOf("FSK-16"), 4, "FSK-16")
    t_eq(Ratings_levelOf("GB-18"), 5, "GB-18")
end sub

sub test_levelOf_unknown()
    t_eq(Ratings_levelOf("Not Rated"), 0, "Not Rated")
    t_eq(Ratings_levelOf("XYZ"), 0, "unknown")
end sub

sub test_limitOf()
    t_eq(Ratings_limitOf(invalid), 0, "no server")
    t_eq(Ratings_limitOf({}), 0, "no maxRating")
    t_eq(Ratings_limitOf({ maxRating: "" }), 0, "off")
    t_eq(Ratings_limitOf({ maxRating: "PG" }), 2, "PG")
end sub

sub test_allowed()
    kid = { maxRating: "PG" }
    t_ok(Ratings_allowed(kid, { OfficialRating: "G" }), "G under PG")
    t_ok(Ratings_allowed(kid, { OfficialRating: "PG" }), "PG at PG")
    t_ok(not Ratings_allowed(kid, { OfficialRating: "PG-13" }), "PG-13 over PG")
    t_ok(not Ratings_allowed(kid, { OfficialRating: "TV-MA" }), "TV-MA over PG")
    t_ok(Ratings_allowed({ maxRating: "" }, { OfficialRating: "R" }), "no limit")
    t_ok(Ratings_allowed(kid, "not an object"), "not an item")
end sub

sub test_keep()
    kid = { maxRating: "PG-13" }
    list = [{ Name: "a", OfficialRating: "PG" }, { Name: "b", OfficialRating: "R" }, { Name: "c", OfficialRating: "TV-14" }]
    names = []
    for each it in Ratings_keep(kid, list)
        names.push(it.Name)
    end for
    t_ok(names.count() >= 2, "PG and TV-14 kept")
    t_eq(names[0], "a", "first kept")
    t_ok(names.count() < 3 or names[2] <> "b", "R dropped")
    t_eq(Ratings_keep({ maxRating: "" }, list).count(), 3, "no limit keeps all")
    t_eq(Ratings_keep(kid, invalid), [], "not a list")
end sub

sub test_withLimit()
    t_eq(Ratings_withLimit({ maxRating: "" }, "/Items?x=1"), "/Items?x=1", "no limit: unchanged")
    t_eq(Ratings_withLimit({ maxRating: "PG-13" }, "/Items?x=1"), "/Items?x=1&MaxOfficialRating=PG-13", "limit added")
    t_eq(Ratings_withLimit({ maxRating: "PG" }, "/Items"), "/Items?MaxOfficialRating=PG", "first parameter")
    t_eq(Ratings_withLimit({ maxRating: "PG" }, ""), "", "empty path")
end sub

' (C2-3) ratings with "+", spaces after the system and Korean / Japanese / Russian / Australian spellings
sub test_levelOf_plusAndAges()
    t_eq(Ratings_levelOf("18+"), 5, "18+")
    t_eq(Ratings_levelOf("16+"), 4, "16+")
    t_eq(Ratings_levelOf("12+"), 3, "12+")
    t_eq(Ratings_levelOf("6+"), 2, "6+")
    t_eq(Ratings_levelOf("0+"), 1, "0+")
    t_eq(Ratings_levelOf("RU-18+"), 5, "RU-18+")
    t_eq(Ratings_levelOf("RU-12+"), 3, "RU-12+")
    t_eq(Ratings_levelOf("AU-MA 15+"), 4, "AU-MA 15+")
    t_eq(Ratings_levelOf("MA 15+"), 4, "MA 15+")
    t_eq(Ratings_levelOf("MA15+"), 4, "MA15+")
    t_eq(Ratings_levelOf("AU-R 18+"), 5, "AU-R 18+")
    t_eq(Ratings_levelOf("R18+"), 5, "R18+")
    t_eq(Ratings_levelOf("JP-R15+"), 4, "JP-R15+")
    t_eq(Ratings_levelOf("R15+"), 4, "R15+")
    t_eq(Ratings_levelOf("KR-19"), 5, "KR-19")
    t_eq(Ratings_levelOf("19"), 5, "19")
    t_eq(Ratings_levelOf("DE-FSK 16"), 4, "DE-FSK 16")
    t_eq(Ratings_levelOf("+"), 0, "a lone plus")
    t_eq(Ratings_levelOf("Not Rated+"), 0, "unknown with plus")
end sub

sub test_allowed_plus()
    kid = { maxRating: "PG" }
    t_ok(not Ratings_allowed(kid, { OfficialRating: "18+" }), "18+ over PG")
    t_ok(not Ratings_allowed(kid, { OfficialRating: "KR-19" }), "KR-19 over PG")
    t_ok(Ratings_allowed(kid, { OfficialRating: "6+" }), "6+ under PG")
end sub
