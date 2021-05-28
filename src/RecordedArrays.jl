module RecordedArrays

export DiscreteClock, ContinuousClock, now, limit, start, init!, increase!
export DynamicRArray, StaticRArray, state, setclock
export records, tspan, ts, vs, toseries, gettime, unione

include("clock.jl")

include("abstract.jl")

include("records.jl")

include("math.jl")

include("dynamic.jl")

include("static.jl")

end
# vim:tw=92:ts=4:sw=4:et
