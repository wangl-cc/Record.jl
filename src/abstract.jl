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

# type alias
const AbstractRScalar{V,T} = AbstractRArray{V,T,0}
const AbstractRVector{V,T} = AbstractRArray{V,T,1}
const AbstractRMatrix{V,T} = AbstractRArray{V,T,2}

# API
timetype(::Type{<:AbstractRArray{<:Any,T}}) where {T} = T

"""
    state(A::AbstractRArray{V,T,N}) -> Array{V,N}

Get current state of recorded array `A`. API for mathematical operations.
"""
function state end

function rlength end
function rsize end

# array interface
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = length(state(A))
Base.size(A::AbstractRArray) = size(state(A))
Base.getindex(A::AbstractRArray, I::Int...) = getindex(state(A), I...)
function Base.show(io::IO, ::MIME"text/plain", A::AbstractRArray)
    print(io, "recorded ")
    return show(io, MIME("text/plain"), state(A))
end

# static
"""
    StaticRArray{V,T,N} <: AbstractRecord{V,T,N}

Record type to record changes of arrays whose elements never change but insert
or delete can  be created by `StaticRArray(t::AbstractClock, xs...)` where
`xs` are abstract arrays to be recorded.

Implemented statical arrays:
* `StaticRVector`

!!! note

    Elements of StaticRArray `A` can be delete by `deleteat!(A,i)`, whose value
    after deletion is 0.

# Examples
```jldoctest
julia> c = DiscreteClock(3);

julia> v = StaticRArray(c, [0, 1, 2])
recorded 3-element Vector{Int64}:
 0
 1
 2

julia> for epoch in c
           push!(v, epoch+2) # push a element
           deleteat!(v, 1)   # delete a element
       end

julia> v # there are still three element now
recorded 3-element Vector{Int64}:
 3
 4
 5

julia> records(v)[6] # but six element are recorded
Record Entries
t: 2-element Vector{Int64}:
 3
 3
v: 2-element Vector{Int64}:
 5
 5

julia> gettime(records(v)[1], 2)[1] # element after deletion is 0
0
```
"""
abstract type StaticRArray{V,T,N} <: AbstractRArray{V,T,N} end
function StaticRArray(t::AbstractClock, x1, x2)
    return StaticRArray(t, x1), StaticRArray(t, x2)
end
function StaticRArray(t::AbstractClock, x1, x2, xs...)
    return StaticRArray(t, x1), StaticRArray(t, x2, xs...)::Tuple...
end

# dynamic
"""
    DynamicRArray{V,T,N} <: AbstractRecord{V,T,N}

Recorded array whose elements change overtime can be created by
`DynamicRArray(t::AbstractClock, xs...)` where `xs` are abstract arrays or
numbers (or called scalar) to be recorded.

Implemented dynamic arrays:
* `DynamicRScalar`
* `DynamicRVector`

!!! note

    For a recorded dynamical scalar `S`, use `S[1] = v` to change its value
    instead of `S = v`.

# Examples
```jldoctest
julia> c = DiscreteClock(3);

julia> s, v = DynamicRArray(c, 0, [0, 1]);

julia> s # scalar
recorded 0

julia> v # vector
recorded 2-element Vector{Int64}:
 0
 1

julia> for epoch in c
           s[1] += 1
           v[1] += 1
       end

julia> s
recorded 3

julia> v
recorded 2-element Vector{Int64}:
 3
 1

julia> records(s)[1]
Record Entries
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4-element Vector{Int64}:
 0
 1
 2
 3

julia> records(v)[1]
Record Entries
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4-element Vector{Int64}:
 0
 1
 2
 3

julia> records(v)[2]
Record Entries
t: 1-element Vector{Int64}:
 0
v: 1-element Vector{Int64}:
 1
```
"""
abstract type DynamicRArray{V,T,N} <: AbstractRArray{V,T,N} end
function DynamicRArray(t::AbstractClock, x1, x2)
    return DynamicRArray(t, x1), DynamicRArray(t, x2)
end
function DynamicRArray(t::AbstractClock, x1, x2, xs...)
    return DynamicRArray(t, x1), DynamicRArray(t, x2, xs...)::Tuple...
end
# vim:tw=92:ts=4:sw=4:et
