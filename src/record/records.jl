"""
    Records{T<:AbstractRArray}

Contain a RecordedArray, whose elements are records of each element of given array.
"""
struct Records{T<:AbstractRArray}
    array::T
end

"""
    records(A::AbstractRArray) -> Records

Create a [`Records`](@ref RecordedArrays.Records) with RecordedArray `A`.
"""
records(A::AbstractRArray) = Records(A)

"""
    rarray(r::Records) -> AbstractRArray

Get array of given Records `r`.
"""
rarray(r::Records) = r.array

Base.IteratorSize(::Type{<:Records{T}}) where {T} = Base.IteratorSize(T)
Base.eltype(::Type{<:Records{T}}) where {T<:DynamicRArray} =
    DynamicEntries{eltype(T),timetype(T)}
Base.eltype(::Type{<:Records{T}}) where {T<:StaticRArray} =
    StaticEntries{eltype(T),timetype(T)}
Base.length(r::Records) = rlength(r.array)
Base.size(r::Records) = rsize(r.array)
function Base.iterate(r::Records, state=1)
    if state <= length(r)
        return r[state]::SingleEntries, state + 1
    else
        return nothing
    end
end
function Base.show(io::IO, ::MIME"text/plain", r::Records)
    print(io, "records for ")
    ns = size(r)
    A = r.array
    T = typeof(A)
    if A isa DynamicRArray
        type = " dynamic "
    elseif A isa StaticRArray
        type = " static "
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
Base.getindex(r::Records, I::Vector) = [getindex(r, i) for i in I]

"""
    AbstractEntries{V,T<:Real}

Supertype of entries, which store changes of specified variable(s) of type `V` with time
of type `T`.
"""
abstract type AbstractEntries{V,T<:Real} end
Base.IteratorSize(::Type{<:AbstractEntries}) = Base.HasLength()
Base.length(e::AbstractEntries) = length(ts(e))
function Base.iterate(e::AbstractEntries, state=1)
    if state <= length(e)
        return e[state], state + 1
    else
        return nothing
    end
end

"""
    ts(e::AbstractEntries{V,T}) -> Vector{T}

Get time entries of given `e`.
"""
function ts end

"""
    vs(e::AbstractEntries{V,T}) -> VecOrMat{V}

Get value entries of given `e`.
"""
function vs end

"""
    tspan(e::AbstractEntries{V,T}) -> T

Get last time of given `e`.
"""
tspan(e::AbstractEntries) = (tse = ts(e); tse[end] - tse[1])

valuetype(::AbstractEntries{V}) where {V} = V

"""
    gettime(e::AbstractEntries{V}, t::Real) -> V
    gettime(e::AbstractEntries{V}, ts) -> Vector{V}

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

julia> ed = records(d)[1]
Record Entries
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

julia> es = records(s)[2]
Record Entries
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
    toseries(e::AbstractEntries)

Convert `e` to the form accepted by `plot` of `Plots.jl`.
"""
function toseries end
toseries(e::AbstractEntries) = ts(e), vs(e)

function Base.show(io::IO, ::MIME"text/plain", e::AbstractEntries)
    println(io, "Record Entries")
    print(io, "t: ")
    show(io, MIME("text/plain"), ts(e))
    print(io, "\nv: ")
    show(io, MIME("text/plain"), vs(e))
    return nothing
end

"""
    SingleEntries{V,T} <: AbstractEntries{V,T}

Type to store changes of a specified variable of type `V` with time of type `T`, element of
[`Records`](@ref RecordedArrays.Records).
"""
abstract type SingleEntries{V,T} <: AbstractEntries{V,T} end
Base.eltype(::Type{<:SingleEntries{V,T}}) where {V,T} = Pair{T,V}

"""
    DynamicEntries{V,T} <: AbstractEntries{V,T}

Specifical single entries type to store changes of a [`DynamicRArray`](@ref).
"""
struct DynamicEntries{V,T} <: SingleEntries{V,T}
    ts::Vector{T}
    vs::Vector{V}
    function DynamicEntries(ts::Vector{T}, vs::Vector{V}) where {T,V}
        length(ts) != length(vs) && throw(ArgumentError("ts and vs must be same length."))
        issorted(ts) || throw(ArgumentError("ts must be monotonically increasing"))
        return new{V,T}(ts, vs)
    end
end

Base.getindex(e::DynamicEntries, i::Integer) = ts(e)[i] => vs(e)[i]

vs(e::DynamicEntries) = e.vs
ts(e::DynamicEntries) = e.ts


"""
    StaticEntries{V,T} <: AbstractEntries{V,T}

Specifical single entries type to store changes of a [`StaticRArray`](@ref).
"""
struct StaticEntries{V,T} <: SingleEntries{V,T}
    s::T
    e::T
    v::V
end

Base.length(::StaticEntries) = 2
function Base.getindex(e::StaticEntries, i::Integer)
    if i == 1
        return e.s => e.v
    elseif i == 2
        return e.e => e.v
    else
        throw(BoundsError(e, i))
    end
end

vs(e::StaticEntries) = [e.v, e.v]
ts(e::StaticEntries) = [e.s, e.e]

"""
    UnionEntries{V,T,N} <: AbstractEntries{T,V}

Type store changes of `N` variables of type `V` with time of type `T`, created by
[`unione`](@ref).
"""
struct UnionEntries{V,T,N,E<:NTuple{N,SingleEntries{T,V}}} <: AbstractEntries{T,V}
    es::E
end

Base.eltype(::Type{<:UnionEntries{V,T}}) where {V,T} = Pair{T,Vector{V}}
function Base.getindex(e::UnionEntries, i::Integer)
    t = ts(e)[i]
    return t => [gettime(BinarySearch(), i, t) for i in e.es]
end

vs(e::UnionEntries) = gettime(BinarySearch(), e, ts(e))
ts(e::UnionEntries) = sort(union(ts.(e.es)...))

"""
    unione(es::AbstractEntries...)
    unione(es::Vector{<:AbstractEntries})
    unione(r::Records)

Construct the union of given entries `es`. `union(r)` construct union all of
elements of Records `r`.

# Examples

```jldoctest
julia> c = DiscreteClock(3);

julia> v = DynamicRArray(c, [1, 1, 1]);

julia> for t in c
           v[t] = 2
       end

julia> ea, eb, ec = records(v);

julia> ue = unione(ea, eb)
Record Entries
t: 3-element Vector{Int64}:
 0
 1
 2
v: 3×2 Matrix{Int64}:
 1  1
 2  1
 2  2

julia> ue = unione(ue, ec)
Record Entries
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

julia> unione(records(v))
Record Entries
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
unione(e1::SingleEntries, e2::SingleEntries) = UnionEntries((e1, e2))
unione(e1::UnionEntries, e2::SingleEntries) = UnionEntries((e1.es..., e2))
unione(e1::SingleEntries, e2::UnionEntries) = UnionEntries((e1, e2.es...))
unione(e1::UnionEntries, e2::UnionEntries) = UnionEntries((e1.es..., e2.es...))
unione(e::SingleEntries) = UnionEntries((e,))
unione(e::UnionEntries) = e
unione(es::SingleEntries...) = UnionEntries(es)
unione(es::Vector{<:AbstractEntries}) = unione(es...)
unione(r::Records) = unione(r...)
function unione(e1::AbstractEntries, e2::AbstractEntries, es::AbstractEntries...)
    return unione(unione(e1, e2), es...)
end


# search algorithm
abstract type AbstractSearch end
struct LinearSearch <: AbstractSearch end
struct BinarySearch <: AbstractSearch end

gettime(e::AbstractEntries, t) = gettime(BinarySearch(), e, t)

function gettime(::LinearSearch, e::DynamicEntries{V}, t::Real) where {V}
    ts_e = ts(e)
    vs_e = vs(e)
    ts_e[1] > t && return zero(V)
    for i in eachindex(ts_e)
        ts_e[i] > t && return vs_e[i-1]
    end
    return vs_e[end]
end

function gettime(::BinarySearch, e::DynamicEntries{V}, t::Real) where {V}
    match = searchsortedlast(ts(e), t)
    return match == 0 ? zero(V) : vs(e)[match]
end

function gettime(::AbstractSearch, e::StaticEntries{V}, t::Real) where {V}
    return t <  e.s ? zero(V) :
           t <= e.e ? e.v : zero(V)
end

function gettime(alg::AbstractSearch, e::SingleEntries{V}, ts_e) where {V}
    state = _init_state(e)
    vs_e = Vector{V}(undef, length(ts_e))
    state = _init_state(e)
    v  = zero(V)
    @inbounds for (i, t) in enumerate(ts_e)
        v::V, state = _gettime_itr(alg, e, t, v, state)
        vs_e[i] = v
    end
    return vs_e
end

gettime(alg::AbstractSearch, e::UnionEntries, t::Real) = [gettime(alg, i, t) for i in e.es]
function gettime(alg::AbstractSearch, e::UnionEntries{V}, ts_e) where {V}
    N = length(e.es)
    vs_e = Matrix{V}(undef, length(ts_e), N)
    @inbounds for i in 1:N
        ei = e.es[i]
        state = _init_state(ei)
        v = zero(V)
        for (j, t) in enumerate(ts_e)
            v::V, state = _gettime_itr(alg, ei, t, v, state)
            vs_e[j, i] = v
        end
    end
    return vs_e
end

_gettime_itr(::AbstractSearch, ::SingleEntries{V}, ::Real, v::V, ::Nothing) where {V} = v, nothing

_init_state(e::DynamicEntries) = 1, length(e)
function _gettime_itr(::LinearSearch, e::DynamicEntries{V}, t::Real, ::V, state::Tuple{Int,Int}) where {V}
    ts_e = ts(e)
    vs_e = vs(e)
    lo, hi = state
    lo == 1 && ts_e[1] > t && return zero(V), state
    for i in lo:hi
        ts_e[i] > t && return vs_e[i-1], (i-1, hi)
    end
    return vs_e[hi], nothing
end

function _gettime_itr(::BinarySearch, e::DynamicEntries{V}, t::Real, ::V, state::Tuple{Int,Int}) where {V}
    ts_e = ts(e)
    vs_e = vs(e)
    lo, hi = state
    m = searchsortedlast(ts_e, t, lo, hi, Base.Order.Forward)
    if m + 1 == lo
        return zero(V), state
    elseif m == hi
        return vs_e[hi], nothing
    else
        return vs_e[m], (m, hi)
    end
end

_init_state(::StaticEntries) = true
function _gettime_itr(::AbstractSearch, e::StaticEntries{V}, t::Real, ::V, state::Bool) where {V}
    state && e.s > t && return zero(V), true
    if e.e >= t
        return e.v, false
    else
        return zero(V), nothing
    end
end

# vim:tw=92:ts=4:sw=4:et
