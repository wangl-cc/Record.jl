"""
    DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRScalar{V,T,0}

Implementation of recorded scaler, created by `DynamicRArray(t::AbstractClock, v::Number)`,
or `DynamicRArray(t::AbstractClock, A::AbstractArray{T,0})`.

!!! info
     
    Store a value `v` of a `DynamicRScalar` `S` by `S[] = v` or `S[1] = v` instead of `S = v`.
    Although this is an array type, Mathematical operations on it work like `Number` for convenience.
```
"""
struct DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRArray{V,T,0}
    v::Array{V,0}
    t::C
    vs::Vector{V}
    ts::Vector{T}
end
DynamicRArray(t::AbstractClock, v::Number) = DynamicRScalar(fill(v), t, [v], [now(t)])
DynamicRArray(t::AbstractClock, v::Array{<:Any,0}) = DynamicRScalar(v, t, [v[]], [now(t)])

state(A::DynamicRScalar) = A.v[]

Base.length(::DynamicRScalar) = 1
Base.size(::DynamicRScalar) = (1,)

rlength(::DynamicRScalar) = 1
rsize(::DynamicRScalar) = (1,)

function Base.setindex!(A::DynamicRScalar, v, i::Int)
    @boundscheck i == 1 || throw(BoundsError(A, i))
    @inbounds A.v[] = v
    push!(A.vs, v)
    push!(A.ts, now(A.t))
    return A
end

function Base.getindex(r::Records{<:DynamicRScalar}, i::Int)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    A = r.array
    return DynamicEntries(A.ts, A.vs)
end

"""
    DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}

Implementation of recorded dynamics vector, created by
`DynamicRArray(c::AbstractClock, v::AbstractVector)`
"""
struct DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}
    v::Vector{V}
    t::C
    vs::Vector{Vector{V}}
    ts::Vector{Vector{T}}
    indmax::Array{I,0}
    indmap::Vector{I}
end
function DynamicRArray(t::AbstractClock, v::AbstractVector)
    n = length(v)
    vs = map(i -> [i], v)
    ts = map(_ -> [now(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(collect(v), t, vs, ts, fill(n), indmap)
end

state(A::DynamicRVector) = A.v

rlength(A::DynamicRVector) = A.indmax[]
rsize(A::DynamicRVector) = (rlength(A),)

function Base.setindex!(A::DynamicRVector, v, i::Int)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    A.v[i] = v
    ind = A.indmap[i]
    push!(A.vs[ind], v)
    push!(A.ts[ind], now(A.t))
    return A
end

function Base.deleteat!(A::DynamicRVector, i::Int)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    deleteat!(A.v, i)
    deleteat!(A.indmap, i)
    return A
end

function Base.push!(A::DynamicRVector, v)
    push!(A.v, v)
    ind = A.indmax[] += 1
    push!(A.indmap, ind)
    push!(A.vs, [v])
    push!(A.ts, [now(A.t)])
    return A
end

function Base.getindex(r::Records{<:DynamicRVector}, i::Int)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    return DynamicEntries(A.ts[i], A.vs[i])
end
# vim:tw=92:ts=4:sw=4:et
