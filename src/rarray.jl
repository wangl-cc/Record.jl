import Base: +, -, *, /, \, ^, conj, real, imag
import Base: adjoint, transpose

"""
    AbstractRArray{V,R,N} <: DenseArray{V,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and record of type `R`", whose changes will be recorded automatically.

!!! note

    Avoid to mutate recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRArray{V,R,N} <: DenseArray{V,N} end # Dense for Array math
# type alias
const AbstractRScalar{V,R} = AbstractRArray{V,R,0}
const AbstractRVector{V,R} = AbstractRArray{V,R,1}

# Abstract Arrays interfaces
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = length(_state(A))
Base.size(A::AbstractRArray) = convert(NTuple{ndims(A),Int}, _size(_record(A)))
Base.size(A::AbstractRArray, dim::Integer) = _size(_record(A))[dim]::Int
Base.getindex(A::AbstractRArray, I...) = getindex(_state(A), I...)
function Base.setindex!(A::AbstractRArray, v, I...)
    @boundscheck checkbounds(A, i)
    @inbounds _state(A)[I...] = v
    @inbounds _record(A)[I...] = v
    return v
end
Base.copyto!(dst::AbstractRArray, src) = copyto!(_state(dst), src)

_growend!(A::AbstractRArray, delta::Integer) = Base._growend!(_state(A), delta)
_deleteend!(A::AbstractRArray, delta::Integer) = Base._deleteend!(_state(A), delta)
# Strided Arrays interfaces
## strides(A) and stride(A, i::Int) have definded for DenseArray
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, _state(A))
Base.elsize(::Type{<:AbstractRArray{T}}) where {T} = Base.elsize(Array{T})
# show
function Base.summary(io::IO, A::T) where {T<:AbstractRArray}
    showdim(io, A)
    print(io, ' ')
    Base.show_type_name(io, T.name)
    print(io, '{')
    n = length(T.parameters)
    for i in 1:n
        p = T.parameters[i]
        if p isa Type && p <: AbstractRecord
            Base.show_type_name(io, p.name)
        else
            show(io, p)
        end
        i < n && print(io, ", ")
    end
    print(io, '}')
    return nothing
end

showdim(io::IO, ::AbstractArray{<:Any,0}) = print(io, "0-dimensional")
showdim(io::IO, A::AbstractVector) = print(io, length(A), "-element")
showdim(io::IO, A::AbstractArray) where {N} = join(io, size(A), '×')

# create RArrays
"""
"""
rarray(::Type{E}, c::AbstractClock, As...) where {E<:AbstractEntry} =
    map(A -> rarray(E, c, A), As)
# E with V
function rarray(
    ::Type{E},
    c::AbstractClock{T},
    A::AbstractArray
) where {V,T<:Real,E<:AbstractEntry{V}}
    return rarray(E{T}, c, A)
end
rarray(::Type{E}, c::AbstractClock{T}, A) where {V,T<:Real,E<:AbstractEntry{V}} =
    rarray(E{T}, c, fill(A))
# E without V or T
function rarray(
    ::Type{E},
    c::AbstractClock{T},
    A::AbstractArray{V}
) where {V,T<:Real,E<:AbstractEntry}
    return rarray(E{V,T}, c, A)
end
rarray(::Type{E}, c::AbstractClock{T}, A::V) where {V,T<:Real,E<:AbstractEntry} =
    rarray(E{V,T}, c, fill(A))

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
# the return of `_state` should be a vector (for array) or a scalar (for scalar),
# but the return of `state` should be a array with the same dimensions
state(A::AbstractRScalar) = @inbounds _state(A)[1]
state(A::AbstractRVector) = _state(A)
state(A::AbstractRArray{V,T,N}) where {V,T,N} = # may unsafe
    unsafe_wrap(Array{V,N}, Base.unsafe_convert(Ptr{V}, A), size(A))

"""
    record(A::AbstractRArray)

Get the record of given Array `A`.
"""
record(A::AbstractRArray) = _record(_record(A))

"""
    setclock(A::AbstractRArray, c::AbstractClock)

Non-mutating setclock for `A`, which will create a deepcopy of `A`, then 
assigned the clock field to `c`.
"""
setclock(A::T, c::AbstractClock) where {T<:AbstractRArray} =
    T(copy(_state(A)), setclock(_record(A), c))

# internal methods
# core interfaces for RArray
@inline _state(A::AbstractArray) = A
@inline _length(A::AbstractRArray) = length(_state(A))

# array math (most of which were implemented in arraymath) #
const URArray{T} = Union{Array{T},AbstractRArray{T}}

## Unary arithmetic operators ##
@inline +(A::AbstractRArray{<:Number}) = A # do nothing for better performance
@inline +(A::AbstractRScalar) = @inbounds _state(A)[1] # return Number for scalar
# force reutrn number for AbstractRScalar
for f in (:-, :conj, :real, :imag, :transpose, :adjoint)
    @eval @inline ($f)(r::AbstractRScalar) = ($f)(@inbounds _state(r)[1])
end

## Binary arithmetic operators ##
# +(A, B) and -(A, B) implemented in arraymath
# this is + for more than two args to avoid allocation by afoldl
# call broadcast directly instead of call state
@inline +(A::URArray, Bs::URArray...) = broadcast(+, A, Bs...)

# * / \ for Array and Number is in arraymath, there are interfaces for RScalar
for f in (:/, :\, :*)
    if f !== :/
        @eval @inline ($f)(A::AbstractRScalar, B::URArray) =
            $f(@inbounds _state(A)[1], B)
    end
    if f !== :\
        @eval @inline ($f)(A::URArray, B::AbstractRScalar) =
            $f(A, @inbounds _state(B)[1])
    end
end

# arithmetic operators for Number and RScalar
for f in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($f)(A::AbstractRScalar, B::AbstractRScalar) =
        @inbounds ($f)(_state(A)[1], _state(B)[1])
    @eval @inline ($f)(A::Number, B::AbstractRScalar) =
        @inbounds ($f)(A, _state(B)[1])
    @eval @inline ($f)(A::AbstractRScalar, B::Number) =
        @inbounds ($f)(_state(A)[1], B)
end

# RArrays
const AbstractScalar{T} = AbstractArray{T,0}
struct RScalar{V,R} <: AbstractRArray{V,R,0}
    state::Array{V,0}
    record::R
end
function RScalar(::Type{E}, c::AbstractClock, v::Array{<:Number,0}) where {E<:AbstractEntry}
    return RScalar(v, ScalarRecord(c, E(v[1], c)))
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::AbstractScalar,
) where {V,T<:Real,E<:AbstractEntry{V,T}}
    return RScalar(E, c, v)
end

_state(A::RScalar) = A.state
_record(A::RScalar) = A.record

struct RVector{V,R} <: AbstractRArray{V,R,1}
    state::Vector{V}
    record::R
end
function RVector(::Type{E}, c::AbstractClock, A::AbstractVector) where {E<:AbstractEntry}
    state = convert(Vector, A)
    es = map(v -> E(v, c), state)
    indmap = collect(1:length(state))
    record = VectorRecord(c, es, indmap)
    return RVector(state, record)
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::AbstractVector,
) where {V,T<:Real,E<:AbstractEntry{V,T}}
    return RVector(E, c, v)
end

_state(A::RVector) = A.state
_record(A::RVector) = A.record

struct RArray{V,R,N} <: AbstractRArray{V,R,N}
    state::Vector{V}
    record::R
    function RArray(
        state::Vector{V},
        record::R,
    ) where {V,C,E<:AbstractEntry,N,R<:AbstractRecord{C,E,N}}
        return new{V,R,N}(state, record)
    end
end
function RArray(::Type{E}, c::AbstractClock, A::AbstractArray) where {V,T,E<:AbstractEntry{V,T}}
    state = similar(vec(A))
    copyto!(state, A)
    sz = Size(A)
    dok = Dict{NTuple{ndims(A),Int},E}()
    for (i, ind) in enumerate(IndexMap(sz))
        dok[ind] = E(state[i], c)
    end
    indmap = IndexMap(axes(A))
    record = DokRecord(c, dok, sz, Size(A), indmap)
    return RArray(state, record)
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::AbstractArray,
) where {V,T<:Real,E<:AbstractEntry{V,T}}
    return RArray(E, c, v)
end

const RMatrix{V,R} = RArray{V,R,2}

_state(A::RArray) = A.state
_record(A::RArray) = A.record
