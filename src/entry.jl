"""
    AbstractEntry{V,T<:Real}

Supertype of all entry types, which store changes of a specified variable of type `V`
with timestamps of type `T`.
"""
abstract type AbstractEntry{V,T<:Real} end

Base.zero(::Type{E}) where {E<:AbstractEntry} = E()
Base.valtype(::Type{E}) where {V,E<:AbstractEntry{V}} = V

return_type(::Type{E}, v, t) where {E<:AbstractEntry} =
    _return_type(E, _typeof(v), _typeof(t))

_typeof(::T) where {T} = T
_typeof(::Type{T}) where {T} = T
_typeof(::AbstractArray{T}) where {T} = T
_typeof(::AbstractClock{T}) where {T} = T

_return_type(::Type{E}, ::Type{V}, ::Type{T}) where {V,T,E<:AbstractEntry} = E{V,T}
_return_type(::Type{E}, ::Type{V}, ::Type{T}) where {V,T,VE,E<:AbstractEntry{VE}} = E{T}
_return_type(
    ::Type{E},
    ::Type{V},
    ::Type{T},
) where {V,T,VE,TE<:Real,E<:AbstractEntry{VE,TE}} = E

# Show methods
function Base.show(io::IO, ::MIME"text/plain", e::AbstractEntry)
    summary(io, e)
    ts = getts(e)
    isempty(ts) && return nothing
    print(io, " with timestamps:\n ")
    join(io, ts, "\n ")
    return nothing
end

# Recipes
@userplot struct TimeSeries{T}
    es::T
end
@userplot struct PhasePortrait{T}
    es::T
end

@recipe function f(args::TimeSeries)
    es = _unpack(args.es...)
    for e in es
        @series begin
            getts(e), getvs(e)
        end
    end
    return nothing
end
@recipe function f(args::PhasePortrait)
    es = _unpack(args.es...)
    length(es) < 2 && error("Must have at least two entries")
    length(es) > 3 && error("Must have at most three entries")
    ts = copy(getts(es[1]))
    for e in es[2:end]
        append!(ts, getts(e))
    end
    sort!(unique!(ts))
    return Tuple(map(ei -> gettime(ei, ts), es)) # this is not type stable for array arguments
end

_unpack(es::AbstractArray{<:AbstractEntry}) = vec(es)
_unpack(A::DOKSparseArray{<:AbstractEntry}) = values(A.dok)
_unpack(es::AbstractEntry...) = es
# Tools
"""
    store!(e::AbstractEntry, v, t::Union{Real,AbstractClock})

Store a entry with value `v` at time `t`.
"""
store!(e::AbstractEntry, v, c::AbstractClock) = store!(e, v, currenttime(c))

"""
    del!(e::AbstractEntry, t::Union{Real,AbstractClock})

Marks a entry `e` deleted at time `t`.
If an AbstractClock `c` is given, `t = currenttime(c)`.
"""
del!(e::AbstractEntry, c::AbstractClock) = del!(e, currenttime(c))

"""
    getts(e::AbstractEntry{V,T}) -> Vector{T}

Get timestamps of an entry `e`.
"""
getts

"""
    getvs(e::AbstractEntry{V,T}) -> Vector{V}

Get values at each timestamp of an entry `e`.
"""
getvs

"""
    tspan(e::AbstractEntry{V,T}) -> T

Get last time of an entry `e`.
"""
tspan(e::AbstractEntry) = (ts = getts(e); ts[end] - ts[1])

# search algorithm
abstract type AbstractSearch end
struct LinearSearch <: AbstractSearch end
struct BinarySearch <: AbstractSearch end

"""
    gettime([alg::AbstractSearch], e::AbstractEntry, t::Real)
    gettime([alg::AbstractSearch], e::AbstractEntry, ts)
    gettime([alg::AbstractSearch], es::AbstractArray{<:AbstractEntry}, t::Real)
    gettime([alg::AbstractSearch], es::AbstractArray{<:AbstractEntry}, ts)

Get the value of `e` at `t::Real` or values at each time `t` in an iterate `ts`.
If `t` is not a timestamp  in `getts(e)`, return value at time `getts(e)[i]` where
`getts(e)[i] < t < getts(e)[i+1]`. The `alg` is a search algorithm that finds
the index `i` of a target time `t`, which can be `LinearSearch` or `BinarySearch`
(by default).
For `es`, an array of entries, return values at `t` as a similar array.

!!! note

    `ts` must be monotonically increasing.
"""
gettime(e::AbstractEntry, t) = gettime(BinarySearch(), e, t) # t or ts
gettime(alg::AbstractSearch, e::AbstractEntry{V}, ts) where {V} =
    @inbounds gettime!(alg, Vector{V}(undef, length(ts)), e, ts)
function gettime!(alg::AbstractSearch, dst, e::AbstractEntry{V}, ts) where {V}
    Base.@_propagate_inbounds_meta
    state = _initstate(e)
    v = zero(V)
    for (i, t) in enumerate(ts)
        v::V, state = _gettime_itr(alg, e, t, v, state)
        dst[i] = v
    end
    return dst
end
_gettime_itr(::AbstractSearch, ::AbstractEntry, ::Real, v, ::Nothing) = v, nothing

gettime(es::AbstractArray{<:AbstractEntry}, t) = gettime(BinarySearch(), es, t) # t or ts
function gettime(alg::AbstractSearch, es::AbstractArray{<:AbstractEntry}, t::Real)
    ret = similar(es, valtype(eltype(es)))
    @inbounds for i in 1:length(es)
        if isassigned(es, i)
            ret[i] = gettime(alg, es[i], t)
        else
            ret[i] = zero(eltype(ret))
        end
    end
    return ret
end
function gettime(alg::AbstractSearch, es::AbstractArray{<:AbstractEntry}, ts)
    tlen = length(ts)
    ret = Array{valtype(eltype(es))}(undef, tlen, size(es)...)
    @inbounds for i in 1:length(es)
        if isassigned(es, i)
            gettime!(alg, view(ret, (i-1)*tlen+1:i*tlen), es[i], ts)
        else
            ret[(i-1)*tlen+1:i*tlen] .= zero(eltype(ret))
        end
    end
    return ret
end

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
DynamicEntry{V}(v, t::T) where {V,T} = DynamicEntry{V,T}(v, t)
DynamicEntry(v::V, t::T) where {V,T} = DynamicEntry{V,T}(v, t)
DynamicEntry{V,T}(v, c::C) where {V,T,C<:AbstractClock} =
    DynamicEntry{V,T}(v, currenttime(c))
DynamicEntry{V}(v, c::AbstractClock{T}) where {V,T} = DynamicEntry{V,T}(v, currenttime(c))
DynamicEntry(v::V, c::AbstractClock{T}) where {V,T} = DynamicEntry{V,T}(v, currenttime(c))

store!(e::DynamicEntry, v, t::Real) = (push!(getvs(e), v); push!(getts(e), t); e)
del!(e::DynamicEntry, ::Real) = e

getts(e::DynamicEntry) = e.ts
getvs(e::DynamicEntry) = e.vs

function gettime(::LinearSearch, e::DynamicEntry, t::Real)
    ts = getts(e)
    vs = getvs(e)
    @inbounds ts[1] > t && return zero(valtype(e))
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
StaticEntry{V}(v, t::T) where {V,T} = StaticEntry{V,T}(v, t)
StaticEntry(v::V, t::T) where {V,T} = StaticEntry{V,T}(v, t)
StaticEntry{V,T}(v, c::C) where {V,T,C<:AbstractClock} = StaticEntry{V,T}(v, currenttime(c))
StaticEntry{V}(v, c::AbstractClock{T}) where {V,T} = StaticEntry{V,T}(v, currenttime(c))
StaticEntry(v::V, c::AbstractClock{T}) where {V,T} = StaticEntry{V,T}(v, currenttime(c))

function store!(e::StaticEntry, v, t::Real)
    e.init && error("the StaticEntry has be initialized")
    e.init = true
    e.v = v
    e.s = t
    e.delete = false
    return e
end
function del!(e::StaticEntry, t::Real)
    e.init && e.delete && error("the StaticEntry has be deleted")
    e.delete = true
    e.e = t
    return e
end

getts(e::StaticEntry) = e.delete ? [e.s, e.e] : [e.s]
getvs(e::StaticEntry) = e.delete ? [e.v, e.v] : [e.v]

gettime(::AbstractSearch, e::StaticEntry{V}, t::Real) where {V} =
    t < e.s ? zero(V) : !e.delete ? e.v : t <= e.e ? e.v : zero(V)

_initstate(::StaticEntry) = true

function _gettime_itr(
    ::AbstractSearch,
    e::StaticEntry{V},
    t::Real,
    ::V,
    state::Bool,
) where {V}
    state && e.s > t && return zero(V), true
    e.delete || return e.v, nothing
    if e.e >= t
        return e.v, false
    else
        return zero(V), nothing
    end
end
