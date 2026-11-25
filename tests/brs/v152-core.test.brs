' v1.5.2 core fixes (review 5 CS-n / ST-n): the pure helpers

sub test_cs1_effectiveAdmin()
    t_ok(MissingArt_effectiveAdmin(true, { url: "http://a", maxRating: "" }), "admin, no limit")
    t_ok(not MissingArt_effectiveAdmin(true, { url: "http://a", maxRating: "PG" }), "admin under PG is not an admin")
    t_ok(not MissingArt_effectiveAdmin(false, { maxRating: "" }), "not an admin")
    t_ok(not MissingArt_effectiveAdmin(true, invalid), "no server")
    t_ok(MissingArt_effectiveAdmin(true, { url: "http://a" }), "no maxRating field")
    t_ok(Ratings_effectiveAdmin({ maxRating: "" }, true), "Ratings: admin, no limit")
    t_ok(not Ratings_effectiveAdmin({ maxRating: "R" }, true), "Ratings: admin under R")
    t_ok(not Ratings_effectiveAdmin({ maxRating: "G" }, false), "Ratings: not admin")
    t_ok(not Ratings_effectiveAdmin(invalid, true), "Ratings: no server")
end sub

sub test_cs1_keepAllowed()
    rows = [{ id: "a", name: "A" }, { id: "b", name: "B" }, { id: "c", name: "C" }]
    kept = MissingArt_keepAllowed(rows, [{ Id: "c" }, { Id: "a" }, "junk"])
    t_eq(kept.count(), 2, "two allowed")
    t_eq(kept[0].id, "a", "order of the rows kept")
    t_eq(kept[1].id, "c", "second")
    t_eq(MissingArt_keepAllowed(rows, invalid).count(), 0, "no allowed list: nothing")
    t_eq(MissingArt_keepAllowed(invalid, []).count(), 0, "no rows")
    srv = { id: "s1", maxRating: "PG" }
    items = [{ Id: "a", Type: "Movie", OfficialRating: "R" }, { Id: "b", Type: "Movie", OfficialRating: "G" }]
    kept = MissingArt_keepAllowed([{ id: "a" }, { id: "b" }], Ratings_keep(srv, items))
    t_eq(kept.count(), 1, "R dropped under PG")
    t_eq(kept[0].id, "b", "G kept")
    t_ok(MissingArt_scanPath("u", "l", 0, 300).instr("OfficialRating") > 0, "scan asks for the rating")
end sub

sub test_cs2_postOutcome()
    t_eq(MissingArt_postOutcome(204), "ok", "204")
    t_eq(MissingArt_postOutcome(200), "ok", "200")
    t_eq(MissingArt_postOutcome(401), "refused", "401")
    t_eq(MissingArt_postOutcome(403), "refused", "403")
    t_eq(MissingArt_postOutcome(500), "failed", "500")
    t_eq(MissingArt_postOutcome(-1), "failed", "no answer")
    t_eq(MissingArt_postOutcome(invalid), "failed", "invalid")
    t_eq(MissingArt_refusedText(403), "The server refused the refresh (403)", "toast")
end sub
