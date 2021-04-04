import Base: length, size, getindex,
             push!, deleteat!

"""
    StaticRArray{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements never change but insert
or delete.
"""
abstract type StaticRArray{V,T,N} <: AbstractRArray{V,T,N} end
function StaticRArray(t::Clock, x1, x2)
    StaticRArray(t, x1), StaticRArray(t, x2)
end
function StaticRArray(t::Clock, x1, x2, xs...)
    StaticRArray(t, x1), StaticRArray(t, x2, xs...)::Tuple...
end


"""
    VectorStaticRecord{V,T,N} <: AbstractRecord{V,T,N}

Record changes vector.
"""
struct StaticRVector{V,T,I} <: StaticRArray{V,T,1}
    v::Vector{V}
    v_all::Vector{V}
    t::Clock{T}
    s::Vector{T}
    e::Vector{T}
    indmax::TypeBox{I}
    indmap::Vector{I}
end
function StaticRArray(t::Clock, x::AbstractVector)
    x = collect(x)
    n = length(x)
    s = fill(now(t), n)
    e = fill(limit(t), n)
    return StaticRVector(copy(x), copy(x), t, s, e,
                              TypeBox(n), collect(1:n))
end

state(r::StaticRVector) = r.v
length(r::StaticRVector) = r.indmax.v
size(r::StaticRVector) = (length(r),)

function push!(r::StaticRVector, v)
    push!(r.v, v)
    push!(r.v_all, v)
    ind = r.indmax.v += true
    push!(r.indmap, ind)
    push!(r.s, now(r.t))
    push!(r.e, limit(r.t))
    return r
end

function deleteat!(r::StaticRVector, i::Integer)
    deleteat!(r.v, i)
    ind = r.indmap[i]
    r.e[ind] = now(r.t)
    deleteat!(r.indmap, i)
    return r
end

function getrecord(r::StaticRVector, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return RecordView([r.s[i], r.e[i]], [r.v[i], r.v[i]])
end
