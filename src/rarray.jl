"""
    AbstractRecArray{V,R,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and record of type `R`", whose changes will be recorded automatically.

!!! note

    Avoid to mutate recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRecArray{T,N} <: AbstractRDArray{T,N} end # Dense for Array math
# type alias
const AbstractRecScalar{T} = AbstractRecArray{T,0}
const AbstractRecVector{T} = AbstractRecArray{T,1}

# array interface
Base.IndexStyle(::Type{T<:AbstractRecArray}) where {T} = IndexLinear()
Base.@propagate_inbounds Base.getindex(A::AbstractRecArray, i::Int) = parent(A)[i]
Base.@propagate_inbounds Base.setindex!(A::AbstractRecArray, v, i::Int) =
    (getrecord(A)[i] = v; parent(A)[i] = v)
## elsize and unsafe_convert have defined for AbstractRDArray in ResizingTools

# parent interface
Base.parent(A::AbstractRecArray) = _state(A)
ArrayInterface.parent_type(::Type{T}) where {T<:AbstractRecArray} = Vector{eltype(T)}
# size interface
ResizingTools.getsize(A) = getsize(getrecord(A))
# This a trick, setsize! is used to resize its another parent
# Besides, the size of RArray is stored in record,
# so overriding setsize! also avoids changing size twice
ResizingTools.setsize!(A::AbstractArray{T,N}, sz::NTuple{N,Any}) where {T,N} =
    resize!(getrecord(A), sz)
ResizingTools.setsize!(A::AbstractArray, d::Integer, n) =
    resize!(getrecord(A), d, n)
# showarg
function Base.showarg(io::IO, ::A, toplevel) where {T,N,A<:AbstractRecArray{T,N}}
    toplevel || print(io, "::")
    print(io, "recorded(::")
    print(io, Array{T,N})
    print(io, ')')
    return nothing
end

# resize!

"""
    state(A::AbstractRArray{V,R,N}) -> Array{V,N}

Get current state of recorded array `A`. API for mathematical operations.

!!! note

    `state` for `AbstractRArray{V,T,N}` where `N >= 2` might be unsafe because of
    `unsafe_wrap` and `unsafe_convert`.
"""
state

# Note:
# `_state` is a internal API which will be called by other function
# state is a export api which will be called by user
# the return of `_state` should be a vector
# but the return of `state` should be a array with the same dimensions
@inline state(A::AbstractRecVector) = _state(A)
@inline state(A::AbstractRecArray{V,T,N}) where {V,T,N} = # may unsafe
    unsafe_wrap(Array{V,N}, Base.unsafe_convert(Ptr{V}, A), size(A))

"""
    getentries(A::AbstractRArray)

Get the array of entries of given Array `A`.
"""
getentries(A::AbstractRecArray) = getrecord(getentries(A))

# internal methods
# core interfaces for RArray
@inline _state(A::AbstractArray) = A
@inline _length(A::AbstractRecArray) = length(_state(A))

"""
    recorded(E, c::AbstractClock, A)

Create a recorded array (or number) with entry of type `E` and clock `c`.
"""
recorded

# E with V
recorded(::Type{E}, c::AbstractClock{T}, A::AbstractArray) where {V,T,E<:AbstractEntry{V}} =
    recorded(E{T}, c, A)
# E without V or T
recorded(::Type{E}, c::AbstractClock{T}, A::AbstractArray{V}) where {V,T,E<:AbstractEntry} =
    recorded(E{V,T}, c, A)


# RArrays
struct RArray{V,R,N} <: AbstractRecArray{V,R,N}
    state::Vector{V}
    record::R
    function RArray(
        state::Vector{V},
        record::R,
    ) where {V,C,E<:AbstractEntry,N,R<:AbstractRecord{C,E,N}}
        return new{V,R,N}(state, record)
    end
end
function recorded(
    ::Type{E},
    c::AbstractClock,
    A::AbstractArray,
) where {V,T<:Real,E<:AbstractEntry{V,T}}
    state = similar(vec(A))
    copyto!(state, A)
    return RArray(state, Record{E}(c, state))
end

const RVector{V,R} = RArray{V,R,1}
const RMatrix{V,R} = RArray{V,R,2}

_state(A::RArray) = A.state
getrecord(A::RArray) = A.record

# linear resize! and sizehint!
# cartisian resize! and sizehint! defined in ResizingTools
Base.sizehint!(A::AbstractRecVector, sz::Integer) = sizehint!(_state(A), sz)
function Base.push!(A::AbstractRecVector, v)
    push!(_state(A), v)
    push!(getrecord(A), v)
    return A
end
function Base.append!(A::AbstractRecVector, vs)
    append!(_state(A), vs)
    append!(_state(A), vs)
    return A
end
function Base.insert!(A::AbstractRecVector, i::Integer, v)
    insert!(_state(A), i, v)
    insert!(getrecord(A), i, v)
    return A
end
function Base.deleteat!(A::AbstractRecVector, inds)
    deleteat!(_state(A), inds)
    deleteat!(getrecord(A), inds)
    return A
end
function Base.resize!(A::AbstractRecVector, nl::Integer)
    resize!(_state(A), nl)
    resize!(getrecord(A), nl)
    return A
end
