import Base:IteratorSize, iterate, eltype,
            +, -, *, /, ÷, \, ^, %,
            transpose,
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

# mathematical Operations
## +, -, *, /, ÷, \, ^, %
## WIP

*(x::AbstractRecord, y) = state(x) * y
*(x, y::AbstractRecord) = x * state(y)
*(x::AbstractRecord, y::AbstractRecord) = state(x) * state(y)

## Linear Algebra
transpose(r::AbstractRecord) = transpose(state(r))

## broadcast
broadcastable(r::AbstractRecord) = state(r) 
