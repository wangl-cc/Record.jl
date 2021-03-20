import Base: length, size, getindex

"""
    ScaleDynamicRecord
"""
struct ScaleDynamicRecord{V,T} <: DynamicRecord{V,T,0}
    xs::Vector{V}
    ts::Vector{T}
end

length(::ScaleDynamicRecord) = 1
size(::ScaleDynamicRecord) = (1,)
function getindex(r::ScaleDynamicRecord, i::Integer)
    @boundscheck i == 1 || throw(BoundsError(r, i))
    return DynamicView(r.rs, r.xs)
end

function DynamicRecord(t::Real, x::Number)
    return ScaleDynamicRecord([x], [t])
end
function record!(r::ScaleDynamicRecord, t::Real, c::EleChange)
    push!(r.xs, c.x)
    push!(r.ts, t)
    return r
end


"""
    VectorDynamicRecord
"""
struct VectorDynamicRecord{V,T,I} <: DynamicRecord{V,T,1}
    xs_list::Vector{Vector{V}}
    ts_list::Vector{Vector{T}}
    indmax::TypeBox{I}
    indmap::Vector{I}
end

length(r::VectorDynamicRecord) = r.indmax.x
size(r::VectorDynamicRecord) = (length(r),)
function getindex(r::VectorDynamicRecord, i::Integer)
    @boundscheck i <= r.indmax.x || throw(BoundsError(r, i))
    return DynamicView(r.xs_list[i], r.ts_list[i])
end

function DynamicRecord(t::Real, x::AbstractVector)
    n = length(x)
    xs = map(i -> [i], x)
    ts = fill([t], n)
    indmap = collect(1:n)
    return VectorDynamicRecord(xs, ts, TypeBox(n), indmap)
end

function record!(r::VectorDynamicRecord, t::Real, c::EleChange)
    ind = r.indmap[c.i]
    push!(r.xs_list[ind], c.x)
    push!(r.ts_list[ind], t)
    return r
end

function record!(r::VectorDynamicRecord, ::Real, c::DelChange)
    deleteat!(r.indmap, c.i)
    return r
end

function record!(r::VectorDynamicRecord, t::Real, c::PushChange)
    ind = r.indmax.x += true
    push!(r.indmap, ind)
    push!(r.xs_list, [c.x])
    push!(r.ts_list, [t])
    return r
end
