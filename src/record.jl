abstract type AbstractRecord{E<:AbstractEntry,N,C<:AbstractClock} <:
              ResizingTools.AbstractRNArray{E,N} end
const Record = AbstractRecord

newentry(r::AbstractRecord{E}) where {E} = Base.Fix2(E, currenttime(getclock(r)))
newentry(r::AbstractRecord{E}, v) where {E} = E(v, currenttime(getclock(r)))

function Base.getindex(r::AbstractRecord{E,N,C}, I::Vararg{Int,N}) where {E,N,C}
    Base.@_propagate_inbounds_meta
    I′ = to_entryind(r, I...)
    return getentry(r, I′...)
end
function Base.setindex!(r::AbstractRecord{E,N,C}, v, I::Vararg{Int,N}) where {E,N,C}
    Base.@_propagate_inbounds_meta
    I′ = to_entryind(r, I...)
    e = getentry!(r, I′...)
    store!(e, v, getclock(r))
    return r
end

delat!(r::AbstractRecord{<:DynamicEntry}, ::Any...) = r
function delat!(r::AbstractRecord, inds...)
    t = currenttime(getclock(r))
    _delall!(r[inds...], t)
    return r
end

_delall!(e::AbstractEntry, t::Real) = (del!(e, t); e)
function _delall!(es, t::Real)
    for entry in es
        del!(entry, t)
    end
    return es
end

const AbstractScalar{T} = AbstractArray{T,0}
struct ScalarRecord{E<:AbstractEntry,C<:AbstractClock} <: AbstractRecord{E,0,C}
    c::C
    e::E
end
Record{E}(c::AbstractClock, s::AbstractScalar) where {E<:AbstractEntry} =
    ScalarRecord(c, E(s[1], c))
Record{E}(c::AbstractClock, v::Number) where {E<:AbstractEntry} = ScalarRecord(c, E(v, c))

Base.parent(r::ScalarRecord) = r.e
ArrayInterface.parent_type(::Type{R}) where {E,R<:ScalarRecord{E}} = E
ResizingTools.getsize(::ScalarRecord) = ()
to_entryind(::ScalarRecord) = ()
getentry(r::ScalarRecord) = r.e
getentry!(r::ScalarRecord) = r.e
getclock(r::ScalarRecord) = r.c

struct VectorRecord{E<:AbstractEntry,C<:AbstractClock} <: AbstractRecord{E,1,C}
    c::C
    es::Vector{E}
    im::Vector{Int}
end
function Record{E}(c::AbstractClock, v::AbstractVector) where {E<:AbstractEntry}
    es = map(v -> E(v, c), v)
    im = collect(Base.OneTo(length(v)))
    return VectorRecord(c, es, im)
end

Base.parent(r::VectorRecord) = r.es
ArrayInterface.parent_type(::Type{R}) where {E,R<:VectorRecord{E}} = Vector{E}
ResizingTools.getsize(r::VectorRecord) = (length(r.im),)
Base.@propagate_inbounds to_entryind(r::VectorRecord, I::Int) = (r.im[I],)
Base.@propagate_inbounds getentry(r::VectorRecord, i′::Int) = r.es[i′] # i′ is parent index
Base.@propagate_inbounds getentry!(r::VectorRecord, i′::Int) = r.es[i′] # i′ is parent index
getclock(r::VectorRecord) = r.c

function ResizingTools.resize_buffer!(A::VectorRecord{E}, I) where {E<:AbstractEntry}
    len = length(A)
    nl = to_dims(I)
    pl = length(parent(A))
    diff = nl - len
    if diff > 0
        append!(A.im, pl+1:pl+diff)
        append!(A.es, map(_ -> E(), 1:diff))
    elseif diff < 0
        delat!(A, _del_ind(len, I))
        resize!(A.im, (I,))
    end
    return A
end
function ResizingTools.resize_buffer_dim!(A::VectorRecord, d::Int, I)
    @boundscheck d == 1 || throw(BoundsError())
    return ResizingTools.resize_buffer!(A, I)
end

_del_ind(len::Int, ind::Integer) = Int(ind):len
_del_ind(len::Int, ind::Base.LogicalIndex) = Base.OneTo(len)[not(ind)]

Base.sizehint!(r::VectorRecord, sz::Integer) = sizehint!(r.es, sz)
function Base.push!(r::VectorRecord, v)
    push!(r.es, newentry(r, v))
    push!(r.im, lastindex(r.es))
    return r
end
Base.append!(r::VectorRecord{E}, v::V) where {V,E<:AbstractEntry{V}} = push!(r, v)
function Base.append!(r::VectorRecord, vs)
    len = length(r.es)
    append!(r.es, map(newentry(r), vs))
    append!(r.im, len+1:len+length(vs))
    return r
end
function Base.insert!(r::VectorRecord, i::Integer, v)
    push!(r.es, newentry(r, v))
    insert!(r.im, i, lastindex(r.es))
end
function Base.deleteat!(r::VectorRecord, inds)
    delat!(r, inds)
    deleteat!(r.im, inds)
    return r
end
function Base.resize!(r::VectorRecord, nl::Integer)
    len = length(r)
    if nl > len
        E = eltype(r)
        append!(r.es, map(_ -> E(), len+1:nl))
        append!(r.im, len+1:nl)
    elseif nl != len
        nl < 0 && throw(ArgumentError("new length must be ≥ 0"))
        delat!(r, nl+1:len)
        resize!(r.im, len - nl)
    end
    return r
end

struct DOKRecord{E<:AbstractEntry,N,C<:AbstractClock} <: AbstractRecord{E,N,C}
    c::C
    dok::DOKSparseArray{E,N}
    sz::Size{N}
    im::MCIndices{N}
end
function Record{E}(c::AbstractClock, A::AbstractArray) where {E<:AbstractEntry}
    sz = Size(A)
    dok = Dict{NTuple{ndims(A),Int},return_type(E, A, c)}()
    sizehint!(dok, prod(size(A)))
    for (i, ind) in enumerate(MCIndices(A))
        dok[ind] = E(A[i], c)
    end
    dok_array = DOKSparseArray(dok, Size(A))
    im = MCIndices(A)
    return DOKRecord(c, dok_array, sz, im)
end
Base.parent(r::DOKRecord) = r.dok
ArrayInterface.parent_type(::Type{R}) where {E,N,R<:DOKRecord{E,N}} = DOKSparseArray{E,N}
ResizingTools.getsize(r::DOKRecord) = r.sz
ResizingTools.size_type(::Type{T}) where {T<:DOKRecord} = Size{ndims(T)}

to_entryind(r::DOKRecord{E,N}, I::Vararg{Int,N}) where {E,N} =
    (Base.@_propagate_inbounds_meta; r.im[I...])
getentry(r::DOKRecord{E,N}, I::Vararg{Int,N}) where {E,N} = get(parent(r), I, E())
getentry!(r::DOKRecord{E,N}, I::Vararg{Int,N}) where {E,N} = get!(parent(r), I, E())
getclock(r::DOKRecord) = r.c

function ResizingTools.pre_resize!(r::DOKRecord{E,N}, inds::NTuple{N,Any}) where {E,N}
    sz = size(r)
    nsz = to_dims(inds)
    psz = size(parent(r))
    for ind in CartesianIndices(r)
        # del entries that are no longer in the new size
        _checkindices(inds, ind.I) || delat!(r, ind)
    end
    for d in 1:N # change im
        diff = nsz[d] - sz[d]
        if diff > 0
            append!(getdim(r.im, d), psz[d]+1:psz[d]+diff)
        elseif diff < 0
            resize!(getdim(r.im, d), (inds[d],))
        end
    end
    return r
end
function ResizingTools.pre_resize!(r::DOKRecord, d::Int, I)
    n = size(r, d)
    nn = to_dims(I)
    pn = size(parent(r), d)
    for ind in CartesianIndices(r)
        # del entries that are no longer in the new size
        _checkindex(I, ind[d]) || delat!(r, ind)
    end
    diff = nn - n
    if diff > 0
        append!(getdim(r.im, d), pn+1:pn+diff)
    elseif diff < 0
        resize!(getdim(r.im, d), (I,))
    end
    return r
end

_checkindices(inds::Tuple, I::Dims) = all(map(_checkindex, inds, I))
_checkindex(ind, i::Int) = i in ind
_checkindex(n::Integer, i::Int) = 1 <= i <= n

ResizingTools.to_parentinds(r::DOKRecord, Is::Tuple) =
    map(_to_parentind, size(r), size(parent(r)), Is)
ResizingTools.to_parentinds(r::DOKRecord, d::Integer, I) =
    Int(d), _to_parentind(size(r, d), size(parent(r), d), I)

_to_parentind(::Int, pn::Int, ::Any) = pn
_to_parentind(n::Int, pn::Int, nn::Int) = (d = nn - n; d > 0 ? pn + d : pn)

Base.show(io::IO, ::MIME"text/plain", r::AbstractRecord) = summary(io, r)
