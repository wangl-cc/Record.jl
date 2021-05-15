"""
    DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRScalar{V,T,0}

Implementation of recorded scaler, created by `DynamicRArray(t::AbstractClock, v::Number)`.
Use `S[1] = v` to change its value instead of `S = v`.
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
function Base.getindex(A::DynamicRScalar, i::Int)
    @boundscheck i == 1 || throw(BoundsError(A, i))
    return value(A.v)
end

rlength(::DynamicRScalar) = 1
rsize(::DynamicRScalar) = (1,)

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
    indmax::State{I}
    indmap::Vector{I}
end
function DynamicRArray(t::AbstractClock, v::AbstractVector)
    n = length(v)
    vs = map(i -> [i], v)
    ts = map(_ -> [now(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(collect(v), t, vs, ts, State(n), indmap)
end

state(A::DynamicRVector) = A.v

rlength(A::DynamicRVector) = value(A.indmax)
rsize(A::DynamicRVector) = (rlength(A),)

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
    return DynamicEntries(A.ts[i], A.vs[i])
end
# vim:tw=92:ts=4:sw=4:et
