' Api (source/Api.bs): the v1.1.1 timing line and route memory helpers
sub test_pathOf()
    t_eq(Api_pathOf("https://h.example:8096/emby/Items?api_key=SECRET&x=1"), "/emby/Items", "scheme, host and query dropped")
    t_eq(Api_pathOf("http://10.0.0.2:8096"), "/", "no path")
    t_eq(Api_pathOf("/Users/u1/Items/Resume?Limit=20"), "/Users/u1/Items/Resume", "a path alone")
end sub

sub test_timingLine()
    line = Api_timingLine("get", "https://h/Users/u1/Views?api_key=SECRET", 200, 143)
    t_eq(line, "http GET /Users/u1/Views 200 143", "method, path, code, ms")
    t_ok(line.instr("SECRET") < 0, "no query in the line")
    t_eq(Api_timingLine("POST", "https://h/Items/1/PlaybackInfo", -1, 15000), "http POST /Items/1/PlaybackInfo -1 15000", "network error")
end sub

sub test_routeKind()
    t_eq(Api_routeKind("/Users/abc/Items/Latest?ParentId=1"), "Items/Latest", "user id and query dropped")
    t_eq(Api_routeKind("/Users/abc/Views"), "Views", "views")
    t_eq(Api_routeKind("/Shows/NextUp?UserId=x"), "Shows/NextUp", "other route")
    t_eq(Api_routeKind("/Users/abc"), "Users", "the user itself")
end sub

sub test_routeKey()
    t_eq(Api_routeKey({ id: "0123456789abcdef" }, "trailers"), "0123456789ab:trailers", "server id cut to 12")
    t_eq(Api_routeKey(invalid, "intros"), ":intros", "no server")
end sub
