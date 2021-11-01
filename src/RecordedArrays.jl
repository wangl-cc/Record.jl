module RecordedArrays

using RecipesBase
using ResizingTools
using ResizingTools: AbstractRDArray, to_parentinds
using FunctionIndices
using ArrayInterface
using Static

# Clock
export DiscreteClock, ContinuousClock
export currenttime, limit, start, init!, increase!

# Entry
export StaticEntry, DynamicEntry
export store!, del!, getts, getvs, tspan
export LinearSearch, BinarySearch, gettime, gettime!

# utils
export MCIndices, DOKSparseArray

# extra (Size from ResizingTools, not from FunctionIndices)
export Size, not

# Record
export Record, ScalarRecord, VectorRecord, DOKRecord

# RNumber, RArray
export RArray, RNumber, RReal
export recorded, getentries, state
export isnum, issubtype

include("clock.jl")

include("utils.jl")

include("entry.jl")

include("record.jl")

include("rnumber.jl")

include("rarray.jl")

end
