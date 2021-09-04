abstract type AbstractRecord{C<:AbstractClock,E<:AbstractEntry,N} <:
    AbstractArray{E,N} end

Base.size(r::AbstractRecord) = convert(NTuple{ndims(r),Int}, _size(r))
function Base.getindex(r::AbstractRecord{C,E,N}, I::Vararg{Int,N}) where {C,E,N}
    @boundscheck checkbounds(r, I...)
    ind = _mapind(r, I...)
    e = _record(r, ind...)
    return e
end
function Base.setindex!(r::AbstractRecord{C,E,N}, v, I::Vararg{Int,N}) where {C,E,N}
    e = r[I...]
    store!(e, v, r.c)
    return r
end

delat!(r::AbstractRecord, c::AbstractClock, args...) =
    delat!(r, currenttime(c), args...)

struct ScalarRecord{C<:AbstractClock,E<:AbstractEntry} <: AbstractRecord{C,E,0}
    c::C
    e::E
end

_size(::ScalarRecord) = Size()
_record(r::ScalarRecord) = r.e
_clock(r::ScalarRecord) = r.c
_mapind(::ScalarRecord) = ()

struct VectorRecord{C<:AbstractClock,E<:AbstractEntry} <: AbstractRecord{C,E,1}
    c::C
    es::Vector{E}
    indmap::Vector{Int}
end

_size(r::VectorRecord) = Size(r.indmap)
_record(r::VectorRecord) = r.es
_record(r::VectorRecord, i::Int) = @inbounds r.es[i]
_clock(r::VectorRecord) = r.c
_mapind(r::VectorRecord, i::Int) = @inbounds (r.indmap[i],)

Base.sizehint!(r::VectorRecord, sz::Integer) = sizehint!(r.es, sz)

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
function Base.deleteat!(r::VectorRecord, inds)
    delat!(r, r.c, inds)
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
        delat!(r, r.c, nl+1:len)
        Base._deleteend!(r.indmap, len-nl)
    end
    return r
end

function delat!(v::VectorRecord, t::Real, inds)
    for ind in inds
        del!(v[ind], t)
    end
end
delat!(v::VectorRecord{C,E}, ::Real, ::Any) where {C,E<:DynamicEntry} = v

struct DokRecord{C<:AbstractClock,E<:AbstractEntry,N} <: AbstractRecord{C,E,N}
    c::C
    dok::DOKSpraseArray{E,N}
    sz::Size{N}
    indmap::IndexMap{N}
end
function DokRecord(
    c::C,
    dok::Dict{NTuple{N,Int},E},
    sz::Size{N},
    rsz::Size{N},
    indmap::IndexMap{N},
) where {C<:AbstractClock,E<:AbstractEntry,N}
    return DokRecord{C,E,N}(c, DOKSpraseArray(dok, rsz), sz, indmap)
end

_size(r::DokRecord) = r.sz
_record(r::DokRecord) = r.dok
_clock(r::DokRecord) = r.c
_mapind(r::DokRecord{C,E,N}, I::Vararg{Int,N}) where {C,E,N} = r.indmap[I...]
_record(r::DokRecord{C,E,N}, I::Vararg{Int,N}) where {C,E,N} = get!(r.dok, I, E())
Base.sizehint!(r::DokRecord, sz::Integer) = sizehint!(r.dok, sz)

function pushdim!(r::DokRecord, d::Integer, n::Integer)
    ind = _size(r)[d] += n
    pushdim!(r.indmap, d, ind-n+1:ind)
    pushdim!(r.dok, d, n)
    return r
end
function deletedim!(r::DokRecord, d::Integer, inds)
    delat!(r.dok, r.c, d, inds)
    _size(r)[d] -= length(inds)
    deletedim!(r.indmap, d, inds)
    return r
end

function delat!(r::DokRecord, t::Real, d::Integer, inds)
    _inds = map(ind -> r.indmap(ind), inds)
    for (k, e) in _dok(_record(r))
        k[d] in _inds && del!(e, t)
    end
    return r
end
delat!(A::DokRecord{C,E}, ::Real, ::Integer, ::Any) where {C,E<:DynamicEntry} = A

Base.show(io::IO, ::MIME"text/plain", r::AbstractRecord) = summary(io, r)
