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
# force reutrn number for AbstractRScalar
for f in (:-, :conj, :real, :imag, :transpose, :adjoint)
    @eval @inline ($f)(r::AbstractRScalar) = ($f)(state(r))
end

## Binary arithmetic operators ##
# +(A, B) and -(A, B) implemented in arraymath
# this is + for more than two args to avoid allocation by afoldl
@inline +(A::NRArray, Bs::NRArray...) = +(state(A), state(Bs)...)

# * / \ for Array and Number is in arraymath, there are interfaces for RScalar
for f in (:/, :\, :*)
    if f !== :/
        @eval @inline ($f)(A::AbstractRScalar, B::NRArray) = $f(state(A), state(B))
    end
    if f !== :\
        @eval @inline ($f)(A::NRArray, B::AbstractRScalar) = $f(state(A), state(B))
    end
end

# arithmetic operators for Number and RScalar
for f in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($f)(A::AbstractRScalar, B::AbstractRScalar) = ($f)(state(A), state(B))
    @eval @inline ($f)(A::Number, B::AbstractRScalar) = ($f)(A, state(B))
    @eval @inline ($f)(A::AbstractRScalar, B::Number) = ($f)(state(A), B)
end

# other arraymath math like matrix * vector was implemented for densearray

## data movement ##
# recevse! is forbiden
if VERSION >= v"1.6"
    @inline reverse(A::AbstractRArray; dims=:) = reverse!(copy(state(A)); dims=dims)
else
    # for julia 1.0-1.5, the kwargs dims=: is not allowed
    @inline reverse(A::AbstractRVector) = reverse(state(A))
    @inline reverse(A::AbstractRArray; dims::Integer) = reverse(state(A); dims=dims)
end

## broadcast
@inline broadcastable(r::AbstractRArray) = state(r)
# vim:tw=92:ts=4:sw=4:et
