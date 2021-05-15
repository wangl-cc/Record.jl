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
    indmax::State{I}
    indmap::Vector{I}
end
function StaticRArray(t::AbstractClock, v::AbstractVector)
    v = collect(v)
    n = length(v)
    s = fill(now(t), n)
    e = fill(limit(t), n)
    delete = zeros(Bool, n)
    return StaticRVector(v, copy(v), delete, t, s, e, State(n), collect(1:n))
end

state(A::StaticRVector) = A.v

rlength(A::StaticRVector) = value(A.indmax)
rsize(A::StaticRVector) = (rlength(A),)

function Base.push!(r::StaticRVector, v)
    push!(r.v, v)
    push!(r.v_all, v)
    push!(r.delete, false)
    ind = plus!(r.indmax, true)
    push!(r.indmap, ind)
    push!(r.s, now(r.t))
    push!(r.e, limit(r.t))
    return r
end

function Base.deleteat!(r::StaticRVector, i::Integer)
    deleteat!(r.v, i)
    ind = r.indmap[i]
    r.delete[ind] = true
    r.e[ind] = now(r.t)
    deleteat!(r.indmap, i)
    return r
end

function Base.getindex(r::Records{<:StaticRVector}, i::Integer)
    @boundscheck i <= length(r) || throw(BoundsError(r, i))
    A = r.array
    t = now(A.t)
    e = ifelse(A.delete[i] || t == start(A.t), A.e[i], t)
    return StaticEntries(A.s[i], e, A.v_all[i])
end
# vim:tw=92:ts=4:sw=4:et
