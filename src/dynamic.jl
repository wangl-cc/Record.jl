import Base: length, size, getindex, setindex!,
             push!, deleteat!

"""
    DynamicRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements change overtime.
"""
abstract type DynamicRecord{V,T,N} <: AbstractRecord{V,T,N} end
function DynamicRecord(t::Clock, x1, x2)
    DynamicRecord(t, x1), DynamicRecord(t, x2)
end
function DynamicRecord(t::Clock, x1, x2, xs...)
     DynamicRecord(t, x1), DynamicRecord(t, x2, xs...)::Tuple...
end


"""
    ScalerDynamicRecord{V, T}

Record changes of a scaler. Use `r[1] = v` to change its value instead of
`r = v`.
"""
struct ScaleDynamicRecord{V,T} <: DynamicRecord{V,T,0}
    v::TypeBox{V}
    t::Clock{T}
    vs::Vector{V}
    ts::Vector{T}
end
function DynamicRecord(t::Clock, x::Number)
    return ScaleDynamicRecord(TypeBox(x), t, [x], [current(t)])
end

state(r::ScaleDynamicRecord) = r.v.v

length(::ScaleDynamicRecord) = 1
size(::ScaleDynamicRecord) = (1,)
function getindex(r::ScaleDynamicRecord, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    return r.v.v
end
function setindex!(r::ScaleDynamicRecord, v, i::Integer=1)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    r.v.v = v
    push!(r.vs, v)
    push!(r.ts, current(r.t))
    return r
end

function getrecord(r::ScaleDynamicRecord, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    return DynamicView(r.ts, r.vs)
end


"""
    VectorDynamicRecord{V,T,I}

Record changes of a vector with indices of type `I`.
"""
struct VectorDynamicRecord{V,T,I} <: DynamicRecord{V,T,1}
    v::Vector{V}
    t::Clock{T}
    vs::Vector{Vector{V}}
    ts::Vector{Vector{T}}
    indmax::TypeBox{I}
    indmap::Vector{I}
end
function DynamicRecord(t::Clock, x::AbstractVector)
    n = length(x)
    vs = map(i -> [i], x)
    ts = map(_ -> [current(t)], 1:n)
    indmap = collect(1:n)
    return VectorDynamicRecord(copy(x), t, vs, ts,
                              TypeBox(n), indmap)
end

state(r::VectorDynamicRecord) = r.v

length(r::VectorDynamicRecord) = r.indmax.v
size(r::VectorDynamicRecord) = (length(r),)

function getindex(r::VectorDynamicRecord, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return r.v[i] 
end

function setindex!(r::VectorDynamicRecord, v, i::Integer)
    r.v[i] = v
    ind = r.indmap[i]
    push!(r.vs[ind], v)
    push!(r.ts[ind], current(r.t))
    return r
end

function deleteat!(r::VectorDynamicRecord, i::Integer)
    deleteat!(r.v, i)
    deleteat!(r.indmap, i)
    return r
end

function push!(r::VectorDynamicRecord, v)
    push!(r.v, v)
    ind = r.indmax.v += true
    push!(r.indmap, ind)
    push!(r.vs, [v])
    push!(r.ts, [current(r.t)])
    return r
end

function getrecord(r::VectorDynamicRecord, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return DynamicView(r.ts[i], r.vs[i])
end
