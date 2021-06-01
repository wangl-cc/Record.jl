# overload mathematical operations
import Base: +, -, *, /, \, ^, adjoint, transpose, broadcastable

using LinearAlgebra: Adjoint, Transpose, AdjointAbsVec, TransposeAbsVec, AdjOrTransAbsVec

## unary operators
for op in (:+, :-, :transpose, :adjoint)
    @eval @inline ($op)(r::AbstractRArray) = ($op)(state(r))
end

## binary operators
for op in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($op)(x::AbstractRArray, y::AbstractRArray) = ($op)(state(x), state(y))
    for T in (Number, Transpose, Adjoint, AbstractArray)
        @eval begin
            @inline ($op)(x::AbstractRArray, y::$T) = ($op)(state(x), y)
            @inline ($op)(x::$T, y::AbstractRArray) = ($op)(x, state(y))
        end
    end
end

# fix for Adjoint or Transpose (copy from LinearAlgebra adjtrans.jl)
# Adjoint/Transpose-vector * vector
@inline *(u::AdjointAbsVec{<:Number}, v::AbstractRVector{<:Number,<:Real}) = *(u, state(v))
@inline *(u::TransposeAbsVec{T}, v::AbstractRVector{T,<:Real}) where {T<:Real} = *(u, state(v))
# vector * Adjoint/Transpose-vector
@inline *(u::AbstractRVector, v::AdjOrTransAbsVec) = *(state(u), v)

## broadcast
@inline broadcastable(r::AbstractRArray) = state(r)
# vim:tw=92:ts=4:sw=4:et
