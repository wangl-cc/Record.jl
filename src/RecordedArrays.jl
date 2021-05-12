module RecordedArrays

export DiscreteClock, ContinuousClock, now, limit, init!, increase!
export DynamicRArray, StaticRArray, state
export records, tspan, ts, vs, toseries, gettime, unione
export State, value, update!, plus!

include("utilities.jl")

include("clock.jl")

include("abstract.jl")

include("records.jl")

include("math.jl")

include("dynamic.jl")

include("static.jl")

end
# vim:tw=92:ts=4:sw=4:et
