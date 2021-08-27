"""
    DynamicRArray{V,T,N} <: AbstractRecord{V,T,N}

Recorded array whose elements change overtime can be created by
`DynamicRArray(t::AbstractClock, xs...)` where `xs` are abstract arrays or
numbers (or called scalar) to be recorded.

Implemented dynamic arrays:
* `DynamicRScalar`
* `DynamicRVector`

!!! note

    For a recorded dynamical scalar `S`, use `S[1] = v` to change its value
    instead of `S = v`.

# Examples
```jldoctest
julia> c = DiscreteClock(3);


julia> s, v = DynamicRArray(c, 0, [0, 1]);


julia> s # scalar
0-dimensional DynamicRScalar{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
0

julia> v # vector
2-element DynamicRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 0
 1

julia> for epoch in c
           s[1] += 1
           v[1] += 1
       end


julia> s
0-dimensional DynamicRScalar{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
3

julia> v
2-element DynamicRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 3
 1

julia> record(s)[1]
Record Entry
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4-element Vector{Int64}:
 0
 1
 2
 3

julia> record(v)[1]
Record Entry
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4-element Vector{Int64}:
 0
 1
 2
 3

julia> record(v)[2]
Record Entry
t: 1-element Vector{Int64}:
 0
v: 1-element Vector{Int64}:
 1
```
"""
abstract type DynamicRArray{V,T,N} <: AbstractRArray{V,T,N} end
DynamicRArray(t::AbstractClock, xs...) = map(x -> DynamicRArray(t, x), xs)
DynamicRArray{V}(t::AbstractClock, x) where {V} = DynamicRArray(t, convert_array(V, x))
DynamicRArray{V}(t::AbstractClock, xs...) where {V} = map(x -> DynamicRArray{V}(t, x), xs)
