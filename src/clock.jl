"""
    AbstractClock{T<:Real}

Supertype of clocks with time of type `T`.
"""
abstract type AbstractClock{T<:Real} end

"""
    currenttime(c::AbstractClock)

Return current time of clock `c`.
"""
function currenttime end

"""
    limit(c::AbstractClock)

Return the limit of clock `c`. For a ContinuousClock `c`,
the max time might larger than `limit(c)`.
"""
function limit end

"""
    start(c::AbstractClock)

Return the start time of clock `c`.
"""
function start end

"""
    init!(c::AbstractClock)

Update current time to start time.
"""
function init! end

"""
    DiscreteClock([start], timelist)
    DiscreteClock(stop)

Clock for discrete-time process, time of which muse be increased with given step and
can't
be updated manually. The `timelist` must be a non-empty and monotonically increasing
`AbstractVector`.  If the `start` is not specified, the first item of `timelist` will be
deleted and set as `start`. During iteration, the current time will be updated automatically
and returned as iteration item. When the iteration finished without `break`, [`init!`](@ref)
will be applied.  `DiscreteClock(stop)` will create a clock with `start=0` and
`timelist=Base.OneTo(stop)`

# Examples

```jldoctest
julia> c = DiscreteClock(0:3);

julia> currenttime(c)
0

julia> [(t, currenttime(c)) for t in c]
3-element Vector{Tuple{Int64, Int64}}:
 (1, 1)
 (2, 2)
 (3, 3)

julia> currenttime(c)
0

julia> c = DiscreteClock(3); # similar to DiscreteClock(0:3)

julia> (currenttime(c), collect(c))
(0, [1, 2, 3])
```
"""
struct DiscreteClock{T<:Real,I<:AbstractVector{T}} <: AbstractClock{T}
    current::Array{T,0}
    start::T
    timelist::I
    function DiscreteClock(start::T, timelist::I) where {T,I<:AbstractVector{T}}
        return new{T,I}(fill(start), start, timelist)
    end
end
function DiscreteClock(timelist::AbstractVector)
    isempty(timelist) && throw(ArgumentError("timelist must contain at least one element"))
    return DiscreteClock(timelist[1], timelist[2:end])
end
function DiscreteClock(stop::Integer)
    stop > 0 || throw(ArgumentError("stop time must be > 0"))
    return DiscreteClock(zero(stop), Base.OneTo(stop))
end

# iterator interfaces
Base.IteratorSize(::Type{<:DiscreteClock}) = Base.HasLength()
Base.length(c::DiscreteClock) = length(c.timelist)
Base.eltype(::Type{<:DiscreteClock{T}}) where {T} = T
Base.iterate(c::DiscreteClock) = _itr_update!(c, iterate(c.timelist))
function Base.iterate(c::DiscreteClock, state)
    return _itr_update!(c, iterate(c.timelist, state))
end
_itr_update!(c::DiscreteClock, ::Nothing) = (init!(c); nothing)
function _itr_update!(c::DiscreteClock{T,I}, ret::Tuple{T,Any}) where {T,I}
    c.current[] = ret[1]
    return ret
end

# clock interfaces
currenttime(c::DiscreteClock) = c.current[]
limit(c::DiscreteClock) = last(c.timelist)
init!(c::DiscreteClock) = c.current[] = c.start
start(c::DiscreteClock) = c.start

"""
    ContinuousClock{T, I<:Union{Nothing, DiscreteClock}} <: AbstractClock{T}
    ContinuousClock(stop, [start=zero(stop)]; [max_epoch=nothing])

A clock for continuous-time process. Unlike the [`DiscreteClock`](@ref DiscreteClock),
during iteration, the current time will not be update automatically, but update by
[`increase!`](@ref increase!) manually. Besides the epoch of current iteration instead of
current time will be returned. If the `max_epoch` is specified, the iteration will break
when epoch reach to the `max_epoch`, even `currenttime(c) < limit(c)`, and break in this way the
[`init!(c)`](@ref init!) will not be applied.

# Examples

```jldoctest
julia> c = ContinuousClock(3.0; max_epoch=2);

julia> for epoch in c
           increase!(c, 1)
           println(currenttime(c), '\t', epoch)
       end
1.0	1
2.0	2

julia> for epoch in c
           increase!(c, 1)
           println(currenttime(c), '\t', epoch)
       end
3.0	1

julia> for epoch in c
           increase!(c, 1)
           println(currenttime(c), '\t', epoch)
       end
1.0	1
2.0	2
```
"""
struct ContinuousClock{T<:Real,I<:Union{Nothing,Integer}} <: AbstractClock{T}
    current::Array{T,0}
    start::T
    stop::T
    epoch::I
    function ContinuousClock(
        start::T,
        stop::T,
        epoch::I,
    ) where {T<:Real,I<:Union{Nothing,Integer}}
        start > stop && throw(ArgumentError("stop must be larger than start"))
        return new{T,I}(fill(start), start, stop, epoch)
    end
end
function ContinuousClock(
    stop::Real,
    start::Real=zero(stop);
    max_epoch::Union{Nothing,Integer}=nothing,
)
    return ContinuousClock(promote(start, stop)..., max_epoch)
end

# iterator interfaces
Base.IteratorSize(::Type{<:ContinuousClock}) = Base.SizeUnknown()
Base.eltype(::ContinuousClock{T}) where {T} = T
Base.iterate(c::ContinuousClock) =
    currenttime(c) < limit(c) ? _itr(c.epoch) : (init!(c); nothing)
Base.iterate(c::ContinuousClock, state) =
    currenttime(c) < limit(c) ? _itr(c.epoch, state) : (init!(c); nothing)

_itr(::Nothing, i::Int=1) = (i, i + 1)
_itr(lim::Integer, i::Integer=one(lim)) = ifelse(i > lim, nothing, (i, i + 1))

# clock interfaces
currenttime(c::ContinuousClock) = c.current[]
limit(c::ContinuousClock) = c.stop
start(c::ContinuousClock) = c.start
init!(c::ContinuousClock) = c.current[] = start(c)

"""
    increase!(c::ContinuousClock, t::Real)

Update current time of clock `c` to `currenttime(c) + t`.
"""
increase!(c::ContinuousClock{T}, t::Real) where {T<:Real} = increase!(c, convert(T, t))::T
increase!(c::ContinuousClock{T}, t::T) where {T<:Real} = c.current[] += t

# vim:tw=92:ts=4:sw=4:et
