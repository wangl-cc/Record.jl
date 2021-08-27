module RecordedArrays

using RecipesBase

export DiscreteClock, ContinuousClock, currenttime, limit, start, init!, increase! # clock
export DynamicRArray, StaticRArray, state, setclock # rarray
export DynamicRScalar, DynamicRVector 
export StaticRVector
export record, gettime, selectrecs, T0 # record and common
export tspan, getts, getvs, toseries, unione, gettime! # entry
export LinearSearch, BinarySearch # search methods

include("clock.jl")

include("utils.jl")

include("abstract.jl")

include("entry.jl")

include("record.jl")

include("selectrecs.jl")

include("math.jl")

include("dynamic/abstract.jl")

include("dynamic/scalar.jl")

include("dynamic/vector.jl")

include("dynamic/array.jl")

include("static/abstract.jl")

include("static/vector.jl")

end
# vim:tw=92:ts=4:sw=4:et
