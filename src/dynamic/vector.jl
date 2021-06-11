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

function Base.getindex(r::Records{<:DynamicRVector}, i::Integer)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    return DynamicEntries(A.ts[i], A.vs[i])
end
