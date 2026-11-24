' QuickPlay.previewFromFields / episodeNameOf (source/QuickPlay.bs): the instant details header (v1.2 SP-12)
sub test_episodeNameOf()
    t_eq(QuickPlay_episodeNameOf("S1:E2  ·  Pilot"), "Pilot", "number and name")
    t_eq(QuickPlay_episodeNameOf("S1:E2"), "", "number only")
    t_eq(QuickPlay_episodeNameOf("S3"), "", "season only")
    t_eq(QuickPlay_episodeNameOf("Pilot"), "Pilot", "name only")
    t_eq(QuickPlay_episodeNameOf(""), "", "empty")
end sub

sub test_previewMovie()
    f = { itemId: "m1", itemType: "Movie", title: "Alien", backdrop: "b", logo: "l", overview: "In space.", heroMeta: "Movie  ·  Horror  ·  1979", meta: "1979", played: true }
    p = QuickPlay_previewFromFields(f, true)
    t_eq(p.itemType, "Movie", "type")
    t_eq(p.title, "Alien", "title")
    t_eq(p.eyebrow, "", "no eyebrow")
    t_eq(p.backdrop, "b", "backdrop")
    t_eq(p.logo, "l", "logo")
    t_eq(p.overview, "In space.", "overview")
    t_eq(p.meta, "Movie  ·  Horror  ·  1979", "hero meta line")
    t_ok(p.played, "played")
    t_ok(p.full, "full list")
end sub

sub test_previewEpisode()
    f = { itemId: "e1", itemType: "Episode", title: "Frasier", chip: "S4, E2", episode: "S4:E2  ·  The Trip", logo: "series-logo", meta: "x" }
    p = QuickPlay_previewFromFields(f, false)
    t_eq(p.eyebrow, "Frasier  ·  S4, E2", "series and number above")
    t_eq(p.title, "The Trip", "the episode's own title")
    t_eq(p.logo, "", "episodes show no logo")
    t_eq(p.meta, "x", "meta when there is no hero meta")
    t_ok(not p.played, "missing played reads as false")
    t_ok(not p.full, "slim list")
    ' (v1.5 details) the series' logo and name, and "S4:E2 - The Trip" under them
    t_eq(p.seriesLogo, "series-logo", "series logo kept for the details header")
    t_eq(p.seriesName, "Frasier", "series name")
    t_eq(p.epLine, "S4:E2 - The Trip", "episode line")
end sub

sub test_previewArtAndProgress()
    f = { itemId: "e1", itemType: "Episode", title: "Frasier", episode: "S4:E2  ·  The Trip", hdPosterUrl: "still", landscape: true, progress: 0.4 }
    p = QuickPlay_previewFromFields(f, true)
    t_eq(p.image, "still", "the card's picture")
    t_ok(p.imageWide, "wide card")
    t_ok(p.progress > 0.39 and p.progress < 0.41, "progress")
    mv = QuickPlay_previewFromFields({ itemId: "m1", itemType: "Movie", title: "Alien" }, true)
    t_eq(mv.image, "", "no picture")
    t_ok(not mv.imageWide, "not wide")
    t_eq(mv.progress, 0, "no progress")
end sub

sub test_previewNotATitle()
    t_ok(QuickPlay_previewFromFields(invalid, true) = invalid, "nothing")
    t_ok(QuickPlay_previewFromFields({ itemId: "p", itemType: "Person", title: "x" }, true) = invalid, "a person")
    t_ok(QuickPlay_previewFromFields({ itemId: "", itemType: "Movie" }, true) = invalid, "no id")
    t_ok(QuickPlay_previewOfCard(invalid, true) = invalid, "no card")
    t_ok(QuickPlay_seriesPreviewOfCard({ itemId: "1" }) = invalid, "not a node")
end sub
