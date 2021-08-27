"""
    AbstractRArray{V,T,N} <: DenseArray{V,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and time of type `T`", whose changes will be recorded automatically.

!!! note

    Avoid to edit recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRArray{V,T<:Real,N} <: DenseArray{V,N} end # Dense for Array math

# type alias
const AbstractRScalar{V,T} = AbstractRArray{V,T,0}
const AbstractRVector{V,T} = AbstractRArray{V,T,1}
const AbstractRMatrix{V,T} = AbstractRArray{V,T,2}

# API
timetype(::Type{<:AbstractRArray{<:Any,T}}) where {T} = T

"""
    state(A::AbstractRArray{V,T,N}) -> Array{V,N}

Get current state of recorded array `A`. API for mathematical operations.

!!! note

    `state` for `AbstractRArray{V,T,N}` where `N >= 2` is unsafe because of
    `unsafe_wrap` and `unsafe_convert`.
"""
function state end

# Note:
# `_state` is a internal API which will be called by other function in this Package
# state is a export api which will be called by user
# the return of `_state` should be a vector (for array rank >= 1) or a number (for scalar),
# but the return of `state` should be a array with the same size
state(A::AbstractRScalar) = _state(A)
state(A::AbstractRVector) = _state(A)
state(A::AbstractRArray{V,T,N}) where {V,T,N} = # maybe unsafe
    unsafe_wrap(Array{V,N}, Base.unsafe_convert(Ptr{V}, A), _size(A))
@inline state(As::Tuple) = map(state, As)

"""
    setclock!(A::AbstractRArray, c::AbstractClock)

Assign the clock of `A` to `c`. Type of `c` should be the same as old one.
"""
setclock!(A::AbstractRArray, c::AbstractClock) = _setclock!(A, c)
_setclock!(A::AbstractRArray, c::AbstractClock) = A.t = c

"""
    setclock!(A::AbstractRArray, c::AbstractClock)

Non-mutating setclock for `A`. It will create a deepcopy of `A` besides
the clock field, which will be assigned to `c`.
"""
setclock(A::AbstractRArray, c::AbstractClock) = (Ac = deepcopy(A); setclock!(Ac, c); Ac)

# internal API
@inline _state(A::AbstractRArray) = A.v
@inline _state(A::AbstractArray) = A
@inline _length(A::AbstractRArray) = length(_state(A))
@inline _size(::AbstractRScalar) = ()
@inline _size(A::AbstractRVector) = (_length(A),)
@inline _size(A::AbstractRArray) = convert(Tuple, A.sz)

# Abstract Arrays interfaces
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = _length(A)
Base.size(A::AbstractRArray) = _size(A)
Base.getindex(A::AbstractRArray, i::Int) = getindex(_state(A), i)
# Strided Arrays interfaces
## strides(A) and stride(A, i::Int) have definded for DenseArray
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, _state(A))
Base.elsize(::Type{<:AbstractRArray{T}}) where {T} = Base.elsize(Array{T})

convert_array(::Type{T}, x::T) where {T} = x
convert_array(::Type{T}, x) where {T} = convert(T, x)
convert_array(::Type{T}, x::Array{T}) where {T} = x
convert_array(::Type{T}, x::AbstractArray{<:Any,N}) where {T,N} = convert(Array{T,N}, x)
# vim:tw=92:ts=4:sw=4:et
