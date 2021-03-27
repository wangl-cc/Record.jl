# overload mathematical operations
import Base:+, -, *, /, \, ^,
            adjoint, transpose,
            broadcastable

## unary operators
for op in (:+, :-, :transpose, :adjoint)
    @eval ($op)(r::AbstractRArray) = ($op)(state(r))
end

## binary operators
for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @inline ($op)(x::AbstractRArray, y::AbstractRArray) =
            ($op)(state(x), state(y))
        @inline ($op)(x::AbstractRArray, y::Number) =
            ($op)(state(x), y)
        @inline ($op)(x::Number, y::AbstractRArray) =
            ($op)(x, state(y))
        @inline ($op)(x::AbstractRArray, y::AbstractArray) =
            ($op)(state(x), y)
        @inline ($op)(x::AbstractArray, y::AbstractRArray) =
            ($op)(x, state(y))
    end
end

## broadcast
broadcastable(r::AbstractRArray) = state(r) 
