"""
    Record{T<:AbstractRArray}

Contain a RecordedArray, whose elements are record of each element of given array.
"""
struct Record{T<:AbstractRArray}
    array::T
end

"""
    record(A::AbstractRArray) -> Record

Create a [`Record`](@ref RecordedArrays.Record) with RecordedArray `A`.
"""
record(A::AbstractRArray) = Record(A)

"""
    rarray(r::Record) -> AbstractRArray

Get array of given Record `r`.
"""
rarray(r::Record) = r.array

Base.IteratorSize(::Type{<:Record{T}}) where {T} = Base.IteratorSize(T)
Base.eltype(::Type{<:Record{T}}) where {T<:DynamicRArray} =
    DynamicEntry{eltype(T),timetype(T)}
Base.eltype(::Type{<:Record{T}}) where {T<:StaticRArray} =
    StaticEntry{eltype(T),timetype(T)}
Base.length(r::Record) = rlength(r.array)
Base.size(r::Record) = rsize(r.array)
Base.firstindex(::Record) = 1
Base.lastindex(r::Record) = length(r)
function Base.iterate(r::Record, state=1)
    if state <= length(r)
        return r[state]::SingleEntry, state + 1
    else
        return nothing
    end
end
function Base.show(io::IO, ::MIME"text/plain", r::Record)
    print(io, "record for ")
    ns = size(r)
    A = r.array
    T = typeof(A)
    if A isa DynamicRArray
        type = " dynamic "
    elseif A isa StaticRArray
        type = " static "
    else
        type = " "
    end
    if isempty(ns)
        print(io, "0-dimensional")
    elseif length(ns) == 1
        print(io, ns[1], "-element")
    else
        join(io, ns, "×")
    end
    print(io, type, typeof(state(r.array)), " with time ", timetype(T))
    return nothing
end
Base.getindex(r::Record, i::Int) = rgetindex(r.array, i)
Base.getindex(r::Record, I::Vector) = [getindex(r, i) for i in I]

"""
    AbstractEntry{V,T<:Real}

Supertype of entry, which store changes of specified variable(s) of type `V` with time
of type `T`.
"""
abstract type AbstractEntry{V,T<:Real} end
Base.IteratorSize(::Type{<:AbstractEntry}) = Base.HasLength()
Base.length(e::AbstractEntry) = length(getts(e))
Base.firstindex(::AbstractEntry) = 1
Base.lastindex(e::AbstractEntry) = length(e)
function Base.iterate(e::AbstractEntry, state=1)
    if state <= length(e)
        return e[state], state + 1
    else
        return nothing
    end
end

"""
    getts(e::AbstractEntry{V,T}) -> Vector{T}

Get time entry of given `e`.
"""
function getts end

"""
    getvs(e::AbstractEntry{V,T}) -> VecOrMat{V}

Get value entry of given `e`.
"""
function getvs end

"""
    tspan(e::AbstractEntry{V,T}) -> T

Get last time of given `e`.
"""
tspan(e::AbstractEntry) = (tse = getts(e); tse[end] - tse[1])

"""
    gettime(e::Union{Record,AbstractEntry}, t::Real)
    gettime(e::Union{Record,AbstractEntry}, ts)

Get the value(s) of `e` at time `t`, If `t` is not in `ts(e)`, return value at time
`ts(e)[i]` where `ts(e)[i] < t < ts(e)[i+1]`. If a iterator of time `ts` is given,
return the value of each time in `ts`.

!!! note

    `ts` must be monotonically increasing.

# Examples

```jldoctest
julia> c = DiscreteClock(5);

julia> d = DynamicRArray(c, 0);

julia> s = StaticRArray(c, [0]);

julia> for t in c
           d[1] += 1
           push!(s, t)
           t >= 3 && deleteat!(s, 1)
       end

julia> ed = record(d)[1]
Record Entry
t: 6-element Vector{Int64}:
 0
 1
 2
 3
 4
 5
v: 6-element Vector{Int64}:
 0
 1
 2
 3
 4
 5

julia> es = record(s)[2]
Record Entry
t: 2-element Vector{Int64}:
 1
 4
v: 2-element Vector{Int64}:
 1
 1

julia> gettime(ed, 1.5)
1

julia> gettime(ed, [5, 6])
2-element Vector{Int64}:
 5
 5

julia> gettime(es, [2, 5])
2-element Vector{Int64}:
 1
 0
```
"""
function gettime end

"""
    toseries(e::AbstractEntry)

Convert `e` to the form accepted by `plot` of `Plots.jl`.
"""
function toseries end
toseries(e::AbstractEntry) = getts(e), getvs(e)

function Base.show(io::IO, ::MIME"text/plain", e::AbstractEntry)
    println(io, "Record Entry")
    print(io, "t: ")
    show(io, MIME("text/plain"), getts(e))
    print(io, "\nv: ")
    show(io, MIME("text/plain"), getvs(e))
    return nothing
end

"""
    SingleEntry{V,T} <: AbstractEntry{V,T}

Type to store changes of a specified variable of type `V` with time of type `T`, element of
[`Record`](@ref RecordedArrays.Record).
"""
abstract type SingleEntry{V,T} <: AbstractEntry{V,T} end
Base.eltype(::Type{<:SingleEntry{V,T}}) where {V,T} = Pair{T,V}

"""
    DynamicEntry{V,T} <: AbstractEntry{V,T}

Specifical single entry type to store changes of a [`DynamicRArray`](@ref).
"""
struct DynamicEntry{V,T} <: SingleEntry{V,T}
    ts::Vector{T}
    vs::Vector{V}
    function DynamicEntry(ts::Vector{T}, vs::Vector{V}) where {T,V}
        length(ts) != length(vs) && throw(ArgumentError("ts and vs must be same length."))
        issorted(ts) || throw(ArgumentError("ts must be monotonically increasing"))
        return new{V,T}(ts, vs)
    end
end

Base.getindex(e::DynamicEntry, i::Integer) = getts(e)[i] => getvs(e)[i]

getvs(e::DynamicEntry) = e.vs
getts(e::DynamicEntry) = e.ts

"""
    StaticEntry{V,T} <: AbstractEntry{V,T}

Specifical single entry type to store changes of a [`StaticRArray`](@ref).
"""
struct StaticEntry{V,T} <: SingleEntry{V,T}
    s::T
    e::T
    v::V
end

Base.length(::StaticEntry) = 2
function Base.getindex(e::StaticEntry, i::Integer)
    if i == 1
        return e.s => e.v
    elseif i == 2
        return e.e => e.v
    else
        throw(BoundsError(e, i))
    end
end

getvs(e::StaticEntry) = [e.v, e.v]
getts(e::StaticEntry) = [e.s, e.e]

"""
    UnionEntry{V,T,N} <: AbstractEntry{T,V}

Type store changes of `N` variables of type `V` with time of type `T`, created by
[`unione`](@ref).
"""
struct UnionEntry{V,T,N,E<:NTuple{N,SingleEntry{T,V}}} <: AbstractEntry{T,V}
    es::E
end

Base.eltype(::Type{<:UnionEntry{V,T}}) where {V,T} = Pair{T,Vector{V}}
function Base.getindex(e::UnionEntry, i::Integer)
    t = getts(e)[i]
    return t => [gettime(BinarySearch(), i, t) for i in e.es]
end

getvs(e::UnionEntry) = gettime(BinarySearch(), e, getts(e))
getts(e::UnionEntry) = sort(union(map(getts, e.es)...))

"""
    unione(es::AbstractEntry...)
    unione(es::Vector{<:AbstractEntry})
    unione(r::Record)

Construct the union of given entry `es`. `union(r)` construct union all of
elements of Record `r`.

# Examples

```jldoctest
julia> c = DiscreteClock(3);

julia> v = DynamicRArray(c, [1, 1, 1]);

julia> for t in c
           v[t] = 2
       end

julia> ea, eb, ec = record(v);

julia> ue = unione(ea, eb)
Record Entry
t: 3-element Vector{Int64}:
 0
 1
 2
v: 3×2 Matrix{Int64}:
 1  1
 2  1
 2  2

julia> ue = unione(ue, ec)
Record Entry
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4×3 Matrix{Int64}:
 1  1  1
 2  1  1
 2  2  1
 2  2  2

julia> unione(record(v))
Record Entry
t: 4-element Vector{Int64}:
 0
 1
 2
 3
v: 4×3 Matrix{Int64}:
 1  1  1
 2  1  1
 2  2  1
 2  2  2
```
"""
unione(e1::SingleEntry, e2::SingleEntry) = UnionEntry((e1, e2))
unione(e1::UnionEntry, e2::SingleEntry) = UnionEntry((e1.es..., e2))
unione(e1::SingleEntry, e2::UnionEntry) = UnionEntry((e1, e2.es...))
unione(e1::UnionEntry, e2::UnionEntry) = UnionEntry((e1.es..., e2.es...))
unione(e::SingleEntry) = UnionEntry((e,))
unione(e::UnionEntry) = e
unione(es::SingleEntry...) = UnionEntry(es)
unione(es::Vector{<:AbstractEntry}) = unione(es...)
unione(r::Record) = unione(r...)
function unione(e1::AbstractEntry, e2::AbstractEntry, es::AbstractEntry...)
    return unione(unione(e1, e2), es...)
end

# search algorithm
abstract type AbstractSearch end
struct LinearSearch <: AbstractSearch end
struct BinarySearch <: AbstractSearch end

const RecEntry = Union{Record,AbstractEntry}

gettime(e::RecEntry, t) = gettime(BinarySearch(), e, t)

function gettime(alg, r::Record, t::Real)
    ret = similar(rarray(r), size(r))
    for i in eachindex(ret)
        @inbounds ret[i] = gettime(alg, r[i], t)
    end
    return ret
end

function gettime(alg, r::Record, ts)
    size_r = size(r)
    ret = similar(rarray(r), length(ts), size_r...)
    for ind in CartesianIndices(size_r)
        sub = @view ret[:, ind.I...]
        @inbounds gettime!(alg, sub, r[ind.I...], ts)
    end
    return ret
end

function gettime(::LinearSearch, e::DynamicEntry{V}, t::Real) where {V}
    ts = getts(e)
    vs = getvs(e)
    ts[1] > t && return zero(V)
    for i in eachindex(ts)
        ts[i] > t && return vs[i-1]
    end
    return vs[end]
end

function gettime(::BinarySearch, e::DynamicEntry{V}, t::Real) where {V}
    match = searchsortedlast(getts(e), t)
    return match == 0 ? zero(V) : getvs(e)[match]
end

function gettime(::AbstractSearch, e::StaticEntry{V}, t::Real) where {V}
    return t < e.s ? zero(V) : t <= e.e ? e.v : zero(V)
end

function gettime(alg::AbstractSearch, e::SingleEntry{V}, ts) where {V}
    return gettime!(alg, Vector{V}(undef, length(ts)), e, ts)
end

function gettime!(
    alg::AbstractSearch,
    dst::AbstractVector{V},
    e::SingleEntry{V},
    ts,
) where {V}
    state = _init_state(e)
    v = zero(V)
    @inbounds for (i, t) in enumerate(ts)
        v::V, state = _gettime_itr(alg, e, t, v, state)
        dst[i] = v
    end
    return dst
end

gettime(alg::AbstractSearch, e::UnionEntry, t::Real) = [gettime(alg, i, t) for i in e.es]
function gettime(alg::AbstractSearch, e::UnionEntry{V}, ts) where {V}
    return gettime!(alg, Matrix{V}(undef, length(ts), length(e.es)), e, ts)
end

function gettime!(
    alg::AbstractSearch,
    dst::AbstractMatrix{V},
    e::UnionEntry{V},
    ts,
) where {V}
    @inbounds for i in 1:size(dst, 2)
        ei = e.es[i]
        state = _init_state(ei)
        v = zero(V)
        for (j, t) in enumerate(ts)
            v::V, state = _gettime_itr(alg, ei, t, v, state)
            dst[j, i] = v
        end
    end
    return dst
end

_gettime_itr(::AbstractSearch, ::SingleEntry{V}, ::Real, v::V, ::Nothing) where {V} =
    v, nothing

_init_state(e::DynamicEntry) = 1, length(e)
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
    for i in lo:hi
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

_init_state(::StaticEntry) = true
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

# vim:tw=92:ts=4:sw=4:et
