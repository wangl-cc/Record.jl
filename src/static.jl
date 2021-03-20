import Base: length, size, getindex,
             push!, deleteat!

struct VectorStaticReocrd{V,T,I} <: StaticRecord{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    t::Clock{T}
    s::Vector{T}
    e::Vector{T}
    indmax::TypeBox{I}
    indmap::Vector{I}
end

state(r::VectorStaticReocrd) = r.v
length(r::VectorStaticReocrd) = r.indmax.x
size(r::VectorStaticReocrd) = (length(r),)

function push!(r::VectorStaticReocrd, v)
    push!(r.v, v)
    push!(r.v_all, v)
    ind = r.indmax.x += true
    push!(r.indmap, ind)
    push!(r.x, v)
    push!(r.s, current(r.t))
    push!(r.e, last(r.t))
    return r
end

function deleteat!(r::VectorStaticReocrd, i::Integer)
    deleteat!(r.x, i)
    ind = r.indmap[i]
    r.e[ind] = current(r.t)
    deleteat!(r.indmap, i)
    return r
end

function StaticRecord(t::Real, maxe::Real, x::AbstractVector)
    x = collect(x)
    n = length(x)
    t, maxe = promote(t, maxe)
    s = fill(t, n)
    e = fill(maxe, n)
    return VectorStaticReocrd(copy(x), copy(x), s, e,
                              TypeBox(n), collect(1:n))
end

function getrecord(r::VectorStaticReocrd, i::Integer)
    @boundscheck i <= r.indmax.x || throw(BoundsError(r, i))
    return StaticView(r.x[i], r.s[i], r.e[i])
end
