"""
    DynamicRVector{V,T,I,C<:AbstractClock{T}} <: DynamicRArray{V,T,1}

Implementation of recorded dynamics vector, created by
`DynamicRArray(c::AbstractClock, v::AbstractVector)`
"""
mutable struct DynamicRVector{Tv,Tt,Tc} <: DynamicRArray{Tv,Tt,1}
    v::Vector{Tv}
    t::Tc
    V::Vector{Vector{Tv}}
    T::Vector{Vector{Tt}}
    rlen::Int
    indmap::Vector{Int}
    function DynamicRVector(
            v::Vector{Tv},
            t::Tc,
            V::Vector{Vector{Tv}},
            T::Vector{Vector{Tt}},
            rlen::Int,
            indmap::Vector{Int}
        ) where {Tv,Tt,Tc<:AbstractClock{Tt}}
        checksize(v, indmap)
        checksize((rlen,), V, T)
        for (vi, ti) in zip(V, T)
            checksize(vi, ti)
        end
        return new{Tv,Tt,Tc}(v, t, V, T, rlen, indmap)
    end
end
function DynamicRArray(t::AbstractClock, v::AbstractVector)
    n = length(v)
    V = map(i -> [i], v)
    T = map(_ -> [currenttime(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(collect(v), t, V, T, n, indmap)
end

_rlength(A::DynamicRVector) = A.rlen

function Base.push!(A::DynamicRVector{T}, v::T) where {T}
    push!(A.v, v)
    ind = A.rlen += 1
    push!(A.indmap, ind)
    push!(A.V, [v])
    push!(A.T, [currenttime(A.t)])
    return A
end
Base.push!(A::DynamicRVector{T}, v) where {T} = push!(A, convert(T, v))

# only insert for state not in record
function Base.insert!(A::DynamicRVector{T}, i::Integer, v::T) where {T}
    insert!(A.v, i, v)
    ind = A.rlen += 1
    insert!(A.indmap, i, ind)
    push!(A.V, [v])
    push!(A.T, [currenttime(A.t)])
    return A
end
Base.insert!(A::DynamicRVector{T}, i::Integer, v) where {T} = insert!(A, i, convert(T, v))

function Base.deleteat!(A::DynamicRVector, i::Integer)
    @boundscheck checkbounds(A, i)
    @inbounds deleteat!(A.v, i)
    @inbounds deleteat!(A.indmap, i)
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