# overload mathematical operations
import Base:+, -, *, /, \, ^,
            adjoint, transpose,
            broadcastable

using LinearAlgebra:Adjoint, Transpose,
                    AdjointAbsVec, TransposeAbsVec,
                    AdjOrTransAbsVec

## unary operators
for op in (:+, :-, :transpose, :adjoint)
    @eval @inline ($op)(r::AbstractRArray) = ($op)(state(r))
end

## binary operators
for op in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($op)(x::AbstractRArray, y::AbstractRArray) =
        ($op)(state(x), state(y))
    for T in (Number, Transpose, Adjoint, AbstractArray)
        @eval begin
            @inline ($op)(x::AbstractRArray, y::$T) = ($op)(state(x), y)
            @inline ($op)(x::$T, y::AbstractRArray) = ($op)(x, state(y))
        end
    end
end

# fix for Adjoint or Transpose (copy from LinearAlgebra adjtrans.jl)
# Adjoint/Transpose-vector * vector
*(u::AdjointAbsVec{<:Number}, v::AbstractRArray{<:Number,<:Real,1}) = *(u, state(v))
*(u::TransposeAbsVec{T}, v::AbstractRArray{T,<:Real,1}) where {T<:Real} = *(u, state(v))
*(u::AdjOrTransAbsVec, v::AbstractRArray{<:Any,<:Real,1}) = *(u, state(v))
# vector * Adjoint/Transpose-vector
*(u::AbstractRArray{<:Any,<:Real,1}, v::AdjOrTransAbsVec) = *(state(u), v)

## broadcast
broadcastable(r::AbstractRArray) = state(r) 
