' Util (source/Util.bs): ids, redaction, addresses
sub test_isSafeId()
    t_ok(Util_isSafeId("a1b2c3", false), "hex")
    t_ok(Util_isSafeId("6f1c-42-AB", false), "dashes")
    t_ok(not Util_isSafeId("a/b", false), "slash")
    t_ok(not Util_isSafeId("../x", false), "dots")
    t_ok(not Util_isSafeId("a b", false), "space")
    t_ok(not Util_isSafeId("a?x=1", false), "query")
    t_ok(not Util_isSafeId(String(65, "a"), false), "65 characters")
    t_ok(Util_isSafeId(String(64, "a"), false), "64 characters")
    t_ok(not Util_isSafeId("", false), "empty, not allowed")
    t_ok(Util_isSafeId("", true), "empty, allowed")
    t_ok(Util_isSafeId(invalid, true), "invalid, allowed")
    t_ok(not Util_isSafeId(invalid, false), "invalid, not allowed")
    t_ok(not Util_isSafeId(42, true), "a number")
end sub

sub test_redact()
    t_eq(Util_redact("GET http://h:8096/Videos/1/stream?api_key=abc123&Static=true"), "GET http://h:8096/Videos/1/stream?api_key=***&Static=true", "api_key")
    t_eq(Util_redact("x?ApiKey=SECRET"), "x?ApiKey=***", "ApiKey, any case")
    t_eq(Util_redact("MediaBrowser Client=" + chr(34) + "Cove" + chr(34) + ", Token=" + chr(34) + "tok-1" + chr(34)), "MediaBrowser Client=" + chr(34) + "Cove" + chr(34) + ", Token=" + chr(34) + "***" + chr(34), "Token header")
    t_eq(Util_redact("X-Emby-Token: abc"), "X-Emby-Token: ***", "X-Emby-Token")
    t_eq(Util_redact("{" + chr(34) + "AccessToken" + chr(34) + ":" + chr(34) + "abc" + chr(34) + "}"), "{" + chr(34) + "AccessToken" + chr(34) + ":" + chr(34) + "***" + chr(34) + "}", "AccessToken JSON")
    t_eq(Util_redact("nothing secret"), "nothing secret", "unchanged")
    t_ok(Util_redact("a?api_key=SECRET1&b=2&api_key=SECRET2").instr("SECRET") < 0, "every occurrence")
end sub

sub test_originOf()
    t_eq(Util_originOf("https://Media.Example.com/emby"), "https://media.example.com:443", "https default port")
    t_eq(Util_originOf("http://192.168.1.5:8096/web/index.html"), "http://192.168.1.5:8096", "port kept")
    t_eq(Util_originOf("http://host"), "http://host:80", "http default port")
    t_eq(Util_originOf("http://user:pw@host:8920/x"), "http://host:8920", "credentials dropped")
    t_eq(Util_originOf("http://[fd00::1]:8096/"), "http://fd00::1:8096", "IPv6")
    t_ok(Util_originOf("https://host/") <> Util_originOf("http://host/"), "scheme counts")
end sub

sub test_hostOf()
    t_eq(Util_hostOf("https://EX.com:8920/a?b#c"), "ex.com", "host")
    t_eq(Util_hostOf("http://a@b@evil.com/x"), "evil.com", "last @ wins")
    t_eq(Util_hostOf("http://[FD00::1]:8096"), "fd00::1", "IPv6")
end sub

sub test_isPrivateHost()
    for each h in ["192.168.1.5", "10.0.0.2", "172.16.0.1", "172.31.255.255", "127.0.0.1", "100.64.0.1", "localhost", "nas", "nas.local", "box.home.arpa", "[fd00::1]", "::1"]
        t_ok(Util_isPrivateHost(h), h + " is private")
    end for
    for each h in ["8.8.8.8", "172.32.0.1", "100.128.0.1", "example.com", "134744072", "0x7f000001", "192.168.01.5", ""]
        t_ok(not Util_isPrivateHost(h), h + " is not private")
    end for
end sub

sub test_tokenSafeTarget()
    t_ok(Util_tokenSafeTarget("https://h", "/videos/1/master.m3u8"), "relative")
    t_ok(Util_tokenSafeTarget("https://h", "https://H/videos/1"), "same host")
    t_ok(not Util_tokenSafeTarget("https://h", "https://other/videos/1"), "other host")
    t_ok(not Util_tokenSafeTarget("https://h", "http://h/videos/1"), "https downgraded to http")
    t_ok(Util_tokenSafeTarget("http://h", "https://h/videos/1"), "http upgraded")
end sub

sub test_setQuery()
    t_eq(Util_setQuery("/a", "x", "1"), "/a?x=1", "first")
    t_eq(Util_setQuery("/a?x=1&y=2", "X", "3"), "/a?y=2&X=3", "replaced, any case")
end sub

sub test_toNumber_and_field()
    t_eq(Util_toNumber("12"), 12, "text")
    t_eq(Util_toNumber(invalid), 0, "invalid")
    t_eq(Util_field({ a: 1 }, "a"), 1, "field")
    t_eq(Util_field([1], "a"), invalid, "not an object")
    t_ok(not Util_flag({ a: "yes" }, "a"), "flag needs a boolean")
    t_ok(Util_flag({ a: true }, "a"), "flag true")
end sub
