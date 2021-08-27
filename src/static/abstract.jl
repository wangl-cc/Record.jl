"""
    StaticRArray{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements never change but insert
or delete can  be created by `StaticRArray(t::AbstractClock, xs...)` where
`xs` are abstract arrays to be recorded.

Implemented statical arrays:
* `StaticRVector`

!!! note

    Elements of StaticRArray `A` can be delete by `deleteat!(A,i)`, whose value
    after deletion is 0.

# Examples
```jldoctest
julia> c = DiscreteClock(3);


julia> v = StaticRArray(c, [0, 1, 2])
3-element StaticRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 0
 1
 2

julia> for epoch in c
           push!(v, epoch+2) # push a element
           deleteat!(v, 1)   # delete a element
       end


julia> v # there are still three element now
3-element StaticRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 3
 4
 5

julia> record(v)[6] # but six element are recorded
Record Entry
t: 2-element Vector{Int64}:
 3
 3
v: 2-element Vector{Int64}:
 5
 5

julia> gettime(record(v)[1], 2)[1] # element after deletion is 0
0
```
"""
abstract type StaticRArray{V,T,N} <: AbstractRArray{V,T,N} end
StaticRArray(t::AbstractClock, xs...) = map(x -> StaticRArray(t, x), xs)
StaticRArray{V}(t::AbstractClock, x) where {V} = StaticRArray(t, convert_array(V, x))
StaticRArray{V}(t::AbstractClock, xs...) where {V} = map(x -> StaticRArray{V}(t, x), xs)
