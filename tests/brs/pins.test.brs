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
    ' (v0.9.0: 16 salt + 64 hash characters; a later format may add a prefix)
    t_ok(p.len() >= 80 and p.len() <= 96, "salt + hash length, got " + p.len().toStr())
    t_ok(Pins_matches(p, "srv", "user", "2468"), "right PIN")
    t_ok(not Pins_matches(p, "srv", "user", "2469"), "wrong PIN")
    t_ok(not Pins_matches(p, "srv", "other", "2468"), "other user")
    t_ok(not Pins_matches(p, "other", "user", "2468"), "other server")
    t_ok(not Pins_matches("", "srv", "user", "2468"), "no PIN set")
    t_ok(not Pins_matches(p, "srv", "user", "abcd"), "not a PIN")
    q = Pins_make("srv", "user", "2468")
    t_ok(p <> q, "a new salt each time")
end sub

' A PIN saved by v0.9.0 (salt + one SHA-256 round) must keep working after updates
sub test_v090_hash_still_matches()
    salt = "0123456789abcdef"
    stored = salt + Pins_digest(salt, "srv", "user", "2468")
    t_eq(stored.len(), 80, "v0.9.0 length")
    t_ok(Pins_matches(stored, "srv", "user", "2468"), "right PIN")
    t_ok(not Pins_matches(stored, "srv", "user", "1357"), "wrong PIN")
end sub
