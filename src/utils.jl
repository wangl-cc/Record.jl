"""
    Indices(sz::Dims{N}) -> R
    Indices(sz::Size{N}) -> R
    Indices(sz::NTuple{N,AbstractVector{Int}}) -> R

A `CartesianIndices` like type with mutable and disconnected region.

# Examples
```jldoctest
julia> im = Indices((2, 2))
2×2 Indices{2}:
 (1, 1)  (1, 2)
 (2, 1)  (2, 2)

julia> foreach(println, im)
(1, 1)
(2, 1)
(1, 2)
(2, 2)
```
"""
struct Indices{N} <: AbstractArray{CartesianIndex{N},N}
    indices::NTuple{N,Vector{Int}}
end
Indices(indices::NTuple{N,AbstractVector{Int}}) where {N} = Indices(map(collect, indices))
Indices(sz::Dims{N}) where {N} = Indices(map(Base.OneTo, sz))
Indices(sz::Size{N}) where {N} = Indices(sz.sz)

Base.size(im::Indices) = map(length, im.indices)

Base.@propagate_inbounds Base.getindex(im::Indices{N}, I::Vararg{Int,N}) where {N} =
    CartesianIndex(map(getindex, im.indices, I))

# DOKArray
const DOK{T,N} = Dict{Dims{N},T}
ResizingTools.isresizable(::Type{<:DOK}) = True()

struct DOKSparseArray{T,N} <: ResizingTools.AbstractRNArray{T,N}
    dok::DOK{T,N}
    sz::Size{N}
end

Base.parent(A::DOKSparseArray) = A.dok
ArrayInterface.parent_type(::Type{<:DOKSparseArray{T,N}}) where {T,N} = DOK{T,N}
ResizingTools.getsize(A::DOKSparseArray{T,N}) where {T,N} = A.sz
ResizingTools.size_type(::Type{<:DOKSparseArray{T,N}}) where {T,N} = Size{N}

function Base.getindex(A::DOKSparseArray{T,N}, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, I...)
    return get(A.dok, I, zero(T))
end
# this methods not used in this package
function Base.setindex!(A::DOKSparseArray{T,N}, v, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, I...)
    return A[I] = v
end

# Tools
function Base.get!(A::DOKSparseArray{T,N}, I::Dims{N}, v::T) where {T,N}
    @boundscheck checkbounds(A, I...)
    return get!(A.dok, I, v)
end
Base.get(A::DOKSparseArray{T,N}, I::Dims{N}, default::T) where {T,N} =
    get(parent(A), I, default)
function ResizingTools.resize_buffer!(A::DOKSparseArray{T,N}, sz::Vararg{Any,N}) where {T,N}
    sz′ = to_dims(sz)
    @boundscheck all(map(<=, size(A), sz′)) && throw(ArgumentError("new size must large than the old one"))
    setsize!(A, sz′)
    return A
end
function ResizingTools.resize_buffer_dim!(A::DOKSparseArray, d::Int, n)
    n′ = to_dims(n)
    @boundscheck ResizingTools.check_dimbounds(A, d, n′)
    setsize!(A, d, n′)
    return A
end
