module Record

export DynamicRecord, StaticRecord, record!,
       EleChange, PushChange, DelChange,
       tspan, ts, xs

include("abstract.jl")

include("dynamic.jl")

include("static.jl")

end
