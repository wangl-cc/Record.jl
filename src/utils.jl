# Size
mutable struct Size{N}
    sz::NTuple{N,Int}
end
@inline Size(I::Int...) = Size(I)
@inline Size(A::AbstractArray) = Size(size(A))

@inline Base.length(::Size{N}) where {N} = N
@inline Base.convert(::Type{T}, sz::Size) where {T<:Tuple} = convert(T, sz.sz)
@inline Base.map(f, sz::Size) = map(f, sz.sz)
@inline Base.:(==)(sz1::Size, sz2::Size) = sz1.sz == sz2.sz

# The below two methods is a modifaction of `MArray` in `StaticArrays.jl`
# https://github.com/JuliaArrays/StaticArrays.jl/blob/master/src/MArray.jl#L80
function Base.getindex(sz::Size{N}, i::Integer) where {N}
    @boundscheck 1 <= i <= N || throw(BoundsError(sz, i))
    return GC.@preserve sz unsafe_load(
        Base.unsafe_convert(Ptr{Int}, pointer_from_objref(sz)),
        i,
    )
end

function Base.setindex!(sz::Size{N}, v, i::Integer) where {N}
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
