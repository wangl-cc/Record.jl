abstract type AbstractRecord{V,T,C<:AbstractClock{T},E<:AbstractEntry{V,T},N} <:
    AbstractArray{E,N} end

Base.size(r::AbstractRecord) = convert(NTuple{ndims(r),Int}, _size(r))
function Base.setindex!(r::AbstractRecord{V,T,C,E,N}, v, I::Vararg{Int,N}) where {V,T,C,E,N}
    e = r[I...]
    store!(e, v, r.c)
    return r
end

struct ScalarRecord{V,T,C,E} <: AbstractRecord{V,T,C,E,0}
    c::C
    e::E
    function ScalarRecord(c::C, e::E) where {V,T,C<:AbstractClock{T},E<:AbstractEntry{V,T}}
        return new{V,T,C,E}(c, e)
    end
end

_size(::ScalarRecord) = Size()
function Base.getindex(r::ScalarRecord, I...)
    @boundscheck checkbounds(r, I...)
    return r.e
end
record(r::ScalarRecord) = r.e

struct VectorRecord{V,T,C,E} <: AbstractRecord{V,T,C,E,1}
    c::C
    es::Vector{E}
    indmap::Vector{Int}
    function VectorRecord(
        c::C,
        es::Vector{E},
        indmap::Vector,
    ) where {V,T,C<:AbstractClock{T},E<:AbstractEntry{V,T}}
        return new{V,T,C,E}(c, es, indmap)
    end
end

_size(r::VectorRecord) = Size(r.indmap)
function Base.getindex(r::VectorRecord, I...)
    @boundscheck checkbounds(r, I...)
    ind = @inbounds r.indmap[I...]
    return r.es[ind]
end
Base.sizehint!(r::VectorRecord, sz::Integer) = sizehint!(r.es, sz)
record(r::VectorRecord) = r.es

function Base.push!(r::VectorRecord, v)
    E = eltype(r)
    push!(r.es, E(r.c, v))
    push!(r.indmap, lastindex(r.es))
    return r
end
function Base.append!(r::VectorRecord, vs)
    len = length(r.es)
    E = eltype(r)
    append!(r.es, map(v -> E(r.c, v), vs)) # create a entry with clock and value and push it into es
    append!(r.indmap, len+1:len+length(vs)) # The index of entry is lastindex(es)
    return r
end
function Base.insert!(r::VectorRecord, i::Integer, v)
    E = eltype(r)
    push!(r.es, E(r.c, v))
    insert!(r.indmap, i, lastindex(r.es))
end
function Base.deleteat!(r::VectorRecord, inds...)
    for i in inds
        del!(r[i], r.c)
    end
    deleteat!(r.indmap, inds) # delete the index of deleted entry from index map
    return r
end
function Base.resize!(r::VectorRecord, nl::Integer)
    len = length(r)
    if nl > len
        E = eltype(r)
        append!(r.es, map(_ -> E(), len+1:nl))
        append!(r.indmap, len+1:nl)
    elseif nl != len
        if nl < 0
            throw(ArgumentError("new length must be ≥ 0"))
        end
        for i in nl+1:len
            del!(r[i], r.c)
        end
        Base._deleteend!(r.indmap, len-nl)
    end
    return r
end

const DOK{T,N} = Dict{NTuple{N,Int},T}

struct DokRecord{V,T,C,E,N} <: AbstractRecord{V,T,C,E,N}
    c::C
    dok::DOK{E,N}
    sz::Size{N}
    rsz::Size{N}
    indmap::IndexMap{N}
    function DokRecord(
        c::C,
        dok::Dict{NTuple{N,Int},E},
        sz::Size{N},
        rsz::Size{N},
        indmap::IndexMap{N},
    ) where {V,T,C<:AbstractClock{T},E<:AbstractEntry{V,T},N}
        return new{V,T,C,E,N}(c, dok, sz, rsz, indmap)
    end
end

_size(r::DokRecord) = r.sz
record(r::DokRecord) = r.dok
function Base.getindex(r::DokRecord{V,T,C,E,N}, I::Vararg{Int,N}) where {V,T,C,E,N}
    @boundscheck checkbounds(r, I...)
    ind = @inbounds r.indmap[I...]
    return get!(r.dok, ind, E())
end
Base.sizehint!(r::DokRecord, sz::Integer) = sizehint!(r.dok, sz)

function pushdim!(r::DokRecord, dim::Integer, n::Integer)
    r.rsz[dim] += n
    ind = _size(r)[dim] += n
    pushdim!(r.indmap, dim, ind-n+1:ind)
    return r
end
function deletedim!(r::DokRecord, dim::Integer, inds)
    _inds = map(ind -> r.indmap(ind), inds)
    for (k, e) in r.dok
        k[dim] in _inds && del!(e, r.c)
    end
    _size(r)[dim] -= length(inds)
    deletedim!(r.indmap, dim, inds)
    return r
end

Base.show(io::IO, ::MIME"text/plain", r::AbstractRecord) = summary(io, r)
