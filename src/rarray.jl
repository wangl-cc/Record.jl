"""
    AbstractRecArray{T,N}

Supertype of recorded `N`-dimensional arrays with elements of type `T`,
whose changes will be recorded automatically.

!!! note
    
    Avoid to mutate recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRecArray{T,N} <: AbstractRDArray{T,N} end # Dense for Array math
# type alias
const AbstractRecScalar{T} = AbstractRecArray{T,0}
const AbstractRecVector{T} = AbstractRecArray{T,1}

# array interface
Base.IndexStyle(::Type{<:AbstractRecArray}) = IndexLinear()
Base.@propagate_inbounds Base.getindex(A::AbstractRecArray, i::Int) = parent(A)[i]
Base.@propagate_inbounds Base.setindex!(A::AbstractRecArray, v, i::Int) =
    (getrecord(A)[i] = v; parent(A)[i] = v)
## elsize and unsafe_convert have defined for AbstractRDArray in ResizingTools

# parent interface
ArrayInterface.parent_type(::Type{A}) where {A<:AbstractRecArray} = Vector{eltype(A)}
# size interface
ResizingTools.getsize(A::AbstractRecArray) = getsize(getrecord(A))
# This a trick, setsize! is used to resize its another parent
# Besides, the size of RArray is stored in record,
# so overriding setsize! also avoids changing size twice
ResizingTools.setsize!(A::AbstractRecArray{T,N}, sz::NTuple{N,Any}) where {T,N} =
    resize!(getrecord(A), sz)
ResizingTools.setsize!(A::AbstractRecArray, d::Integer, n) = resize!(getrecord(A), d, n)

# this methods may be unsafe because of the state
ResizingTools.copyto_parent!(dst::AbstractRecArray, src::AbstractArray, dinds...) =
    copyto!(view(state(dst), dinds...), src)

# showarg
function Base.showarg(io::IO, ::A, toplevel) where {T,N,A<:AbstractRecArray{T,N}}
    toplevel || print(io, "::")
    print(io, "recorded(::")
    print(io, Array{T,N})
    print(io, ')')
    return nothing
end

_unpack(A::AbstractRecArray) = _unpack(getentries(A))

"""
    state(A::AbstractRecArray{T,N}) -> Array{T,N}
    state(x::RecordedNumber{T}) -> T

Get current state of a recorded array `A` or a recorded number `x`.

!!! note
    
    `state` for `AbstractRecArray{V,T,N}` where `N >= 2` may be unsafe because of
    `unsafe_wrap` and `unsafe_convert`.
"""
state

# Note:
# `parent` is an internal API called by other function
# `state` is an export api called by user
# the return of `parent` should be a vector
# but the return of `state` should be a array with the same dimensions
@inline state(A::AbstractRecVector) = parent(A)
@inline state(A::AbstractRecArray{T,N}) where {T,N} = # may be unsafe
    unsafe_wrap(Array{T,N}, Base.unsafe_convert(Ptr{T}, A), size(A))

"""
    getentries(A::AbstractRecArray)

Get entries of a recorded array `A`.
"""
getentries(A::AbstractRecArray) = parent(getrecord(A))

"""
    recorded(E, c::AbstractClock, A)

Create a recorded array (or number) with entry of type `E` and clock `c`.
"""
recorded

# RArrays
struct RArray{T,N,R} <: AbstractRecArray{T,N}
    state::Vector{T}
    record::R
end
RArray(state::Vector{T}, record::R) where {T,E,N,R<:AbstractRecord{E,N}} =
    RArray{T,N,R}(state, record)
function recorded(::Type{E}, c::AbstractClock, A::AbstractArray) where {E<:AbstractEntry}
    state = similar(vec(A))
    copyto!(state, A)
    return RArray(state, Record{E}(c, A))
end

const RVector{V,R} = RArray{V,1,R}
const RMatrix{V,R} = RArray{V,2,R}

Base.parent(A::RArray) = A.state
getrecord(A::RArray) = A.record

# linear resize! and sizehint!
# cartisian resize! and sizehint! defined in ResizingTools
Base.sizehint!(A::AbstractRecVector, sz::Integer) = sizehint!(parent(A), sz)
function Base.push!(A::AbstractRecVector, v)
    push!(parent(A), v)
    push!(getrecord(A), v)
    return A
end
function Base.append!(A::AbstractRecVector, vs)
    append!(parent(A), vs)
    append!(getrecord(A), vs)
    return A
end
function Base.insert!(A::AbstractRecVector, i::Integer, v)
    insert!(parent(A), i, v)
    insert!(getrecord(A), i, v)
    return A
end
function Base.deleteat!(A::AbstractRecVector, inds)
    deleteat!(parent(A), inds)
    deleteat!(getrecord(A), inds)
    return A
end
function Base.resize!(A::AbstractRecVector, nl::Integer)
    resize!(parent(A), nl)
    resize!(getrecord(A), nl)
    return A
end
