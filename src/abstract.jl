import Base:IteratorSize, iterate, eltype, setindex!
using Base:HasShape, HasLength

"""
    AbstractRecord{V,T,N}
    
Supertype for record which record changes of `N`-dimensional arrays with
elements of type `V` and time of type `T`".
"""
abstract type AbstractRecord{V<:Number, T<:Real, N} end

IteratorSize(::Type{<:AbstractRecord{V,T,N}}) where {V,T,N} =
    HasShape{N}()

function iterate(r::AbstractRecord, state = 1)
    if state <= length(r)
        return r[state], state + 1
    else
        return nothing
    end
end


"""
    DynamicRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements change overtime.
"""
abstract type DynamicRecord{V,T,N} <: AbstractRecord{V,T,N} end

"""
    StaticRecord{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes arrays whose elements never change but
insert or delete.
"""
abstract type StaticRecord{V,T,N} <: AbstractRecord{V,T,N} end


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
tspan(v::StaticView) = v.e -v.s
xs(v::StaticView) = [v.x, v.x]
ts(v::StaticView) = [v.s, v.e]


"""
    AbstractChange{V,I}
"""
abstract type AbstractChange{V<:Number,I} end

struct EleChange{V,I} <: AbstractChange{V,I}
    x::V
    i::I
end

struct DelChange{I} <: AbstractChange{Number,I}
    i::I
end

struct PushChange{V} <: AbstractChange{V,Int}
    x::V
end

function record!(r::AbstractRecord, t::Real, cs::AbstractChange...)
    for c in cs
        record!(r, t, c)
    end
    return r
end

mutable struct TypeBox{T}
    x::T
end

Base.setindex

