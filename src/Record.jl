module Record

export DynamicRecord, StaticRecord, state,
       Clock, current, limit, isend, notend, increase!,
       getrecord, tspan, ts, vs

include("tools.jl")

include("view.jl")

include("abstract.jl")

include("dynamic.jl")

include("static.jl")

end
