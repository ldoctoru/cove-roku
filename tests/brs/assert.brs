' Asserts for tests/run.js. Plain BrightScript (not compiled by bsc): the counters live in the global AA.
sub t_begin(file as string)
    g = GetGlobalAA()
    g.tFile = file
    g.tCase = ""
    g.tPass = 0
    g.tFail = 0
end sub

sub t_case(name as string)
    GetGlobalAA().tCase = name
    print "CASE "; name
end sub

sub t_end()
    g = GetGlobalAA()
    print "RESULT "; g.tPass.toStr(); " "; g.tFail.toStr()
end sub

function t_show(v as dynamic) as string
    if v = invalid then return "invalid"
    t = type(v)
    if t = "roString" or t = "String" then return chr(34) + v + chr(34)
    if t = "roArray" or t = "roAssociativeArray" then return FormatJson(v)
    if t = "roBoolean" or t = "Boolean"
        if v then return "true"
        return "false"
    end if
    return v.toStr()
end function

sub t_ok(cond as boolean, msg as string)
    g = GetGlobalAA()
    if cond
        g.tPass = g.tPass + 1
    else
        g.tFail = g.tFail + 1
        print "FAIL "; g.tCase; ": "; msg
    end if
end sub

' Equal values: scalars compare directly (Integer 3 = Float 3.0), arrays and AAs by their JSON
sub t_eq(actual as dynamic, expected as dynamic, msg as string)
    same = false
    ta = type(actual)
    te = type(expected)
    if actual = invalid or expected = invalid
        same = actual = invalid and expected = invalid
    else if ta = "roArray" or ta = "roAssociativeArray" or te = "roArray" or te = "roAssociativeArray"
        same = t_show(actual) = t_show(expected)
    else if (ta = "roString" or ta = "String") <> (te = "roString" or te = "String")
        same = false
    else
        same = actual = expected
    end if
    t_ok(same, msg + ": expected " + t_show(expected) + ", got " + t_show(actual))
end sub
