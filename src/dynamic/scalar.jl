"""
    DynamicRScalar{V,T,C<:AbstractClock{T}} <: DynamicRScalar{V,T,0}

Implementation of recorded scaler, created by `DynamicRArray(t::AbstractClock, v::Number)`,
or `DynamicRArray(t::AbstractClock, A::AbstractArray{T,0})`.

!!! info
     
    Store a value `v` of a `DynamicRScalar` `S` by `S[] = v` or `S[1] = v` instead of `S = v`.
    Although this is an array type, Mathematical operations on it work like `Number` for convenience.
```
"""
mutable struct DynamicRScalar{V,T,C} <: DynamicRArray{V,T,0}
    v::V
    c::C
    record::DynamicEntry{V,T}
    function DynamicRScalar(
            v::V,
            c::C,
            record::DynamicEntry{V,T},
        ) where {V,T,C<:AbstractClock{T}}
        new{V,T,C}(v, c, record)
    end
end
DynamicRArray(c::AbstractClock, v::Number) =
    DynamicRScalar(v, c, DynamicEntry(v, c))
DynamicRArray(c::AbstractClock, v::Array{<:Any,0}) =
    DynamicRArray(c, v[])

function Base.setindex!(A::DynamicRScalar, v, i::Int)
    @boundscheck checkbounds(A, i)
    A.v = v
    store!(A.record, v, currenttime(A.c))
    return A
end

function rgetindex(A::DynamicRScalar, i::Integer=1)
    @boundscheck rcheckbounds(A, i)
    return A.record
end
