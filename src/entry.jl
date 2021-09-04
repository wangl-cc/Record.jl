"""
    AbstractEntry{V,T<:Real}

Supertype of all entry types, which store changes of a specified variable of type `V`
with timestamps of type `T`.
"""
abstract type AbstractEntry{V,T<:Real} end

Base.zero(::Type{E}) where {E<:AbstractEntry} = E()

# Show methods
function Base.show(io::IO, ::MIME"text/plain", e::AbstractEntry)
    summary(io, e)
    ts = getts(e)
    isempty(ts) && return nothing
    print(io, " with timestamps:\n ")
    join(io, ts, "\n ")
    return nothing
end

# Tools
"""
    store!(e::AbstractEntry, v, t::Union{Real,AbstractClock})

Store a entry with value `v` at time `t`.
"""
store!(e::AbstractEntry, v, c::AbstractClock) = store!(e, v, currenttime(c))

"""
    del!(e::AbstractEntry, t::Union{Real,AbstractClock})

Delete the entry `e` at time `t`. If an AbstractClock `c` is given,
`t = currenttime(c)`.
"""
del!(e::AbstractEntry, c::AbstractClock) = del!(e, currenttime(c))

"""
    getts(e::AbstractEntry{V,T}) -> Vector{T}

Get timestamps of given entry `e`.
"""
getts

"""
    getvs(e::AbstractEntry{V,T}) -> Vector{V}

Get values at each timestamp of given entry `e`.
"""
getvs

"""
    tspan(e::AbstractEntry{V,T}) -> T

Get last time of given `e`.
"""
tspan(e::AbstractEntry) = (ts = getts(e); ts[end] - ts[1])

# search algorithm
abstract type AbstractSearch end
struct LinearSearch <: AbstractSearch end
struct BinarySearch <: AbstractSearch end

"""
    gettime([alg::AbstractSearch], e::AbstractEntry, t::Real)
    gettime([alg::AbstractSearch], e::AbstractEntry, ts)

Get the value of `e` at `t::Real` or values at each time `t` in an iterate `ts`.
If `t` is not a timestamp  in `getts(e)`, return value at time `getts(e)[i]` where
`getts(e)[i] < t < getts(e)[i+1]`. The `alg` is a search algorithm that finds
the index `i` of a target time `t`, which can be `LinearSearch` or `BinarySearch`
(by default).

!!! note

    `ts` must be monotonically increasing.

# Examples

```jldoctest
```
"""
gettime(e::AbstractEntry, t) = gettime(BinarySearch(), e, t)
function gettime(alg::AbstractSearch, e::AbstractEntry{V}, ts) where {V}
    return gettime!(alg, Vector{V}(undef, length(ts)), e, ts)
end
function gettime!(alg::AbstractSearch, dst, e::AbstractEntry{V}, ts) where {V}
    state = _initstate(e)
    v = zero(V)
    for (i, t) in enumerate(ts)
        v::V, state = _gettime_itr(alg, e, t, v, state)
        dst[i] = v
    end
    return dst
end
_gettime_itr(::AbstractSearch, ::AbstractEntry, ::Real, v, ::Nothing) = v, nothing

"""
    DynamicEntry{V,T} <: AbstractEntry{V,T}

Entry type to store changing history of a variable whose value changing overtime.
"""
struct DynamicEntry{V,T<:Real} <: AbstractEntry{V,T}
    vs::Vector{V}
    ts::Vector{T}
    function DynamicEntry{V,T}(v::V, t::T) where {V,T}
        return new{V,T}([v], [t])
    end
    function DynamicEntry{V,T}() where {V,T}
        return new{V,T}(V[], T[])
    end
end
DynamicEntry{V,T}(v, t) where {V,T} = DynamicEntry{V,T}(convert(V, v), convert(T, t))

store!(e::DynamicEntry, v, t::Real) = (push!(getvs(e), v); push!(getts(e), t); e)
del!(e::DynamicEntry, ::Real) = e

getts(e::DynamicEntry) = e.ts
getvs(e::DynamicEntry) = e.vs

function gettime(::LinearSearch, e::DynamicEntry{V}, t::Real) where {V}
    ts = getts(e)
    vs = getvs(e)
    @inbounds ts[1] > t && return zero(V)
    @inbounds for i in eachindex(ts)
        ts[i] > t && return vs[i-1]
    end
    return vs[end]
end

function gettime(::BinarySearch, e::DynamicEntry{V}, t::Real) where {V}
    match = searchsortedlast(getts(e), t)
    return match == 0 ? zero(V) : getvs(e)[match]
end

_initstate(e::DynamicEntry) = 1, length(getvs(e))

function _gettime_itr(
    ::LinearSearch,
    e::DynamicEntry{V},
    t::Real,
    ::V,
    state::Tuple{Int,Int},
) where {V}
    ts = getts(e)
    vs = getvs(e)
    lo, hi = state
    lo == 1 && ts[1] > t && return zero(V), state
    @inbounds for i in lo:hi
        ts[i] > t && return vs[i-1], (i - 1, hi)
    end
    return vs[hi], nothing
end
function _gettime_itr(
    ::BinarySearch,
    e::DynamicEntry{V},
    t::Real,
    ::V,
    state::Tuple{Int,Int},
) where {V}
    ts = getts(e)
    vs = getvs(e)
    lo, hi = state
    m = searchsortedlast(ts, t, lo, hi, Base.Order.Forward)
    if m + 1 == lo
        return zero(V), state
    elseif m == hi
        return vs[hi], nothing
    else
        return vs[m], (m, hi)
    end
end

"""
    StaticEntry{V,T} <: AbstractEntry{V,T}

Entry type to store changing history of a variable whose value not changing overtime.
"""
mutable struct StaticEntry{V,T<:Real} <: AbstractEntry{V,T}
    init::Bool         # initialized or not
    v::V               # value
    s::T               # start time
    delete::Bool       # deleted or not
    e::T               # end time
    function StaticEntry{V,T}(v::V, t::T) where {V,T}
        return new{V,T}(true, v, t, false) # e.e is not assigned
    end
    function StaticEntry{V,T}() where {V,T}
        return new{V,T}(false) # most of fields are not assigned
    end
end
StaticEntry{V,T}(v, t) where {V,T} = StaticEntry{V,T}(convert(V, v), convert(T, t))

function store!(e::StaticEntry, v, t::Real)
    e.init && error("the StaticEntry have be initialized")
    e.v = v
    e.s = t
    e.delete = false
    return e
end
del!(e::StaticEntry, t::Real) = (e.delete = true; e.e = t)

getts(e::StaticEntry) = e.delete ? [e.s, e.e] : [e.s]
getvs(e::StaticEntry) = e.delete ? [e.v, e.v] : [e.v]

function gettime(::AbstractSearch, e::StaticEntry{V}, t::Real) where {V}
    return t < e.s ? zero(V) : t <= e.e ? e.v : zero(V)
end

_initstate(::StaticEntry) = true

function _gettime_itr(
    ::AbstractSearch,
    e::StaticEntry{V},
    t::Real,
    ::V,
    state::Bool,
) where {V}
    state && e.s > t && return zero(V), true
    if e.e >= t
        return e.v, false
    else
        return zero(V), nothing
    end
end
