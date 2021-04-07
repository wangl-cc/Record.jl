module RecordedArray

export Clock, now, limit, isend, notend, increase!
export DynamicRArray, StaticRArray, state
export getrecord, records, tspan, ts, vs, toplot

include("tools.jl")

include("abstract.jl")

include("view.jl")

include("math.jl")

include("dynamic.jl")

include("static.jl")

end
# vim:tw=92:ts=4:sw=4:et
