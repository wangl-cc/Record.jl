import Base:IteratorSize, iterate, eltype,
            *, transpose, broadcastable
using Base:HasShape, HasLength

mutable struct Clock{T<:Real}
    t::T
    max::T
end
Clock(max::Real) = Clock(0.0, max)
Clock(t::Real, max::Real) = Clock(promote(t, max)...)

current(c::Clock) = c.t
limit(c::Clock) = c.max
isend(c::Clock) = current(c) > limit(c)
notend(c::Clock) = current(c) <= limit(c)
increase!(c::Clock, t::Real) = c.t += t

"""
    AbstractRecord{V,T,N}
    
Supertype for record which record changes of `N`-dimensional arrays with
elements of type `V` and time of type `T`".
"""
abstract type AbstractRecord{V<:Number, T<:Real, N} end

function IteratorSize(::Type{<:AbstractRecord{V,T,N}}) where {V,T,N} 
    HasShape{N}()
end
function iterate(r::AbstractRecord, state = 1)
    if state <= length(r)
        return getrecord(r, state), state + 1
    else
        return nothing
    end
end

transpose(r::AbstractRecord) = transpose(state(r))
*(x::AbstractRecord, y) = state(x) * y
*(x, y::AbstractRecord) = x * state(y)
*(x::AbstractRecord, y::AbstractRecord) = state(x) * state(y)
broadcastable(r::AbstractRecord) = state(r) 


"""
    DynamicRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements change overtime.
"""
abstract type DynamicRecord{V,T,N} <: AbstractRecord{V,T,N} end
DynamicRecord(t::Clock, x, xs...) =
    (DynamicRecord(t, x), DynamicRecord(t, xs)...)

"""
    StaticRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes arrays whose elements never change but
insert or delete.
"""
abstract type StaticRecord{V,T,N} <: AbstractRecord{V,T,N} end
StaticRecord(t::Clock, x, xs...) =
    (StaticRecord(t, x), StaticRecord(t, xs)...)

"""
    RecordView{V,T}
"""
abstract type RecordView{V,T} end

struct DynamicView{V,T} <: RecordView{V,T}
    xs::Vector{V}
    ts::Vector{T}
end
tspan(v::DynamicView) = v.ts[end] - v.ts[1]
xs(v::DynamicView) = v.xs
ts(v::DynamicView) = v.ts

struct StaticView{V,T} <: RecordView{V,T}
    x::V
    s::T
    e::T
end
tspan(v::StaticView) = v.e - v.s
xs(v::StaticView) = [v.x, v.x]
ts(v::StaticView) = [v.s, v.e]

mutable struct TypeBox{V}
    v::V
end
