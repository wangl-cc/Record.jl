import Base: length, size, getindex

struct VectorStaticReocrd{V,T,I} <: StaticRecord{V,T,1}
    x::Vector{V}
    s::Vector{T}
    e::Vector{T}
    maxe::T
    indmax::TypeBox{I}
    indmap::Vector{I}
end

length(r::VectorStaticReocrd) = r.indmax.x
size(r::VectorStaticReocrd) = (length(r),)
function getindex(r::VectorStaticReocrd, i::Integer)
    @boundscheck i <= r.indmax.x || throw(BoundsError(r, i))
    return StaticView(r.x[i], r.s[i], r.e[i])
end

function StaticRecord(t::Real, maxe::Real, x::AbstractVector)
    x = collect(x)
    n = length(x)
    t, maxe = promote(t, maxe)
    s = fill(t, n)
    e = fill(maxe, n)
    return VectorStaticReocrd(x, s, e, maxe, TypeBox(n), collect(1:n))
end

function record!(r::VectorStaticReocrd, t::Real, c::DelChange)
    ind = r.indmap[c.i]
    r.e[ind] = t
    deleteat!(r.indmap, c.i)
    return r
end

function record!(r::VectorStaticReocrd, t::Real, c::PushChange)
    ind = r.indmax.x += true
    push!(r.indmap, ind)
    push!(r.x, c.x)
    push!(r.s, t)
    push!(r.e, r.maxe)
    return r
end
