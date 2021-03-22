module Record

export DynamicRecord, StaticRecord,
       Clock, current, limit, isend, notend, increase!,
       tspan, ts, xs

include("abstract.jl")

include("dynamic.jl")

include("static.jl")

end
