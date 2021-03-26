import Base:IteratorSize, iterate, eltype

import Base:+, -, *, /, \, ^,
            adjoint, transpose,
            broadcastable

using Base:HasShape, HasLength

"""
    AbstractRecord{V,T,N}
    
Supertype for record which record changes of `N`-dimensional arrays with
elements of type `V` and time of type `T`".
"""
abstract type AbstractRecord{V<:Number, T<:Real, N} end

function IteratorSize(::Type{<:AbstractRecord{V,T,N}}) where {V,T,N} 
    HasShape{N}()
end
function iterate(r::AbstractRecord, state = 1)
    if state <= length(r)
        return getrecord(r, state), state + 1
    else
        return nothing
    end
end

"""
    state(r::DynamicRecord)

Get current state of recorded variable `r`. 
"""
function state end

# mathematical Operations (WIP)
## unary operators
## +, -, transpose, adjoint
for op in (:+, :-, :transpose, :adjoint)
    @eval ($op)(r::AbstractRecord) = ($op)(state(r))
end
## binary operators
## +, -, *, /, \, ^
for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        ($op)(x::AbstractRecord, y) = ($op)(state(x), y)
        ($op)(x, y::AbstractRecord) = ($op)(x, state(y))
        ($op)(x::AbstractRecord, y::AbstractRecord) =
            ($op)(state(x), state(y))
    end
end

## broadcast
broadcastable(r::AbstractRecord) = state(r) 
