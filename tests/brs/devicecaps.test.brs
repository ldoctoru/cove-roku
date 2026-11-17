' DeviceCaps.hevcConditions (source/DeviceCaps.bs, PL-12)
function t_caps(extra as object) as object
    c = { hevc: true, hevc4k: true, hevc10: true, hdr10: true, hlg: true, dolbyVision: true }
    c.append(extra)
    return c
end function

function t_ranges(conds as object) as string
    out = []
    for each c in conds
        if c.Property = "VideoRangeType" then out.push(c.Value)
    end for
    return out.join(",")
end function

function t_props(conds as object) as string
    out = []
    for each c in conds
        out.push(c.Property + " " + c.Condition + " " + c.Value)
    end for
    return out.join("|")
end function

sub test_hevcConditions_full()
    t_eq(DeviceCaps_hevcConditions(t_caps({}), true).count(), 0, "4K Main 10 with every HDR: no conditions")
end sub

sub test_hevcConditions_noHevc()
    t_eq(DeviceCaps_hevcConditions(t_caps({ hevc: false }), true).count(), 0, "no HEVC: no HEVC profile")
end sub

sub test_hevcConditions_hd()
    t_eq(t_props(DeviceCaps_hevcConditions(t_caps({ hevc4k: false, hevc10: false }), false)), "VideoBitDepth LessThanEqual 8|Width LessThanEqual 1920", "1080p-only 8-bit decoder")
end sub

sub test_hevcConditions_sdrTv()
    c = t_caps({ hdr10: false, hlg: false, dolbyVision: false })
    t_eq(t_ranges(DeviceCaps_hevcConditions(c, true)), "DOVI,HDR10,HDR10Plus,DOVIWithHDR10,DOVIWithHDR10Plus,HLG,DOVIWithHLG", "SDR TV on Jellyfin")
    t_eq(DeviceCaps_hevcConditions(c, false).count(), 0, "Emby: no range types sent")
end sub

sub test_hevcConditions_hdr10NoDv()
    t_eq(t_ranges(DeviceCaps_hevcConditions(t_caps({ dolbyVision: false }), true)), "DOVI", "HDR10 + HLG TV without DV: DV-only files converted")
end sub

sub test_hevcConditions_dvNoHdr10()
    t_eq(t_ranges(DeviceCaps_hevcConditions(t_caps({ hdr10: false, hlg: false }), true)), "HDR10,HDR10Plus,HLG", "DV TV: DV files with a base layer still play")
end sub
