abstract type AbstractRecord{E<:AbstractEntry,N,C<:AbstractClock} <:
              ResizingTools.AbstractRNArray{E,N} end
const Record = AbstractRecord

function Base.getindex(r::AbstractRecord{E,N,C}, I::Vararg{Int,N}) where {E,N,C}
    Base.@_propagate_inbounds_meta
    I′ = to_entryind(r, I...)
    return getentry(r, I′...)
end
function Base.setindex!(r::AbstractRecord{E,N,C}, v, I::Vararg{Int,N}) where {E,N,C}
    Base.@_propagate_inbounds_meta
    I′ = to_entryind(r, I...)
    e = getentry!(r, I′...)
    store!(e, v, r.c)
    return r
end

delat!(r::AbstractRecord{<:DynamicEntry}, ::Any...) = r
function delat!(r::AbstractRecord, inds...)
    t = currenttime(getclock(r))
    for entry in r[inds...]
        del!(entry, t)
    end
    return r
end

newentry(r::AbstractRecord{E}) where {E} = Base.Fix2(E, getclock(r))
newentry(r::AbstractRecord{E}, v) where {E} = E(v, getclock(r))

const AbstractScalar{T} = AbstractArray{T,0}
struct ScalarRecord{E<:AbstractEntry,C<:AbstractClock} <: AbstractRecord{E,0,C}
    c::C
    e::E
end
Record{E}(c::AbstractClock, v::AbstractScalar) where {E<:AbstractEntry} =
    ScalarRecord(c, E(v[1], c))
Record{E}(c::AbstractClock, v::Number) where {E<:AbstractEntry} = ScalarRecord(c, E(v, c))

Base.parent(r::ScalarRecord) = r.e
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
function Record{E}(c::AbstractClock, state::AbstractVector) where {E<:AbstractEntry}
    es = map(v -> E(v, c), state)
    im = collect(Base.OneTo(state))
    return VectorRecord(c, es, im)
end

Base.parent(r::VectorRecord) = r.es
ResizingTools.getsize(r::VectorRecord) = (length(r.im),)
Base.@propagate_inbounds to_entryind(r::VectorRecord, I::Int) = (r.im[I],)
Base.@propagate_inbounds getentry(r::VectorRecord, i′::Int) = r.es[i′] # i′ is parent index
Base.@propagate_inbounds getentry!(r::VectorRecord, i′::Int) = r.es[i′] # i′ is parent index
getclock(r::VectorRecord) = r.c

Base.sizehint!(r::VectorRecord, sz::Integer) = sizehint!(r.es, sz)
function Base.push!(r::VectorRecord, v)
    push!(r.es, newentry(r, v))
    push!(r.im, lastindex(r.es))
    return r
end
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
        if nl < 0
            throw(ArgumentError("new length must be ≥ 0"))
        end
        delat!(r, nl+1:len)
        resize!(r.im, len - nl)
    end
    return r
end

struct DokRecord{E<:AbstractEntry,N,C<:AbstractClock} <: AbstractRecord{E,N,C}
    c::C
    dok::DOKSparseArray{E,N}
    sz::Size{N}
    im::Indices{N}
end
function Record{E}(c::AbstractClock, A::AbstractArray) where {E<:AbstractEntry}
    sz = Size(A)
    dok = Dict{NTuple{ndims(A),Int},E}()
    for (i, ind) in enumerate(Indices(sz))
        dok[ind] = E(state[i], c)
    end
    dok_array = DOKSparseArray(dok, size(A))
    im = Indices(A)
    return DokRecord(c, dok_array, sz, im)
end
Base.parent(r::DokRecord) = r.dok
ResizingTools.getsize(r::DokRecord) = r.sz
ResizingTools.size_type(::Type{T}) where {T<:DokRecord} = Size{ndims(T)}

to_entryind(r::DokRecord{E,N}, I::Vararg{Int,N}) where {E,N} =
    (Base.@_propagate_inbounds_meta; r.im[I...])
getentry(r::DokRecord) = r.dok
getentry(r::DokRecord{E,N}, I::Vararg{Int,N}) where {E,N} = get(parent(r), I, E())
getentry!(r::DokRecord{E,N}, I::Vararg{Int,N}) where {E,N} = get!(parent(r), I, E())
getclock(r::DokRecord) = r.c

function ResizingTools.pre_resize!(r::DokRecord{E,N}, inds::Vararg{Any,N}) where {E,N}
    sz = size(r)
    nsz = to_dims(inds)
    psz = size(parent(r))
    for ind in CartesianIndices(r)
        # del entries that are no longer in the new size
        _checkindices(inds, ind.I) || delat!(r, ind)
    end
    for i in 1:N # change im
        diff = nsz[i] - sz[i]
        if diff > 0
            append!(r.im[i], psz[i]-diff:psz[i])
        elseif diff < 0
            resize!(r.im[i], (inds[i],))
        end
    end
    return r
end
function ResizingTools.pre_resize!(r::DokRecord, d::Integer, I)
    n = size(r, d)
    nn = to_dims(I)
    pn = size(parent(r))
    for ind in CartesianIndices(r)
        # del entries that are no longer in the new size
        _checkindices(I, ind[d]) || delat!(r, ind)
    end
    diff = nn - n
    if diff > 0
        append!(r.im[d], pn[d]-diff:pn[d])
    elseif diff < 0
        resize!(r.im[d], (I,))
    end
    return r
end

_checkindices(inds::Tuple, I::Dims) = all(map(_checkindex, inds, I))
_checkindex(ind, i::Int) = checkindex(Bool, ind, i)
_checkindex(ind::Integer, i::Int) = checkindex(Bool, Base.OneTo(ind), i)

ResizingTools.to_parentinds(r::DokRecord, Is::Tuple) =
    map(_to_parentind, size(r), size(parent(r)), Is)

_to_parentind(::Int, pn::Int, ::Any) = pn
_to_parentind(n::Int, pn::Int, nn::Int) = (d = nn - n; d > 0 ? pn + d : pn)

Base.show(io::IO, ::MIME"text/plain", r::AbstractRecord) = summary(io, r)
