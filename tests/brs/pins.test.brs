' Pins (source/Pins.bs): profile PIN hashing (roEVPDigest is Node's sha256 here, see tests/brs-mocks.js)
sub test_isValid()
    t_ok(Pins_isValid("0000"), "4 digits")
    t_ok(not Pins_isValid("123"), "3 digits")
    t_ok(not Pins_isValid("12345"), "5 digits")
    t_ok(not Pins_isValid("12a4"), "a letter")
    t_ok(not Pins_isValid(""), "empty")
end sub

sub test_digest_isSha256()
    ' sha256("salt:s:u:1234")
    t_eq(Pins_digest("salt", "s", "u", "1234"), "e50dd3909207e24e95de4f59830967626f19fc973a1ed3d2ac8b06cb121e0d2d", "known hash")
end sub

sub test_make_and_matches()
    p = Pins_make("srv", "user", "2468")
    t_eq(p.len(), 80, "16 salt + 64 hash characters")
    t_ok(Pins_matches(p, "srv", "user", "2468"), "right PIN")
    t_ok(not Pins_matches(p, "srv", "user", "2469"), "wrong PIN")
    t_ok(not Pins_matches(p, "srv", "other", "2468"), "other user")
    t_ok(not Pins_matches(p, "other", "user", "2468"), "other server")
    t_ok(not Pins_matches("", "srv", "user", "2468"), "no PIN set")
    t_ok(not Pins_matches(p, "srv", "user", "abcd"), "not a PIN")
    q = Pins_make("srv", "user", "2468")
    t_ok(p <> q, "a new salt each time")
end sub
