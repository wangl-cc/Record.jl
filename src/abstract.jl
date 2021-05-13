"""
    AbstractRArray{V,T,N} <: AbstractArray{V,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and time of type `T`", whose changes will be recorded automatically.
`AbstractRArray` is a subtype of `AbstractArray`, so array operations
like `getindex`, `setindex!`, `length`, `size`, mathematical operations
like `+`, `-`, `*`, `/` and broadcast on a recorded array `A` works same as
its current state [`state(A)`](@ref state).

!!! note

    Avoid to edit recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRArray{V<:Number,T<:Real,N} <: AbstractArray{V,N} end

timetype(::Type{<:AbstractRArray{V,T}}) where {V,T} = T

"""
    state(A::AbstractRArray{V,T,N}) -> Array{V,N}

Get current state of recorded array `A`. 
"""
function state end

function rlength end
function rsize end

# interface
Base.length(A::AbstractRArray) = length(state(A))
Base.size(A::AbstractRArray) = size(state(A))
Base.getindex(A::AbstractRArray, I::Int...) = getindex(state(A), I...)

function Base.show(io::IO, ::MIME"text/plain", A::AbstractRArray)
    print(io, "recorded ")
    return show(io, MIME("text/plain"), state(A))
end
# vim:tw=92:ts=4:sw=4:et
