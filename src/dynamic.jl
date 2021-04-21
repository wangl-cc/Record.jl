"""
    DynamicRArray{V,T,N} <: AbstractRecord{V,T,N}

Recorded arrays whose elements change overtime.
"""
abstract type DynamicRArray{V,T,N} <: AbstractRArray{V,T,N} end
function DynamicRArray(t::AbstractClock, x1, x2)
    return DynamicRArray(t, x1), DynamicRArray(t, x2)
end
function DynamicRArray(t::AbstractClock, x1, x2, xs...)
    return DynamicRArray(t, x1), DynamicRArray(t, x2, xs...)::Tuple...
end

"""
    DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRScalar{V,T,0}

Implementation of recorded scaler, created by `DynamicRArray(t::AbstractClock, v::Number)`.
Use `S[1] = v` to change its value instead of `S = v`.

Examples
≡≡≡≡≡≡≡≡≡≡
```jldoctest
julia> c = DiscreteClock(3);

julia> s = DynamicRArray(c, 0)
recorded 0

julia> for epoch in c
           s[1] += 1
       end

julia> s
recorded 3

julia> records(s)[1]
Record Entries
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
```
"""
struct DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRArray{V,T,0}
    v::State{V}
    t::C
    vs::Vector{V}
    ts::Vector{T}
end
function DynamicRArray(t::AbstractClock, v::Number)
    return DynamicRScalar(State(v), t, [v], [now(t)])
end

state(A::DynamicRScalar) = value(A.v)

Base.length(::DynamicRScalar) = 1
Base.size(::DynamicRScalar) = (1,)
function Base.getindex(A::DynamicRScalar, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(A, i))
    return value(A.v)
end
function Base.setindex!(A::DynamicRScalar, v, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(A, i))
    update!(A.v, v)
    push!(A.vs, v)
    push!(A.ts, now(A.t))
    return A
end

function Base.getindex(r::Records{<:DynamicRScalar}, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    A = r.array
    return SingleEntries(A.ts, A.vs)
end

"""
    DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}

Implementation of recorded dynamics vector, created by
`DynamicRArray(c::AbstractClock, v::AbstractVector)`


Examples
≡≡≡≡≡≡≡≡≡≡
```jldoctest
julia> c = DiscreteClock(3);

julia> v = DynamicRArray(c, [0, 1])
recorded 2-element Vector{Int64}:
 0
 1

julia> for epoch in c
           v[1] += 1
       end

julia> v
recorded 2-element Vector{Int64}:
 3
 1

julia> records(v)[1]
Record Entries
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
```
"""
struct DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}
    v::Vector{V}
    t::C
    vs::Vector{Vector{V}}
    ts::Vector{Vector{T}}
    indmax::State{I}
    indmap::Vector{I}
end
function DynamicRArray(t::AbstractClock, v::AbstractVector)
    n = length(v)
    vs = map(i -> [i], v)
    ts = map(_ -> [now(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(copy(v), t, vs, ts, State(n), indmap)
end

state(A::DynamicRVector) = A.v

Base.length(A::DynamicRVector) = value(A.indmax)
Base.size(A::DynamicRVector) = (length(A),)

function Base.getindex(A::DynamicRVector, i::Integer)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    return A.v[i]
end

function Base.setindex!(A::DynamicRVector, v, i::Integer)
    A.v[i] = v
    ind = A.indmap[i]
    push!(A.vs[ind], v)
    push!(A.ts[ind], now(A.t))
    return A
end

function Base.deleteat!(A::DynamicRVector, i::Integer)
    deleteat!(A.v, i)
    deleteat!(A.indmap, i)
    return A
end

function Base.push!(A::DynamicRVector, v)
    push!(A.v, v)
    ind = plus!(A.indmax, true)
    push!(A.indmap, ind)
    push!(A.vs, [v])
    push!(A.ts, [now(A.t)])
    return A
end

function Base.getindex(r::Records{<:DynamicRVector}, i::Integer)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    return SingleEntries(A.ts[i], A.vs[i])
end
# vim:tw=92:ts=4:sw=4:et
