"""
    DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRScalar{V,T,0}

Implementation of recorded scaler, created by `DynamicRArray(t::AbstractClock, v::Number)`,
or `DynamicRArray(t::AbstractClock, A::AbstractArray{T,0})`.

!!! info
     
    Store a value `v` of a `DynamicRScalar` `S` by `S[] = v` or `S[1] = v` instead of `S = v`.
    Although this is an array type, Mathematical operations on it work like `Number` for convenience.
```
"""
mutable struct DynamicRScalar{Tv,Tt,Tc} <: DynamicRArray{Tv,Tt,0}
    v::Tv
    t::Tc
    V::Vector{Tv}
    T::Vector{Tt}
    function DynamicRScalar(
            v::Tv,
            t::Tc,
            V::Vector{Tv},
            T::Vector{Tt}
        ) where {Tv,Tt,Tc<:AbstractClock{Tt}}
        checksize(V, T)
        new{Tv,Tt,Tc}(v, t, V, T)
    end
end
DynamicRArray(t::AbstractClock, v::Number) =
    DynamicRScalar(v, t, [v], [currenttime(t)])
DynamicRArray(t::AbstractClock, v::Array{<:Any,0}) =
    DynamicRArray(t, v[])

rlength(::DynamicRScalar) = 1
rsize(::DynamicRScalar) = ()

function Base.setindex!(A::DynamicRScalar, v, i::Int)
    @boundscheck checkbounds(A, i)
    A.v = v
    push!(A.V, v)
    push!(A.T, currenttime(A.t))
    return A
end

function rgetindex(A::DynamicRScalar, i::Integer=1)
    @boundscheck rcheckbounds(A, i)
    return DynamicEntry(A.T, A.V)
end
