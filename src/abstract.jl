"""
    AbstractRArray{V,T,N}
    
Supertype of recorded `N`-dimensional arrays with elements of type `V`
and time of type `T`", whose changes will be recorded automatically.
"""
abstract type AbstractRArray{V<:Number, T<:Real, N} <: AbstractArray{V, N} end

"""
    state(A::AbstractRArray)

Get current state of recorded array `A`. 
"""
function state end

function Base.show(io::IO, ::MIME"text/plain", A::AbstractRArray)
    print(io, "recorded ")
    show(io, MIME("text/plain"), state(A))
end
