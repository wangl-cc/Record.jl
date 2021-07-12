"""
    StaticRVector{V,T,C<:AbstractClock{T}} <: StaticRArray{V,T,1}

Implementation of recorded static vector, created by
`StaticRArray(c::AbstractClock, v::AbstractVector)`.
"""
mutable struct StaticRVector{Tv,Tt,Tc} <: StaticRArray{Tv,Tt,1}
    v::Vector{Tv}
    t::Tc
    V::Vector{Tv}
    delete::Vector{Bool}
    s::Vector{Tt}
    e::Vector{Tt}
    rlen::Int
    indmap::Vector{Int}
    function StaticRVector(
            v::Vector{Tv},
            t::Tc,
            V::Vector{Tv},
            delete::Vector{Bool},
            s::Vector{Tt},
            e::Vector{Tt},
            rlen::Int,
            indmap::Vector{Int}
        ) where {Tv,Tt,Tc<:AbstractClock{Tt}}
        checksize((rlen,), V, delete, s, e)
        checksize(v, indmap)
        return new{Tv,Tt,Tc}(v, t, V, delete, s, e, rlen, indmap)
    end
end

function StaticRArray(t::AbstractClock, v::AbstractVector)
    v = collect(v)
    n = length(v)
    s = fill(currenttime(t), n)
    e = fill(limit(t), n)
    delete = zeros(Bool, n)
    return StaticRVector(v, t, copy(v), delete, s, e, n, collect(1:n))
end

rlength(A::StaticRVector) = A.rlen
rsize(A::StaticRVector) = (rlength(A),)

function Base.push!(A::StaticRVector{T}, v::T) where {T}
    push!(A.v, v)
    push!(A.V, v)
    push!(A.delete, false)
    ind = A.rlen += 1
    push!(A.indmap, ind)
    push!(A.s, currenttime(A.t))
    push!(A.e, limit(A.t))
    return A
end
Base.push!(A::StaticRVector{T}, v) where {T} = push!(A, convert(T, v))

# only insert for state not in record
function Base.insert!(A::StaticRVector{T}, i::Integer, v::T) where {T}
    insert!(A.v, i, v)
    push!(A.V, v)
    push!(A.delete, false)
    ind = A.rlen += 1
    insert!(A.indmap, i, ind)
    push!(A.s, currenttime(A.t))
    push!(A.e, limit(A.t))
    return A
end
Base.insert!(A::StaticRVector{T}, i::Integer, v) where {T} = insert!(A, i, convert(T, v))

function Base.deleteat!(A::StaticRVector, i::Integer)
    @boundscheck checkbounds(A, i)
    @inbounds deleteat!(A.v, i)
    @inbounds ind = A.indmap[i]
    A.delete[ind] = true
    A.e[ind] = currenttime(A.t)
    @inbounds deleteat!(A.indmap, i)
    return A
end

function rgetindex(A::StaticRVector, i::Integer)
    t = currenttime(A.t)
    e = ifelse(A.delete[i] || t == start(A.t), A.e[i], t)
    return StaticEntry(A.s[i], e, A.V[i])
end
