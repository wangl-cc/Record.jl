import Base: length, size, getindex, setindex!,
             push!, deleteat!

"""
    DynamicRArray{V,T,N} <: AbstractRecord{V,T,N}

Recorded arrays whose elements change overtime.
"""
abstract type DynamicRArray{V,T,N} <: AbstractRArray{V,T,N} end
function DynamicRArray(t::Clock, x1, x2)
    DynamicRArray(t, x1), DynamicRArray(t, x2)
end
function DynamicRArray(t::Clock, x1, x2, xs...)
     DynamicRArray(t, x1), DynamicRArray(t, x2, xs...)::Tuple...
end

"""
    ScalerDynamicRecord{V, T}

Record scaler. Use `S[1] = v` to change its value instead of
`S[1] = v`.
"""
struct DynamicRScalar{V,T} <: DynamicRArray{V,T,0}
    v::TypeBox{V}
    t::Clock{T}
    vs::Vector{V}
    ts::Vector{T}
end
function DynamicRArray(t::Clock, x::Number)
    return DynamicRScalar(TypeBox(x), t, [x], [current(t)])
end

state(r::DynamicRScalar) = r.v.v

length(::DynamicRScalar) = 1
size(::DynamicRScalar) = (1,)
function getindex(r::DynamicRScalar, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    return r.v.v
end
function setindex!(r::DynamicRScalar, v, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    r.v.v = v
    push!(r.vs, v)
    push!(r.ts, current(r.t))
    return r
end

function getrecord(r::DynamicRScalar, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    return RecordView(r.ts, r.vs)
end


"""
    DynamicRVector{V,T,I}

Record changes of a vector with indices of type `I`.
"""
struct DynamicRVector{V,T,I} <: DynamicRArray{V,T,1}
    v::Vector{V}
    t::Clock{T}
    vs::Vector{Vector{V}}
    ts::Vector{Vector{T}}
    indmax::TypeBox{I}
    indmap::Vector{I}
end
function DynamicRArray(t::Clock, x::AbstractVector)
    n = length(x)
    vs = map(i -> [i], x)
    ts = map(_ -> [current(t)], 1:n)
    indmap = collect(1:n)
    return DynamicRVector(copy(x), t, vs, ts,
                              TypeBox(n), indmap)
end

state(r::DynamicRVector) = r.v

length(r::DynamicRVector) = r.indmax.v
size(r::DynamicRVector) = (length(r),)

function getindex(r::DynamicRVector, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return r.v[i] 
end

function setindex!(r::DynamicRVector, v, i::Integer)
    r.v[i] = v
    ind = r.indmap[i]
    push!(r.vs[ind], v)
    push!(r.ts[ind], current(r.t))
    return r
end

function deleteat!(r::DynamicRVector, i::Integer)
    deleteat!(r.v, i)
    deleteat!(r.indmap, i)
    return r
end

function push!(r::DynamicRVector, v)
    push!(r.v, v)
    ind = r.indmax.v += true
    push!(r.indmap, ind)
    push!(r.vs, [v])
    push!(r.ts, [current(r.t)])
    return r
end

function getrecord(r::DynamicRVector, i::Integer)
    @boundscheck i <= r.indmax.v || throw(BoundsError(r, i))
    return RecordView(r.ts[i], r.vs[i])
end
