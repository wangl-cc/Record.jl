mutable struct RNumber{T<:Number,R} <: Number
    v::T
    record::R
end
recorded(::Type{E}, c::AbstractClock, n::Number) where {E<:AbstractEntry} =
    RNumber(n, Record{E}(c, n))

Base.parent(x::RNumber) = x.v
getrecord(x::RNumber) = x.record

Base.setindex!(x::RNumber, v, I...) = (getrecord(x)[I...] = v; x.v = v; v)

mutable struct RReal{T<:Real,R} <: Real
    v::T
    record::R
end
recorded(::Type{E}, c::AbstractClock, n::Real) where {E<:AbstractEntry} =
    RReal(n, Record{E}(c, n))

Base.parent(x::RReal) = x.v
getrecord(x::RReal) = x.record

"""
    RecordedNumber{T}

A `Union` of recorded numbers with type `T`.

!!! info

    `RecordedNumber{S} <: T` will always return `false` where `T` is a subtype
    of `Number`, even if `S <: T`.
    There is a function `issubtype(RecordedNumber{S}, T)`  which would return `true`
    if `S <: T`. Besides, `isnum(T, n::RecordedNumber{S})` would return `true` if
    `S <: T`.

!!! note

    Store a value `v` to an `RecordedNumber` `x` by `x[] = v` or `x[1] = v` instead of
    `x = v`.
"""
const RecordedNumber{T} = Union{RNumber{T},RReal{T}}
const RN = RecordedNumber

"""
    getentries(x::RecordedNumber)

Get entries of a recorded number `x`.
"""
getentries(x::RecordedNumber) = parent(getrecord(x))

"""
    issubtype(S, T) -> Bool

Similar to `S <: T`, but for a `S` where `S <: RecordedNumber{P}`, return `true` if
`P <: T`.
"""
issubtype(::Type{S}, ::Type{T}) where {T,S} = S <: T
issubtype(::Type{<:RecordedNumber{S}}, ::Type{T}) where {T,S} = S <: T

"""
    isnum(T, x) -> Bool

Similar to `x is T`, but for `x` where `x::RecordedNumber{S}`, return `true` if `S <:T`.
"""
isnum(::Type{T}, t::Number) where {T} = t isa T
isnum(::Type{T}, t::RecordedNumber{S}) where {T,S} = S <: T

Base.convert(::Type{T}, n::RecordedNumber{T}) where {T<:Number} = state(n)
Base.convert(::Type{T}, n::RecordedNumber) where {T<:Number} = convert(T, state(n))
Base.convert(::Type{T}, n::RecordedNumber) where {P,T<:RecordedNumber{P}} =
    convert(P, state(n))

Base.promote_rule(::Type{<:RN{S}}, ::Type{<:RN{T}}) where {S<:Number,T<:Number} =
    promote_type(S, T)
Base.promote_rule(::Type{<:RN{S}}, ::Type{T}) where {S<:Number,T<:Number} =
    promote_type(S, T)

Base.show(io::IO, ::MIME"text/plain", x::RecordedNumber) = show(io, state(x))

_unpack(x::RecordedNumber) = _unpack(getentries(x))

@inline state(n::RecordedNumber{T}) where {T} = parent(n)::T

@inline Base.getindex(x::RecordedNumber) = state(x)
@inline function Base.getindex(x::RecordedNumber, i::Integer)
    @boundscheck isone(i) || throw(BoundsError(x, i))
    return parent(x)
end
@inline function Base.getindex(x::RecordedNumber, I::Integer...)
    @boundscheck all(isone, I) || throw(BoundsError(x, I))
    return parent(x)
end

@inline Base.setindex!(x::RReal, v) = (getrecord(x)[] = v; x.v = v; x)
@inline function Base.setindex!(x::RecordedNumber, v, i::Integer)
    @boundscheck isone(i) || throw(BoundsError(x, i))
    getrecord(x)[] = v
    x.v = v
    return x
end
@inline function Base.getindex(x::RecordedNumber, v, I::Integer...)
    @boundscheck all(isone, I) || throw(BoundsError(x, I))
    getrecord(x)[] = v
    x.v = v
    return x
end

for op in (:+, :-, :conj, :real, :imag, :float)
    @eval @inline Base.$op(x::RecordedNumber) = $op(parent(x))
end

for op in (:+, :-, :*, :/, :\, :^, :(==))
    @eval @inline Base.$op(x::RecordedNumber{T}, y::RecordedNumber{T}) where {T} =
        $op(parent(x), parent(y))
end

Base.hash(x::RecordedNumber, h::UInt) = hash(state(x), h)
