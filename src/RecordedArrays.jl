module RecordedArrays

using RecipesBase
using ResizingTools
using ResizingTools: AbstractRDArray, to_parentinds
using ArrayInterface
using Static

# Clock
export DiscreteClock, ContinuousClock
export currenttime, limit, start, init!, increase!

# utils
export Size, Indices

# Entry
export StaticEntry, DynamicEntry
export store!, del!, getts, getvs, tspan
export LinearSearch, BinarySearch, gettime, gettime!

# Record
export ScalarRecord, VectorRecord, DokRecord

# RArray
export recorded, RArray
export getrecord, getentries, state

include("clock.jl")

include("utils.jl")

include("entry.jl")

include("record.jl")

include("rnumber.jl")

include("rarray.jl")

end
