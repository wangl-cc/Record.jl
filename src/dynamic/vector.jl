"""
    DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}

Implementation of recorded dynamics vector, created by
`DynamicRArray(c::AbstractClock, v::AbstractVector)`
"""
mutable struct DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}
    v::Vector{V}
    t::C
    vs::Vector{Vector{V}}
    ts::Vector{Vector{T}}
    indmax::I
    indmap::Vector{I}
end
function DynamicRArray(t::AbstractClock, v::AbstractVector)
    n = length(v)
    vs = map(i -> [i], v)
    ts = map(_ -> [currenttime(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(collect(v), t, vs, ts, n, indmap)
end

rlength(A::DynamicRVector) = A.indmax
rsize(A::DynamicRVector) = (rlength(A),)

function Base.push!(A::DynamicRVector{T}, v::T) where {T}
    push!(A.v, v)
    ind = A.indmax += 1
    push!(A.indmap, ind)
    push!(A.vs, [v])
    push!(A.ts, [currenttime(A.t)])
    return A
end
Base.push!(A::DynamicRVector{T}, v) where {T} = push!(A, convert(T, v))

# only insert for state not in record
function Base.insert!(A::DynamicRVector{V}, i::Integer, v::V) where {V}
    insert!(A.v, i, v)
    ind = A.indmax += 1
    insert!(A.indmap, i, ind)
    push!(A.vs, [v])
    push!(A.ts, [currenttime(A.t)])
    return A
end
Base.insert!(A::DynamicRVector{T}, i::Integer, v) where {T} = insert!(A, i, convert(T, v))

function Base.setindex!(A::DynamicRVector, v, i::Int)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    A.v[i] = v
    ind = A.indmap[i]
    push!(A.vs[ind], v)
    push!(A.ts[ind], currenttime(A.t))
    return A
end

function Base.deleteat!(A::DynamicRVector, i::Integer)
    @boundscheck i <= length(A) || throw(BoundsError(A, i))
    deleteat!(A.v, i)
    deleteat!(A.indmap, i)
    return A
end

function rgetindex(A::DynamicRVector, i::Int)
    @boundscheck i <= rlength(A) || throw(BoundsError(A, i))
    return DynamicEntry(A.ts[i], A.vs[i])
end
