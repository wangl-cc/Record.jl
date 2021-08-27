"""
    DynamicRVector{V,T,C} <: DynamicRArray{V,T,1}

Implementation of recorded dynamics vector, created by
`DynamicRArray(c::AbstractClock, v::AbstractVector)`
"""
mutable struct DynamicRVector{V,T,C} <: DynamicRArray{V,T,1}
    v::Vector{V}
    c::C
    record::Vector{DynamicEntry{V,T}}
    indmap::Vector{Int}
    function DynamicRVector(
            v::Vector{V},
            c::C,
            record::Vector{DynamicEntry{V,T}},
            indmap::Vector{Int}
        ) where {V,T,C<:AbstractClock{T}}
        checksize(v, indmap)
        return new{V,T,C}(v, c, record, indmap)
    end
end
function DynamicRArray(c::AbstractClock, v::AbstractVector)
    n = length(v)
    V = map(i -> [i], v)
    T = map(_ -> [currenttime(c)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(collect(v), c, V, T, indmap)
end

_rlength(A::DynamicRVector) = length(A.record)

function Base.push!(A::DynamicRVector{T}, v::T) where {T}
    push!(A.v, v)
    ind = lastindex(A.record) + 1
    push!(A.indmap, ind)
    push!(A.record, DynamicEntry(v, A.c))
    return A
end
Base.push!(A::DynamicRVector{T}, v) where {T} = push!(A, convert(T, v))

# only insert for state not in record
function Base.insert!(A::DynamicRVector{T}, i::Integer, v::T) where {T}
    insert!(A.v, i, v)
    ind = lastindex(A.record) + 1
    insert!(A.indmap, i, ind)
    push!(A.record, DynamicEntry(v, A.c))
    return A
end
Base.insert!(A::DynamicRVector{T}, i::Integer, v) where {T} = insert!(A, i, convert(T, v))

function Base.deleteat!(A::DynamicRVector, i::Integer)
    @boundscheck checkbounds(A, i)
    @inbounds deleteat!(A.indmap, i)
    @inbounds deleteat!(A.record, i)
    return A
end

function Base.setindex!(A::DynamicRVector, v, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds A.v[i] = v
    @inbounds ind = A.indmap[i]
    push!(A.V[ind], v)
    push!(A.T[ind], currenttime(A.t))
    return A
end

function rgetindex(A::DynamicRVector, i::Int)
    @boundscheck i <= rlength(A) || throw(BoundsError(A, i))
    return DynamicEntry(A.T[i], A.V[i])
end