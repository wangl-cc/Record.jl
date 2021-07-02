"""
    StaticRVector{V,T,C<:AbstractClock{T}, I} <: StaticRArray{V,T,1}

Implementation of recorded static vector, created by
`StaticRArray(c::AbstractClock, v::AbstractVector)`.
"""
mutable struct StaticRVector{V,T,C<:AbstractClock{T},I} <: StaticRArray{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    delete::Vector{Bool}
    t::C
    s::Vector{T}
    e::Vector{T}
    indmax::I
    indmap::Vector{I}
end
function StaticRArray(t::AbstractClock, v::AbstractVector)
    v = collect(v)
    n = length(v)
    s = fill(currenttime(t), n)
    e = fill(limit(t), n)
    delete = zeros(Bool, n)
    return StaticRVector(v, copy(v), delete, t, s, e, n, collect(1:n))
end

rlength(A::StaticRVector) = A.indmax
rsize(A::StaticRVector) = (rlength(A),)

function Base.push!(A::StaticRVector{V}, v::V) where {V}
    push!(A.v, v)
    push!(A.v_all, v)
    push!(A.delete, false)
    ind = A.indmax += 1
    push!(A.indmap, ind)
    push!(A.s, currenttime(A.t))
    push!(A.e, limit(A.t))
    return A
end
Base.push!(A::StaticRVector{T}, v) where {T} = push!(A, convert(T, v))

# only insert for state not in record
function Base.insert!(A::StaticRVector{V}, i::Integer, v::V) where {V}
    insert!(A.v, i, v)
    push!(A.v_all, v)
    push!(A.delete, false)
    ind = A.indmax += 1
    insert!(A.indmap, i, ind)
    push!(A.s, currenttime(A.t))
    push!(A.e, limit(A.t))
    return A
end
Base.insert!(A::StaticRVector{T}, i::Integer, v) where {T} = insert!(A, i, convert(T, v))

function Base.deleteat!(A::StaticRVector, i::Integer)
    deleteat!(A.v, i)
    ind = A.indmap[i]
    A.delete[ind] = true
    A.e[ind] = currenttime(A.t)
    deleteat!(A.indmap, i)
    return A
end

function rgetindex(A::StaticRVector, i::Integer)
    @boundscheck i <= rlength(A) || throw(BoundsError(A, i))
    t = currenttime(A.t)
    e = ifelse(A.delete[i] || t == start(A.t), A.e[i], t)
    return StaticEntry(A.s[i], e, A.v_all[i])
end
