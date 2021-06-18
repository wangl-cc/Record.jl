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

function Base.getindex(r::Record{<:DynamicRScalar}, i::Integer=1)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    A = r.array
    return DynamicEntry(A.ts, A.vs)
end
