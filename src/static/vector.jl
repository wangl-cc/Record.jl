"""
    StaticRVector{V,T,C<:AbstractClock{T}, I} <: StaticRArray{V,T,1}

Implementation of recorded static vector, created by
`StaticRArray(c::AbstractClock, v::AbstractVector)`.
"""
struct StaticRVector{V,T,C<:AbstractClock{T},I} <: StaticRArray{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    delete::Vector{Bool}
    t::C
    s::Vector{T}
    e::Vector{T}
    indmax::Array{I,0}
    indmap::Vector{I}
end
function StaticRArray(t::AbstractClock, v::AbstractVector)
    v = collect(v)
    n = length(v)
    s = fill(now(t), n)
    e = fill(limit(t), n)
    delete = zeros(Bool, n)
    return StaticRVector(v, copy(v), delete, t, s, e, fill(n), collect(1:n))
end

state(A::StaticRVector) = A.v

rlength(A::StaticRVector) = A.indmax[]
rsize(A::StaticRVector) = (rlength(A),)

function Base.push!(A::StaticRVector{V}, v::V) where {V}
    push!(A.v, v)
    push!(A.v_all, v)
    push!(A.delete, false)
    ind = A.indmax[] += 1
    push!(A.indmap, ind)
    push!(A.s, now(A.t))
    push!(A.e, limit(A.t))
    return A
end
Base.push!(A::StaticRVector{T}, v) where {T} = push!(A, convert(T, v))

function Base.deleteat!(A::StaticRVector, i::Integer)
    deleteat!(A.v, i)
    ind = A.indmap[i]
    A.delete[ind] = true
    A.e[ind] = now(A.t)
    deleteat!(A.indmap, i)
    return A
end

function Base.getindex(r::Record{<:StaticRVector}, i::Integer)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    t = now(A.t)
    e = ifelse(A.delete[i] || t == start(A.t), A.e[i], t)
    return StaticEntry(A.s[i], e, A.v_all[i])
end
