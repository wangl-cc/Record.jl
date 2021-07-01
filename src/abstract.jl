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
abstract type AbstractRArray{V,T<:Real,N} <: DenseArray{V,N} end # Dense for Array math

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

@inline state(A::AbstractArray) = A
@inline state(As::AbstractArray...) = map(state, As)
@inline state(As::Tuple) = map(state, As)

"""
    setclock(A::AbstractRArray, c::AbstractClock)

Non-mutating setclock for `A`. It will create a deepcopy of `A` besides 
the clock field, which will be assigned to `c`.
"""
function setclock(A::AbstractRArray, c::AbstractClock)
    stackdict = IdDict()
    flds = ntuple(i -> getfield(A, i), nfields(A)) # split for type stable
    flds_new = map(fld -> setclock_internal(fld, c, stackdict), flds)
    return (typeof(A))(flds_new...)
end

setclock_internal(xi, ::AbstractClock, stackdict) =
    Base.deepcopy_internal(xi, stackdict)::typeof(xi)
setclock_internal(::AbstractClock, c::AbstractClock, _) = c

function rlength end
function rsize end

# Abstract Arrays interfaces
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = length(state(A))
Base.size(A::AbstractRArray) = size(state(A))
Base.getindex(A::AbstractRArray, I::Int...) = getindex(state(A), I...)
Base.elsize(::Type{<:AbstractRArray{V,T,N}}) where {V,T,N} = Base.elsize(Array{V,N})
function Base.show(io::IO, ::MIME"text/plain", A::AbstractRArray)
    print(io, "recorded ")
    return show(io, MIME("text/plain"), state(A))
end
# Strided Arrays interfaces
## strides(A) and stride(A, i::Int) have definded for DenseArray
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, state(A)) # will in BLAS
Base.elsize(::Type{<:AbstractRArray{T}}) where {T} = Base.elsize(Array{T})

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

julia> record(v)[6] # but six element are recorded
Record Entry
t: 2-element Vector{Int64}:
 3
 3
v: 2-element Vector{Int64}:
 5
 5

julia> gettime(record(v)[1], 2)[1] # element after deletion is 0
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
function StaticRArray{V}(t::AbstractClock, x) where {V}
    return StaticRArray(t, convert_array(V, x))
end
function StaticRArray{V}(t::AbstractClock, x1, x2) where {V}
    return StaticRArray{V}(t, x1), StaticRArray{V}(t, x2)
end
function StaticRArray{V}(t::AbstractClock, x1, x2, xs...) where {V}
    return StaticRArray{V}(t, x1), StaticRArray{V}(t, x2, xs...)::Tuple...
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

julia> record(s)[1]
Record Entry
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

julia> record(v)[1]
Record Entry
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

julia> record(v)[2]
Record Entry
t: 1-element Vector{Int64}:
 0
v: 1-element Vector{Int64}:
 1
```
"""
abstract type DynamicRArray{V,T,N} <: AbstractRArray{V,T,N} end
DynamicRArray(t::AbstractClock, xs...) = map(x -> DynamicRArray(t, x), xs)
DynamicRArray{V}(t::AbstractClock, x) where {V} = DynamicRArray(t, convert_array(V, x))
DynamicRArray{V}(t::AbstractClock, xs...) where {V} = map(x -> DynamicRArray{V}(t, x), xs)

convert_array(::Type{T}, x::T) where {T} = x
convert_array(::Type{T}, x) where {T} = convert(T, x)
convert_array(::Type{T}, x::Array{T}) where {T} = x
convert_array(::Type{T}, x::AbstractArray{<:Any,N}) where {T,N} = convert(Array{T,N}, x)

# Type for test math API (some types of RArray are not implemented now)
struct _TestArray{V,N} <: RecordedArrays.AbstractRArray{V,Int,N}
    A::Array{V,N}
end
state(A::_TestArray) = A.A
state(A::_TestArray{<:Any,0}) = A.A[1]
_testa(A::Array) = _TestArray(A)
_testa(x::Number) = _TestArray(x)
_testa(As::Array...) = map(_testa, As)

rlength(A::_TestArray) = length(A.A)
rsize(A::_TestArray) = size(A.A)

# vim:tw=92:ts=4:sw=4:et
