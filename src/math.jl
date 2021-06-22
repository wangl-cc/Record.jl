# overload mathematical operations
import Base: +, -, *, /, \, ^, conj, real, imag, reverse
import Base: adjoint, transpose
import Base: broadcastable

import LinearAlgebra: dot

using LinearAlgebra: Adjoint, Transpose, AdjointAbsVec, TransposeAbsVec, AdjOrTransAbsVec

# Union of Array and RArray
const NRArray{T} = Union{Array{T},AbstractRArray{T}}

## Unary arithmetic operators ##
@inline +(A::AbstractRArray{<:Number}) = state(A) # do nothing for better performance
for f in (:-, :conj, :real, :imag, :transpose, :adjoint)
    @eval @inline ($f)(r::AbstractRArray) = ($f)(state(r))
end

## Binary arithmetic operators ##
# +(A, B) and -(A, B) implemented in arraymath, this is + for more than two args
+(A::NRArray, Bs::NRArray...) = +(state(A), state(Bs)...)

# * / \ for Array and Number is in arraymath, this is for Scalar
for f in (:/, :\, :*)
    if f !== :/
        @eval @inline ($f)(A::AbstractRScalar, B::NRArray) =
            Base.broadcast_preserving_zero_d($f, state(A), state(B))
    end
    if f !== :\
        @eval @inline ($f)(A::NRArray, B::AbstractRScalar) =
            Base.broadcast_preserving_zero_d($f, state(A), state(B))
    end
end

# arithmetic operators for number
for f in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($f)(A::AbstractRScalar, B::AbstractRScalar) =
        ($f)(state(A), state(B))
    @eval @inline ($f)(A::Number, B::AbstractRScalar) =
        ($f)(A, state(B))
    @eval @inline ($f)(A::AbstractRScalar, B::Number) =
        ($f)(state(A), B)
end

## data movement ##
# recevse! is forbiden
if VERSION >= v"1.6"
    reverse(A::AbstractRArray; dims=:) = reverse!(copy(state(A)); dims)
else
    reverse(A::AbstractRArray; dims::Integer) = reverse!(copy(state(A)); dims)
end

# for DenseArray BLAS
Base.pointer(A::AbstractRArray) = pointer(state(A))
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} = Base.unsafe_convert(Ptr{T}, state(A))

## broadcast
@inline broadcastable(r::AbstractRArray) = state(r)
# vim:tw=92:ts=4:sw=4:et
