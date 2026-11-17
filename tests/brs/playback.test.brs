' Playback (source/Playback.bs): how the access token goes with stream and trickplay URLs.
' Jellyfin 12 accepts only the Authorization header and ?ApiKey=; Emby keeps ?api_key=.

function pb_jelly() as object
    return { id: "j1", type: "jellyfin", url: "http://jf.lan:8096", token: "TOKJ", userId: "u1" }
end function

function pb_emby() as object
    return { id: "e1", type: "emby", url: "http://emby.lan:8096", token: "TOKE", userId: "u2" }
end function

function pb_opts() as object
    return { audio: -1, sub: -1, burn: false, maxBitrate: 0, defaultAudio: -1, sourceId: "" }
end function

function pb_info(transcodingUrl as string, direct as boolean) as object
    return {
        PlaySessionId: "ps1",
        MediaSources: [{ Id: "src1", Container: "mkv", SupportsDirectPlay: direct, TranscodingUrl: transcodingUrl, MediaStreams: [{ Type: "Video", Codec: "h264" }] }]
    }
end function

sub test_tokenParam()
    t_eq(Playback_tokenParam(pb_jelly()), "ApiKey=TOKJ", "Jellyfin: ApiKey")
    t_eq(Playback_tokenParam(pb_emby()), "api_key=TOKE", "Emby: api_key")
end sub

sub test_videoHeaders()
    h = Playback_videoHeaders(pb_jelly(), "http://jf.lan:8096/Videos/1/stream")
    t_eq(h.count(), 1, "Jellyfin: one header")
    t_ok(h[0].startsWith("Authorization:MediaBrowser "), "Jellyfin: Authorization MediaBrowser scheme")
    t_ok(h[0].instr("Token=" + chr(34) + "TOKJ" + chr(34)) > 0, "Jellyfin: token in the header")
    t_ok(h[0].instr("X-Emby") < 0, "no legacy header")
    t_eq(Playback_videoHeaders(pb_emby(), "http://emby.lan:8096/Videos/1/stream").count(), 0, "Emby: none")
    t_eq(Playback_videoHeaders(pb_jelly(), "http://other.host/x.m3u8").count(), 0, "another host: none")
    srv = pb_jelly()
    srv.token = ""
    t_eq(Playback_videoHeaders(srv, "http://jf.lan:8096/x").count(), 0, "no token: none")
end sub

sub test_directPlayJellyfin()
    s = Playback_streamFrom(pb_jelly(), "it1", pb_info("", true), false, pb_opts())
    t_eq(s.method, "DirectPlay", "direct play")
    t_ok(LCase(s.url).instr("api_key") < 0 and LCase(s.url).instr("apikey") < 0, "no token in the URL")
    t_ok(s.url.instr("TOKJ") < 0, "token not in the URL")
    t_eq(s.headers.count(), 1, "sign-in header")
    t_ok(s.headers[0].instr("TOKJ") > 0, "header carries the token")
end sub

sub test_directPlayEmby()
    s = Playback_streamFrom(pb_emby(), "it1", pb_info("", true), false, pb_opts())
    t_eq(s.method, "DirectPlay", "direct play")
    t_ok(s.url.instr("&api_key=TOKE") > 0, "Emby keeps api_key")
    t_eq(s.headers.count(), 0, "no headers for Emby")
end sub

sub test_transcodeJellyfin()
    ' the server's own URL already has ApiKey: nothing is added
    s = Playback_streamFrom(pb_jelly(), "it1", pb_info("/videos/it1/master.m3u8?MediaSourceId=src1&ApiKey=TOKJ", false), false, pb_opts())
    t_eq(s.streamFormat, "hls", "hls")
    t_eq(s.url.split("TOKJ").count(), 2, "token once")
    t_eq(s.headers.count(), 1, "header too")
    ' an old server without a key in it: ApiKey is added, not api_key
    s = Playback_streamFrom(pb_jelly(), "it1", pb_info("/videos/it1/master.m3u8?MediaSourceId=src1", false), false, pb_opts())
    t_ok(s.url.instr("&ApiKey=TOKJ") > 0, "ApiKey added")
    t_ok(s.url.instr("api_key") < 0, "no api_key")
    ' another host gets nothing
    s = Playback_streamFrom(pb_jelly(), "it1", pb_info("http://cdn.example/videos/it1/master.m3u8?a=1", false), false, pb_opts())
    t_ok(s.url.instr("TOKJ") < 0, "no token to another host")
    t_eq(s.headers.count(), 0, "no header to another host")
end sub

sub test_transcodeEmby()
    s = Playback_streamFrom(pb_emby(), "it1", pb_info("/videos/it1/master.m3u8?MediaSourceId=src1", false), false, pb_opts())
    t_ok(s.url.instr("&api_key=TOKE") > 0, "api_key added")
    t_eq(s.headers.count(), 0, "no headers")
end sub

sub test_trickplayJellyfin()
    item = { Id: "it1", Trickplay: { src1: { "320": { Width: 320, Height: 180, TileWidth: 10, TileHeight: 10, ThumbnailCount: 50, Interval: 10000 } } } }
    tp = Playback_trickplayInfo(pb_jelly(), item, "src1")
    t_eq(tp.url, "http://jf.lan:8096/Videos/it1/Trickplay/320/", "tile base")
    t_eq(tp.query, ".jpg?MediaSourceId=src1&ApiKey=TOKJ", "ApiKey for the Poster")
end sub
