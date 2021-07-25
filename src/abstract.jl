"""
    AbstractRArray{V,T,N} <: DenseArray{V,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and time of type `T`", whose changes will be recorded automatically.

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

!!! note

    `state` for `AbstractRArray{V,T,N}` where `N >= 2` is unsafe because of
    `unsafe_wrap` and `unsafe_convert`.
"""
function state end

# Note:
# `_state` is a internal API which will be called by other function in this Package
# state is a export api which will be called by user
# the return of `_state` should be a vector (for array rank >= 1) or a number (for scalar),
# but the return of `state` should be a array with the same size
state(A::AbstractRScalar) = _state(A)
state(A::AbstractRVector) = _state(A)
state(A::AbstractRArray{V,T,N}) where {V,T,N} = # maybe unsafe
    unsafe_wrap(Array{V,N}, Base.unsafe_convert(Ptr{V}, A), _size(A))
@inline state(As::Tuple) = map(state, As)

"""
    setclock!(A::AbstractRArray, c::AbstractClock)

Assign the clock of `A` to `c`. Type of `c` should be the same as old one.
"""
setclock!(A::AbstractRArray, c::AbstractClock) = _setclock!(A, c)
_setclock!(A::AbstractRArray, c::AbstractClock) = A.t = c

"""
    setclock!(A::AbstractRArray, c::AbstractClock)

Non-mutating setclock for `A`. It will create a deepcopy of `A` besides
the clock field, which will be assigned to `c`.
"""
setclock(A::AbstractRArray, c::AbstractClock) = (Ac = deepcopy(A); setclock!(Ac, c); Ac)

function rlength end
function rsize end
raxes(A::AbstractRArray) = map(Base.OneTo, rsize(A))
function rcheckbounds(A::AbstractRArray, I...)
    return Base.checkbounds_indices(Bool, raxes(A), I)
end

# internal API
@inline _state(A::AbstractRArray) = A.v
@inline _state(A::AbstractArray) = A
@inline _length(A::AbstractRArray) = length(_state(A))
@inline _size(::AbstractRScalar) = ()
@inline _size(A::AbstractRVector) = (_length(A),)
@inline _size(A::AbstractRArray) = convert(Tuple, A.sz)

# Abstract Arrays interfaces
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = _length(A)
Base.size(A::AbstractRArray) = _size(A)
Base.getindex(A::AbstractRArray, i::Int) = getindex(_state(A), i)
# Strided Arrays interfaces
## strides(A) and stride(A, i::Int) have definded for DenseArray
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, _state(A))
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
3-element StaticRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 0
 1
 2

julia> for epoch in c
           push!(v, epoch+2) # push a element
           deleteat!(v, 1)   # delete a element
       end


julia> v # there are still three element now
3-element StaticRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
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
StaticRArray(t::AbstractClock, xs...) = map(x -> StaticRArray(t, x), xs)
StaticRArray{V}(t::AbstractClock, x) where {V} = StaticRArray(t, convert_array(V, x))
StaticRArray{V}(t::AbstractClock, xs...) where {V} = map(x -> StaticRArray{V}(t, x), xs)

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
0-dimensional DynamicRScalar{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
0

julia> v # vector
2-element DynamicRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
 0
 1

julia> for epoch in c
           s[1] += 1
           v[1] += 1
       end


julia> s
0-dimensional DynamicRScalar{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
3

julia> v
2-element DynamicRVector{Int64, Int64, DiscreteClock{Int64, Base.OneTo{Int64}}}:
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
    v::Vector{V}
    sz::NTuple{N,Int}
end
_testa(A::Array) = _TestArray(vec(A), size(A))
_testa(As::Array...) = map(_testa, As)

rlength(A::_TestArray) = length(A.v)
rsize(A::_TestArray) = A.sz

# vim:tw=92:ts=4:sw=4:et
