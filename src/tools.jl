mutable struct Clock{T<:Real}
    t::T
    max::T
end
Clock(max::Real) = Clock(0.0, max)
Clock(t::Real, max::Real) = Clock(promote(t, max)...)

current(c::Clock) = c.t
limit(c::Clock) = c.max
isend(c::Clock) = current(c) >= limit(c)
notend(c::Clock) = current(c) < limit(c)
increase!(c::Clock, t::Real) = c.t += t

mutable struct TypeBox{V}
    v::V
end
