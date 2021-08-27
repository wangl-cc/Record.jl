abstract type AbstractRecord{V,T,E <: AbstractEntry{V,T},N} <: AbstractArray{E,N} end

function storeat!(r::AbstractRecord{V,T}, t::T, v::V, I...) where {V,T}
    e = _getentry(r, I...)
    store!(e, t, V)
    return r
end

"""
    record(A::AbstractRArray) -> AbstractRecord

Get the record of given RecordedArray `A`.
"""
function record end

struct ScalarRecord{V,T,E} <: AbstractRecord{V,T,E,0}
    e::E
end

Base.size(::ScalarRecord) = ()
Base.getindex(r::ScalarRecord) = r.e

_getentry(r::ScalarRecord) = r.e

struct VectorRecord{V,T,E} <: AbstractArray{V,T,E,1}
    es::Vector{E}
    indmap::Vector{Int}
    function VectorRecord(es::Vector{E}, indmap::Vector) where {V,T,E <: AbstractEntry{V,T}}
        return new{V,T,E}(es, indmap)
    end
end

Base.size(r::VectorRecord) = size(r.es)
Base.getindex(r::VectorRecord, i::Int) = r.es[i]

_getentry(r::VectorRecord, i::Int) = (ind = r.indmap[i]; r.es[ind])

function _pushentry!(r::VectorRecord{V,T,E}, c::AbstractClock{T}, v::V) where {V,T,E}
    push!(r.es, E(c, v))
    push!(r.indmap, length(r.es))
    return r
end
function _deleteentry!(r::VectorRecord, i::Integer)
    deleteat!(r.indmap, i)
    return r
end

struct DokRecord{V,T,E,N} <: AbstractRecord{V,T,E,N}
    dok::Dict{NTuple{N,Int},E}
    sz::Size{N}
    indmap::IndexMap{N}
end

Base.size(r::DokRecord) = convert(Tuple, r.sz)
function Base.getindex(r::DokRecord{V,T,E,N}, I::Vararg{Int,N}) where {V,T,E,N}
    return get(r.dok, I, missval(E))
end

_getentry(r::DokRecord, I...) = (ind = r.indmap[I]; r.dok[ind])

Base.show(io::IO, ::MIME"text/plain", r::AbstractRecord) = summary(io, r)
