"""
    AbstractRArray{V,T,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and time of type `T`", whose changes will be recorded automatically.

!!! note

    Avoid to edit recorded arrays outside of loop, because clocks will initial
    automatically when finnish loop.
"""
abstract type AbstractRArray{V<:Number,T<:Real,N} <: AbstractArray{V,N} end

timetype(::Type{<:AbstractRArray{V,T}}) where {V,T} = T

"""
    state(A::AbstractRArray)

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
