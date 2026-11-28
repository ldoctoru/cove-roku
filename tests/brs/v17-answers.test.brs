' v1.7 answers (Liviu): opening a title from New marks it read; Theme Music is per profile
sub test_withoutId()
    t_eq(Live_withoutId(["a", "b", "c"], "b").count(), 2, "one id removed")
    t_eq(Live_withoutId(["a", "b"], "b")[0], "a", "the others kept in order")
    t_eq(Live_withoutId(["a"], "z").count(), 1, "an unknown id changes nothing")
    t_eq(Live_withoutId(invalid, "a").count(), 0, "no list gives an empty one")
end sub

sub test_themeMusicPersonal()
    t_ok(PrefScope_isPersonal("themeMusic"), "Theme Music is a personal setting")
    t_ok(PrefScope_isPersonal("becauseRows"), "Because You Watched rows stay personal")
end sub
