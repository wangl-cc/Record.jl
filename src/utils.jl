# Size
mutable struct Size{N}
    sz::NTuple{N,Int}
end
@inline Size(I::Int...) = Size(I)
@inline Size(A::AbstractArray) = Size(size(A))

const USize{N} = Union{Size{N},NTuple{Integer,N}}
_totuple(sz::Size) = sz.sz
_totuple(sz::Tuple{Vararg{Integer}}) = sz

@inline Base.length(::Size{N}) where {N} = N
@inline Base.convert(::Type{T}, sz::Size) where {T<:Tuple} = convert(T, sz.sz)
@inline Base.map(f, sz::Size) = map(f, _totuple(sz))
@inline Base.map(f, sz1::USize, sz2::Usize) = map(f, _totuple(sz1), _totuple(sz2))
for op in (:(==), :(<),)
    @eval @inline Base.$op(sz1::USize, sz2::USize) = $op(_totuple(sz1), _totuple(sz2))
end
_resize!(sz::Size{N}, nsz::NTuple{N,Int}) where {N} = sz.sz = nsz

# The below two methods is a modifaction of `MArray` in `StaticArrays.jl`
# https://github.com/JuliaArrays/StaticArrays.jl/blob/master/src/MArray.jl#L80
function Base.getindex(sz::Size{N}, i::Int) where {N}
    @boundscheck 1 <= i <= N || throw(BoundsError(sz, i))
    return GC.@preserve sz unsafe_load(
        Base.unsafe_convert(Ptr{Int}, pointer_from_objref(sz)),
        i,
    )
end

function Base.setindex!(sz::Size{N}, v, i::Int) where {N}
    @boundscheck 1 <= i <= N || throw(BoundsError(sz, i))
    return GC.@preserve sz unsafe_store!(
        Base.unsafe_convert(Ptr{Int}, pointer_from_objref(sz)),
        convert(Int, v),
        i,
    )
end

# IndexMap
struct IndexMap{N} <: AbstractArray{Int,N}
    Is::NTuple{N,Vector{Int}}
end
IndexMap(axes::NTuple{N,AbstractVector{Int}}) where {N} = IndexMap(map(collect, axes))
IndexMap(sz::NTuple{N,Int}) where {N} = IndexMap(map(Base.OneTo, sz))
IndexMap(sz::Size{N}) where {N} = IndexMap(sz.sz)

Base.size(indmap::IndexMap) = map(length, indmap.Is)

function Base.getindex(indmap::IndexMap{N}, I::Vararg{Int,N}) where {N}
    @boundscheck checkbounds(indmap, I...)
    return @inbounds map(getindex, indmap.Is, I)
end

function pushdim!(indmap::IndexMap, dim::Integer, ind::Integer)
    push!(indmap.Is[dim], ind)
    return indmap
end
function pushdim!(indmap::IndexMap, dim::Integer, inds)
    append!(indmap.Is[dim], inds)
    return indmap
end
function deletedim!(indmap::IndexMap, dim::Integer, inds)
    deleteat!(indmap.Is[dim], inds)
    return indmap
end
function insertdim!(indmap::IndexMap, dim::Integer, i::Integer, ind::Integer)
    insert!(indmap.Is[dim], i, ind)
    return indmap
end

# DOKArray
struct DOKSpraseArray{T,N} <: AbstractArray{T,N}
    dok::Dict{NTuple{N,Int},T}
    sz::Size{N}
end
_dok(A::DOKSpraseArray) = A.dok

Base.size(A::DOKSpraseArray{T,N}) where {T,N} = convert(NTuple{N,Int}, A.sz)
Base.size(A::DOKSpraseArray, d::Integer) = A.sz[d]
function Base.getindex(A::DOKSpraseArray{T,N}, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, I...)
    return get(A.dok, I, zero(T))
end
# Tools
function Base.get!(A::DOKSpraseArray{T,N}, I::NTuple{N,Int}, v::T) where {T,N}
    @boundscheck checkbounds(A, I...)
    return get!(A.dok, I, v)
end
Base.sizehint!(A::DOKSpraseArray, sz::Integer) = sizehint!(A, sz)
function Base.resize!(A::DOKSpraseArray{T,N}, sz::Vararg{Integer,N}) where {T,N}
    A.sz <= sz && throw(ArgumentError("new size must large than the old one"))
    return _resize!(A.sz, sz)
end