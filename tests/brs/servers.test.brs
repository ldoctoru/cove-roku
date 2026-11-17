' Servers (source/Servers.bs): discovery answers and profile roles

' (C2-9) a Jellyfin base URL is kept; anything that isn't a plain http(s) address is dropped
sub test_parseDiscovery()
    s = Servers_parseDiscovery("{""Address"":""http://192.168.1.20:8096"",""Id"":""abc123"",""Name"":""Home""}")
    t_ok(s <> invalid, "plain address")
    if s <> invalid then t_eq(s.address, "http://192.168.1.20:8096", "address")
    s = Servers_parseDiscovery("{""Address"":""http://192.168.1.20:8096/jellyfin/"",""Id"":""abc123"",""Name"":""Home""}")
    t_ok(s <> invalid, "base URL kept")
    if s <> invalid then t_eq(s.address, "http://192.168.1.20:8096/jellyfin", "trailing slash dropped")
    t_ok(Servers_parseDiscovery("{""Address"":""javascript:alert(1)"",""Id"":""abc""}") = invalid, "javascript: dropped")
    t_ok(Servers_parseDiscovery("{""Address"":""http://h/a b"",""Id"":""abc""}") = invalid, "space in path dropped")
    t_ok(Servers_parseDiscovery("{""Address"":""http://h"",""Id"":""a/b""}") = invalid, "unsafe id dropped")
    t_ok(Servers_parseDiscovery("not json") = invalid, "not JSON")
    t_ok(Servers_parseDiscovery(invalid) = invalid, "not a string")
    long = Servers_parseDiscovery("{""Address"":""http://h"",""Id"":""abc"",""Name"":""" + String(50, "n") + """}")
    if long <> invalid then t_eq(long.name.len(), 40, "name cut to 40")
    noName = Servers_parseDiscovery("{""Address"":""http://nas.local:8096"",""Id"":""abc""}")
    if noName <> invalid then t_eq(noName.name, "nas.local", "host as the name")
end sub

sub test_parents_and_limits()
    srv = { users: [{ i: "dad", p: "x" }, { i: "kid", r: "PG" }, { i: "mom" }] }
    t_eq(Servers_parentIds(srv), ["dad"], "one parent")
    t_ok(Servers_anyLimited(srv), "a limit exists")
    t_ok(Servers_isLastParent(srv, "dad"), "dad is the last parent")
    two = { users: [{ i: "dad", p: "x" }, { i: "mom", p: "y" }, { i: "kid", r: "PG" }] }
    t_ok(not Servers_isLastParent(two, "dad"), "two parents")
    t_ok(not Servers_anyLimited({ users: [{ i: "a" }] }), "no limits")
    t_ok(not Servers_anyLimited(invalid), "no server")
end sub
