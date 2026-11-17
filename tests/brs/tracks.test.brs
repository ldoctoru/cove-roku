' Tracks.capForcesEncode (source/Tracks.bs, PL-11)
function t_info() as object
    return { MediaSources: [{ Id: "a", Bitrate: 60000000 }, { Id: "b", Bitrate: 8000000 }] }
end function

sub test_capForcesEncode_auto()
    t_ok(not Tracks_capForcesEncode(t_info(), "", 0), "automatic quality")
end sub

sub test_capForcesEncode_below()
    t_ok(Tracks_capForcesEncode(t_info(), "", 20000000), "first file above the cap")
    t_ok(Tracks_capForcesEncode(t_info(), "a", 20000000), "chosen file above the cap")
end sub

sub test_capForcesEncode_within()
    t_ok(not Tracks_capForcesEncode(t_info(), "b", 20000000), "chosen file within the cap")
    t_ok(not Tracks_capForcesEncode(t_info(), "", 120000000), "cap above the file")
end sub

sub test_capForcesEncode_missing()
    t_ok(not Tracks_capForcesEncode(invalid, "", 20000000), "no answer")
    t_ok(not Tracks_capForcesEncode({ MediaSources: [] }, "", 20000000), "no files")
    t_ok(not Tracks_capForcesEncode({ MediaSources: [{ Id: "a" }] }, "", 20000000), "no bitrate")
end sub
