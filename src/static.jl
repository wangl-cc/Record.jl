import Base: length, size, getindex,
             push!, deleteat!

"""
    StaticRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements never change but insert
or delete.
"""
abstract type StaticRecord{V,T,N} <: AbstractRecord{V,T,N} end
function StaticRecord(t::Clock, x1, x2)
    StaticRecord(t, x1), StaticRecord(t, x2)
end
function StaticRecord(t::Clock, x1, x2, xs...)
    StaticRecord(t, x1), StaticRecord(t, x2, xs...)::Tuple...
end


"""
    VectorStaticRecord{V,T,N} <: AbstractRecord{V,T,N}

Record changes vector.
"""
struct VectorStaticReocrd{V,T,I} <: StaticRecord{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    t::Clock{T}
    s::Vector{T}
    e::Vector{T}
    indmax::TypeBox{I}
    indmap::Vector{I}
end
function StaticRecord(t::Clock, x::AbstractVector)
    x = collect(x)
    n = length(x)
    s = fill(current(t), n)
    e = fill(limit(t), n)
    return VectorStaticReocrd(copy(x), copy(x), t, s, e,
                              TypeBox(n), collect(1:n))
end

state(r::VectorStaticReocrd) = r.v
length(r::VectorStaticReocrd) = r.indmax.v
size(r::VectorStaticReocrd) = (length(r),)

function push!(r::VectorStaticReocrd, v)
    push!(r.v, v)
    push!(r.v_all, v)
    ind = r.indmax.v += true
    push!(r.indmap, ind)
    push!(r.s, current(r.t))
    push!(r.e, limit(r.t))
    return r
end

function deleteat!(r::VectorStaticReocrd, i::Integer)
    deleteat!(r.v, i)
    ind = r.indmap[i]
    r.e[ind] = current(r.t)
    deleteat!(r.indmap, i)
    return r
end

function getrecord(r::VectorStaticReocrd, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return StaticView(r.v[i], r.s[i], r.e[i])
end
