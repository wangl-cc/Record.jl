import Base: +, -, *, /, \, ^, conj, real, imag

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

Base.promote_rule(
    ::Type{<:RecordedNumber{S}},
    ::Type{<:RecordedNumber{T}},
) where {S<:Number,T<:Number} = promote_type(S, T)
Base.promote_rule(::Type{<:RecordedNumber{S}}, ::Type{T}) where {S<:Number,T<:Number} =
    promote_type(S, T)
Base.promote_rule(::Type{S}, ::Type{<:RecordedNumber{T}}) where {S<:Number,T<:Number} =
    promote_type(S, T)

Base.show(io::IO, ::MIME"text/plain", x::RecordedNumber) = show(io, state(x))

@inline state(n::RecordedNumber{T}) where {T} = _state(n)::T

@inline Base.getindex(x::RecordedNumber) = state(x)
@inline function Base.getindex(x::RecordedNumber, i::Integer)
    @boundscheck isone(i) || throw(BoundsError())
    return state(x)
end
@inline function Base.getindex(x::RecordedNumber, I::Integer...)
    @boundscheck all(isone, I) || throw(BoundsError())
    return state(x)
end

for op in (:+, :-, :conj, :real, :imag)
    @eval @inline Base.($op)(x::RecordedNumber) = ($op)(state(x))
end

for op in (:+, :-, :*, :/, :\, :^)
    @eval @inline Base.($op)(x::RecordedNumber{T}, y::RecordedNumber{T}) where {T} =
        ($op)(state(x), state(y))
end

struct RNumber{T<:Number,R} <: Number
    v::T
    record::R
end
recorded(::Type{E}, c::AbstractClock, n::Number) where {E<:AbstractEntry} =
    RNumber(n, Record{E}(c, n))

_state(x::RNumber) = x.v
getrecord(x::RNumber) = x.record

Base.setindex!(x::RNumber, v, I...) = (getrecord(x)[I...] = v; x.v = v; v)

struct RReal{T<:Real,R} <: Real
    v::T
    record::R
end
recorded(::Type{E}, c::AbstractClock, n::Real) where {E<:AbstractEntry} =
    RReal(n, Record{E}(c, n))

_state(x::RReal) = x.v
getrecord(x::RReal) = x.record

Base.setindex!(x::RReal, v, I...) = (getrecord(x)[I...] = v; x.v = v; v)

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
