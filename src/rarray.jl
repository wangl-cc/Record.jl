import Base: +, -, *, /, \, ^, conj, real, imag
import Base: adjoint, transpose

"""
    AbstractRArray{V,R,N} <: DenseArray{V,N}

Supertype of recorded `N`-dimensional arrays with elements of type `V`
and record of type `R`", whose changes will be recorded automatically.

!!! note

    Avoid to mutate recorded arrays out of loop, because clocks will initial
    automatically during loop.
"""
abstract type AbstractRArray{V,R,N} <: DenseArray{V,N} end # Dense for Array math
# type alias
const AbstractRScalar{V,R} = AbstractRArray{V,R,0}
const AbstractRVector{V,R} = AbstractRArray{V,R,1}

# Abstract Arrays interfaces
Base.IndexStyle(::Type{<:AbstractRArray}) = IndexLinear()
Base.length(A::AbstractRArray) = length(_state(A))
Base.size(A::AbstractRArray) = convert(NTuple{ndims(A),Int}, _size(A))
Base.size(A::AbstractRArray, dim::Integer) = _size(A)[dim]::Int
Base.getindex(A::AbstractRArray, i::Int) = getindex(_state(A), i)
function Base.setindex!(A::AbstractRArray, v, i::Int)
    @boundscheck checkbounds(A, i)
    @inbounds A.state[i] = v
    @inbounds _record(A)[i] = v
    return v
end
# Strided Arrays interfaces
## strides(A) and stride(A, i::Int) have definded for DenseArray
Base.unsafe_convert(::Type{Ptr{T}}, A::AbstractRArray{T}) where {T} =
    Base.unsafe_convert(Ptr{T}, _state(A))
Base.elsize(::Type{<:AbstractRArray{T}}) where {T} = Base.elsize(Array{T})
# show
function Base.summary(io::IO, A::T) where {T<:AbstractRArray}
    showdim(io, A)
    print(io, ' ')
    Base.show_type_name(io, T.name)
    print(io, '{')
    n = length(T.parameters)
    for i in 1:n
        p = T.parameters[i]
        if p isa Type && p <: AbstractRecord
            Base.show_type_name(io, p.name)
        else
            show(io, p)
        end
        i < n && print(io, ", ")
    end
    print(io, '}')
    return nothing
end

showdim(io::IO, ::AbstractArray{<:Any,0}) = print(io, "0-dimensional")
showdim(io::IO, A::AbstractVector) = print(io, length(A), "-element")
showdim(io::IO, A::AbstractArray) where {N} = join(io, size(A), '×')

rarray(::Type{E}, c::AbstractClock, As...) where {E<:AbstractEntry} =
    map(A -> rarray(E, c, A), As)

# Resize interfaces
# Vector
Base.sizehint!(A::AbstractRVector, sz::Integer) = sizehint!(_state(A), sz)
function Base.push!(A::AbstractRVector, v)
    push!(_state(A), v)
    push!(_record(A), v)
    return A
end
function Base.insert!(A::AbstractRVector, i::Integer, v)
    insert!(_state(A), i, v)
    push!(_record(A), v)
    return A
end
function Base.deleteat!(A::AbstractRVector, i::Integer)
    deleteat!(_state(A), i)
    deleteat!(_record(A), i)
    return A
end
# Array
Base.sizehint!(A::AbstractRArray{V,R,N}, sz::Vararg{Integer,N}) where {V,R,N} =
    sizehint!(_state(A), prod(sz))
function pushdim!(A::AbstractRArray, dim::Integer, n::Integer)
    # grow state and move element
    blk_len, vblk_num, batch_num = _blkinfo(A, dim)
    blk_num = vblk_num + n
    v = _state(A)
    blk_type = zeros(Bool, blk_num)
    blk_type[vblk_num+1:blk_num] .= true
    delta = blk_len * n * batch_num
    ind = length(v)
    Base._growend!(v, delta)
    _moveblkend!(v, ind, blk_len, blk_type, batch_num, delta)
    # change record dim
    pushdim!(_record(A), dim, n)
    return A
end
function deletedim!(A::AbstractRArray, dim::Integer, inds)
    # grow state and move element
    n = length(inds)
    blk_len, blk_num, batch_num = _blkinfo(A, dim)
    v = _state(A)
    blk_type = zeros(Bool, blk_num)
    for ind in inds # if inds is a Integer, broadcast will raise a error
        blk_type[ind] = true
    end
    delta = blk_len * n * batch_num
    _moveblkbegin!(v, blk_len, blk_type, batch_num, delta)
    Base._deleteend!(v, delta)
    # change record dim
    deletedim!(_record(A), dim, inds)
    return A
end

function _moveblkbegin!(
    v::Vector,
    blk_len::Integer,
    blk_type::AbstractVector{Bool},
    batch_num::Integer,
    delta::Integer,
)
    blk_num = length(blk_type)
    ind = 1
    _delta = 0
    for i in 1:batch_num , j in 1:blk_num
        if @inbounds blk_type[j]
            _delta += blk_len
        else
            if _delta != 0 
                for k in ind:(ind+blk_len-1)
                    v[k] = v[k+_delta]
                end
            end
            ind += blk_len
        end
    end
    _delta != delta && error("given delta don't equal to the real delta")
    return v
end
function _moveblkend!(
    v::Vector,
    ind::Integer,
    blk_len::Integer,
    blk_type::AbstractVector{Bool},
    batch_num::Integer,
    delta::Integer
)
    blk_num = length(blk_type)
    for i in batch_num:-1:1, j in blk_num:-1:1
        if @inbounds blk_type[j]
            delta -= blk_len
            delta == 0 && break
        else
            for k in ind:-1:(ind-blk_len+1)
                v[k+delta] = v[k]
            end
            ind -= blk_len
        end
    end
    return v
end

function _blkinfo(A::AbstractArray, dim::Integer)
    dim > ndims(A) && throw(ArgumentError("dim must less than ndims(A)"))
    blk_len = 1
    sz = size(A)
    for i in 1:(dim-1)
        blk_len *= sz[i]
    end
    batch_num = 1
    for i in (dim+1):ndims(A)
        batch_num *= sz[i]
    end
    return blk_len, sz[dim], batch_num
end

"""
    state(A::AbstractRArray{V,R,N}) -> Array{V,N}

Get current state of recorded array `A`. API for mathematical operations.

!!! note

    `state` for `AbstractRArray{V,T,N}` where `N >= 2` might be unsafe because of
    `unsafe_wrap` and `unsafe_convert`.
"""
state

# Note:
# `_state` is a internal API which will be called by other function
# state is a export api which will be called by user
# the return of `_state` should be a vector (for array) or a number (for scalar),
# but the return of `state` should be a array with the same dimensions
state(A::AbstractRScalar) = _state(A)
state(A::AbstractRVector) = _state(A)
state(A::AbstractRArray{V,T,N}) where {V,T,N} = # may unsafe
    unsafe_wrap(Array{V,N}, Base.unsafe_convert(Ptr{V}, A), size(A))

"""
    record(A::AbstractRArray)

Get the record of given Array `A`.
"""
record(A::AbstractRArray) = record(_record(A))

"""
    setclock!(A::AbstractRArray, c::AbstractClock)

Assign the clock of `A` to `c`. Type of `c` should be the same as old one.
"""
setclock!(A::AbstractRArray, c::AbstractClock) = _setclock!(A.record, c)

"""
    setclock(A::AbstractRArray, c::AbstractClock)

Non-mutating setclock for `A`, which will create a deepcopy of `A`, then 
assigned the clock field to `c`.
"""
setclock(A::AbstractRArray, c::AbstractClock) = (Ac = deepcopy(A); setclock!(Ac, c); Ac)

# internal methods
# core interfaces for RArray
@inline _state(A::AbstractArray) = A
@inline _length(A::AbstractRArray) = length(_state(A))

# array math (most of which were implemented in arraymath) #
const URArray{T} = Union{Array{T},AbstractRArray{T}}

## Unary arithmetic operators ##
@inline +(A::AbstractRArray{<:Number}) = A # do nothing for better performance
@inline +(A::AbstractRScalar) = _state(A) # return Number for scalar
# force reutrn number for AbstractRScalar
for f in (:-, :conj, :real, :imag, :transpose, :adjoint)
    @eval @inline ($f)(r::AbstractRScalar) = ($f)(_state(r))
end

## Binary arithmetic operators ##
# +(A, B) and -(A, B) implemented in arraymath
# this is + for more than two args to avoid allocation by afoldl
# call broadcast directly instead of call state
@inline +(A::URArray, Bs::URArray...) = broadcast(+, A, Bs...)

# * / \ for Array and Number is in arraymath, there are interfaces for RScalar
for f in (:/, :\, :*)
    if f !== :/
        @eval @inline ($f)(A::AbstractRScalar, B::URArray) = $f(_state(A), B)
    end
    if f !== :\
        @eval @inline ($f)(A::URArray, B::AbstractRScalar) = $f(A, _state(B))
    end
end

# arithmetic operators for Number and RScalar
for f in (:+, :-, :*, :/, :\, :^)
    @eval @inline ($f)(A::AbstractRScalar, B::AbstractRScalar) = ($f)(_state(A), _state(B))
    @eval @inline ($f)(A::Number, B::AbstractRScalar) = ($f)(A, _state(B))
    @eval @inline ($f)(A::AbstractRScalar, B::Number) = ($f)(_state(A), B)
end

# RArrays
struct RScalar{V,R} <: AbstractRArray{V,R,0}
    state::Array{V,0}
    record::R
end
function RScalar(::Type{E}, c::AbstractClock, v::Array{<:Number,0}) where {E<:AbstractEntry}
    return RScalar(v, ScalarRecord(c, E(v, c)))
end
function RScalar(::Type{E}, c::AbstractClock, v::Number) where {E<:AbstractEntry}
    return RScalar(E, c, fill(v))
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::Union{Number,Array{<:Number,0}},
) where {E<:AbstractEntry}
    return RScalar(E, c, v)
end

_state(A::RScalar) = @inbounds A.state[1]
_record(A::RScalar) = A.record
_size(::RScalar) = ()

struct RVector{V,R} <: AbstractRArray{V,R,1}
    state::Vector{V}
    record::R
end
function RVector(::Type{E}, c::AbstractClock, A::AbstractVector) where {E<:AbstractEntry}
    state = convert(Vector, A)
    es = map(v -> E(v, c), state)
    indmap = collect(1:length(state))
    record = VectorRecord(c, es, indmap)
    return RVector(state, record)
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::AbstractVector
) where {E<:AbstractEntry}
    return RVector(E, c, v)
end

_state(A::RVector) = A.state
_record(A::RVector) = A.record
_size(A::RVector) = Size(length(_state(A)))

struct RArray{V,R,N} <: AbstractRArray{V,R,N}
    state::Vector{V}
    record::R
    function RArray(
        state::Vector{V},
        record::R,
    ) where {V,T,C,E<:AbstractEntry{V,T},N,R<:AbstractRecord{V,T,C,E,N}}
        return new{V,R,N}(state, record)
    end
end
function RArray(::Type{E}, c::AbstractClock{T}, A::AbstractArray{V}) where {V,T,E<:AbstractEntry}
    state = similar(vec(A))
    copyto!(state, A)
    sz = Size(A)
    dok = Dict{NTuple{ndims(A),Int},E{V,T}}()
    for (i, ind) in enumerate(IndexMap(sz))
        dok[ind] = E(state[i], c)
    end
    indmap = IndexMap(axes(A))
    record = DokRecord(c, dok, sz, Size(A), indmap)
    return RArray(state, record)
end
function rarray(
    ::Type{E},
    c::AbstractClock,
    v::AbstractArray
) where {E<:AbstractEntry}
    return RArray(E, c, v)
end

const RMatrix{V,R} = RArray{V,R,2}

_state(A::RArray) = A.state
_record(A::RArray) = A.record
_size(A::RArray) = _size(_record(A))
