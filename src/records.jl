"""
    Records{T<:AbstractRArray}

Contain a RecordedArray, whose elements are records of each element of given array.
"""
struct Records{T<:AbstractRArray}
    array::T
end

"""
    records(A::AbstractRArray)

Create a [`Records`](@ref RecordedArrays.Records) with RecordedArray `A`.
"""
records(A::AbstractRArray) = Records(A)

Base.IteratorSize(::Type{<:Records{T}}) where {T} = Base.IteratorSize(T)
Base.eltype(::Type{<:Records{T}}) where {T<:DynamicRArray} =
    DynamicEntries{timetype(T),eltype(T)}
Base.eltype(::Type{<:Records{T}}) where {T<:StaticRArray} =
    StaticEntries{timetype(T),eltype(T)}
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
    if length(ns) == 1
        print(io, ns[1], "-element")
    else
        join(io, ns, "×")
    end
    print(io, type, typeof(state(r.array)), " with time ", timetype(T))
    return nothing
end

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

"""
    toseries(e::AbstractEntries)

Convert `e` to the form accepted by `plot` of `Plots.jl`.
"""
toseries(e::AbstractEntries) = ts(e), vs(e)

"""
    gettime(e::AbstractEntries, t::Real, [indrange::Tuple=(1,length)])

Get the value(s) of `e` at time `t`, If `t` is not in `ts(e)`, return value at time
`ts(e)[i]` where `ts(e)[i] < t < ts(e)[i+1]`. If `indrange` is specified, will only search
`i` in `indrange[1]:indrange[2]`. The return value is a tuple consists of the value and
some information about next search which is useful during iteration.

# Examples

```jldoctest
julia> c = DiscreteClock(5);

julia> n = DynamicRArray(c, 0);

julia> for t in c
           n[1] += 1
       end

julia> e = records(n)[1]
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

julia> v, state = gettime(e, 1.5);

julia> v
1

julia> state
(2, 6)

julia> state = (1, length(e))
(1, 6)

julia> for t in 0:0.5:6
           v, state = gettime(e, t, state)
           print(v, " ")
       end
0 0 1 1 2 2 3 3 4 4 5 5 5
```
"""
function gettime end

gettime(::AbstractEntries, ::Real, v::Tuple{Any,Nothing}) = (v[1], v)

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
        return new{V,T}(ts, vs)
    end
end

Base.getindex(e::DynamicEntries, i::Integer) = ts(e)[i] => vs(e)[i]

vs(e::DynamicEntries) = e.vs
ts(e::DynamicEntries) = e.ts

_init_state(e::DynamicEntries) = 1, length(e)
function gettime(e::DynamicEntries, t::Real, state::Tuple{Int,Int}=_init_state(e))
    ts_e = ts(e)
    vs_e = vs(e)
    l, h = state
    l == 1 && ts_e[1] > t && return zero(eltype(vs_e)), state
    for i in l:h
        ts_e[i] > t && return vs_e[i-1], (i-1, h)
    end
    return vs_e[end], (vs_e[end], nothing)
end

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

_init_state(::StaticEntries) = true
function gettime(e::StaticEntries, t::Real, state::Bool=_init_state(e))
    state && e.s > t && return zero(e.v), state
    if e.e >= t
        return e.v, false
    else
        zero_v = zero(e.v)
        return zero_v, (zero_v, nothing)
    end
end

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
    return t => [gettime(i, t)[1] for i in e.es]
end

function vs(e::UnionEntries{V}) where {V}
    ts_e = ts(e)
    N = length(e.es)
    vs_e = Matrix{V}(undef, length(ts_e), N)
    for i in 1:N
        ei = e.es[i]
        state = _init_state(e)
        for (j, t) in enumerate(ts_e)
            vs_e[j, i], state = gettime(ei, t, state)
        end
    end
    return vs_e
end
ts(e::UnionEntries) = sort(union(ts.(e.es)...))

_init_state(e::UnionEntries) = Any[_init_state(i) for i in e.es]
function gettime(e::UnionEntries{V}, t::Real, state::Vector=_init_state(e)) where {V}
    es = e.es
    N = length(es)
    v_e = Vector{V}(undef, N)
    for i in 1:N
        v_e[i], state[i] = gettime(es[i], t, state[i])
    end
    return v_e, state
end

function Base.show(io::IO, ::MIME"text/plain", e::AbstractEntries)
    println(io, "Record Entries")
    print(io, "t: ")
    show(io, MIME("text/plain"), ts(e))
    print(io, "\nv: ")
    show(io, MIME("text/plain"), vs(e))
    return nothing
end

"""
    unione(es::AbstractEntries...)
    unione(es::Vector{<:AbstractEntries})
    unione(r::Records)

Construct the union of given entries `es`. `union(r)` construct union all of elements of
Records `r`. See example.

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
# vim:tw=92:ts=4:sw=4:et
