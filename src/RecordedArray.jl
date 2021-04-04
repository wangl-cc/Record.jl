module RecordedArray

export DynamicRArray, StaticRArray,
       state,
       Clock, now, limit, isend, notend, increase!,
       getrecord,
       records, tspan, ts, vs, toplot

include("tools.jl")

include("abstract.jl")

include("view.jl")

include("math.jl")

include("dynamic.jl")

include("static.jl")

end
