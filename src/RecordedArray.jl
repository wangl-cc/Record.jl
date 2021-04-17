module RecordedArray

export DiscreteClock, ContinuousClock, now, limit, init!, increase!
export DynamicRArray, StaticRArray, state
export records, tspan, ts, vs, toseries, getstate_bytime

include("utilities.jl")

include("clock.jl")

include("abstract.jl")

include("records.jl")

include("math.jl")

include("dynamic.jl")

include("static.jl")

end
# vim:tw=92:ts=4:sw=4:et
