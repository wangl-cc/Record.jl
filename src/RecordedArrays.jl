module RecordedArrays

using RecipesBase

# Clock
export DiscreteClock, ContinuousClock
export currenttime, limit, start, init!, increase!

# utils
export Size, IndexMap

# Entry
export StaticEntry, DynamicEntry
export store!, del!, getts, getvs, tspan
export LinearSearch, BinarySearch, gettime, gettime!

# Record
export ScalarRecord, VectorRecord, DokRecord
export selectrecs, T0

# RArray
export RScalar, RVector, RArray
export rarray, record, state
export pushdim!, deletedim!

include("clock.jl")

include("utils.jl")

include("entry.jl")

include("record.jl")

include("selectrecs.jl")

include("rarray.jl")

end
# vim:tw=92:ts=4:sw=4:et
