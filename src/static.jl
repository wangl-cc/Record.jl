"""
    StaticRArray{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements never change but insert
or delete.
"""
abstract type StaticRArray{V,T,N} <: AbstractRArray{V,T,N} end
function StaticRArray(t::AbstractClock, x1, x2)
    return StaticRArray(t, x1), StaticRArray(t, x2)
end
function StaticRArray(t::AbstractClock, x1, x2, xs...)
    return StaticRArray(t, x1), StaticRArray(t, x2, xs...)::Tuple...
end

"""
    StaticRVector{V,T,C<:AbstractClock{T}, I} <: StaticRArray{V,T,1}

Implementation of recorded static vector, created by
`StaticRArray(c::AbstractClock, v::AbstractVector)`.

# Examples

```jldoctest
julia> c = DiscreteClock(3);

julia> v = StaticRArray(c, [0, 1])
recorded 2-element Vector{Int64}:
 0
 1

julia> for epoch in c
           push!(v, epoch + 1)
       end

julia> v
recorded 5-element Vector{Int64}:
 0
 1
 2
 3
 4

julia> deleteat!(v, 1) # only delete current state
recorded 4-element Vector{Int64}:
 1
 2
 3
 4

julia> records(v)[5] # there are still 5 elements
Record Entries
t: 2-element Vector{Int64}:
 3
 3
v: 2-element Vector{Int64}:
 4
 4
```
"""
struct StaticRVector{V,T,C<:AbstractClock{T},I} <: StaticRArray{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    t::C
    s::Vector{T}
    e::Vector{T}
    indmax::State{I}
    indmap::Vector{I}
end
function StaticRArray(t::AbstractClock, v::AbstractVector)
    v = collect(v)
    n = length(v)
    s = fill(now(t), n)
    e = fill(limit(t), n)
    return StaticRVector(copy(v), copy(v), t, s, e, State(n), collect(1:n))
end

state(A::StaticRVector) = A.v

Base.length(A::StaticRVector) = value(A.indmax)
Base.size(A::StaticRVector) = (length(A),)
function Base.getindex(A::StaticRVector, i::Integer)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    return A.v[i]
end

function Base.push!(r::StaticRVector, v)
    push!(r.v, v)
    push!(r.v_all, v)
    ind = plus!(r.indmax, true)
    push!(r.indmap, ind)
    push!(r.s, now(r.t))
    push!(r.e, limit(r.t))
    return r
end

function Base.deleteat!(r::StaticRVector, i::Integer)
    deleteat!(r.v, i)
    ind = r.indmap[i]
    r.e[ind] = now(r.t)
    deleteat!(r.indmap, i)
    return r
end

function Base.getindex(r::Records{<:StaticRVector}, i::Integer)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    return SingleEntries([A.s[i], A.e[i]], [A.v_all[i], A.v_all[i]])
end
# vim:tw=92:ts=4:sw=4:et
