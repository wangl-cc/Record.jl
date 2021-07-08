# overload mathematical operations
import Base: +, -, *, /, \, ^, conj, real, imag
import Base: adjoint, transpose

using LinearAlgebra: Adjoint, Transpose, AdjointAbsVec, TransposeAbsVec, AdjOrTransAbsVec

# Union of Array and RArray
const NRArray{T} = Union{Array{T},AbstractRArray{T}}

## Unary arithmetic operators ##
@inline +(A::AbstractRArray{<:Number}) = A # do nothing for better performance
@inline +(A::AbstractRScalar{<:Number}) = _state(A) # return Number for scalar
# force reutrn number for AbstractRScalar
for f in (:-, :conj, :real, :imag, :transpose, :adjoint)
    @eval @inline ($f)(r::AbstractRScalar) = ($f)(_state(r))
end

## Binary arithmetic operators ##
# +(A, B) and -(A, B) implemented in arraymath
# this is + for more than two args to avoid allocation by afoldl
# call broadcast directly instead of call state
@inline +(A::NRArray, Bs::NRArray...) = broadcast(+, A, Bs...)

# * / \ for Array and Number is in arraymath, there are interfaces for RScalar
for f in (:/, :\, :*)
    if f !== :/
        @eval @inline ($f)(A::AbstractRScalar, B::NRArray) = $f(_state(A), B)
    end
    if f !== :\
        @eval @inline ($f)(A::NRArray, B::AbstractRScalar) = $f(A, _state(B))
    end
end

# arithmetic operators for Number and RScalar
for f in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($f)(A::AbstractRScalar, B::AbstractRScalar) = ($f)(_state(A), _state(B))
    @eval @inline ($f)(A::Number, B::AbstractRScalar) = ($f)(A, _state(B))
    @eval @inline ($f)(A::AbstractRScalar, B::Number) = ($f)(_state(A), B)
end

# other arraymath math like matrix * vector was implemented for densearray

# vim:tw=92:ts=4:sw=4:et
