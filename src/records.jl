"""
    Records{T<:AbstractRArray}

Contain a RecordedArray, whose elements are changing records of each element of given array.
"""
struct Records{T<:AbstractRArray}
    array::T
end

"""
    records(A::AbstractRArray)

Create a [Records](@ref Records) with RecordedArray `A`.
"""
records(A::AbstractRArray) = Records(A)

Base.IteratorSize(::Type{<:Records{T}}) where {T} = Base.IteratorSize(T)
Base.eltype(::Type{<:Records{T}}) where {T} = SingleEntries{timetype(T),eltype(T)}
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
    AbstractEntries{T<:Real,V}

Supertype of entries, which store changes of specified variable(s) of type `V` with time
of type `T`.
"""
abstract type AbstractEntries{T<:Real,V} end
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
    ts(e::AbstractEntries{T,V}) -> Vector{T}

Get time entries of given `e`.
"""
function ts end

"""
    vs(e::AbstractEntries{T,V}) -> VecOrMat{V}

Get value entries of given `e`.
"""
function vs end

"""
    tspan(e::AbstractEntries{T,V}) -> T

Get last time of given `e`.
"""
tspan(e::AbstractEntries) = (tse = ts(e); tse[end] - tse[1])

"""
    toseries(e::AbstractEntries)

Convert `e` to the form accepted by `plot` of `Plots.jl`.
"""
toseries(e::AbstractEntries) = ts(e), vs(e)

"""
    SingleEntries{T,V} <: AbstractEntries{T,V}

Type store changes of a specified variable of type `V` with time of type `T`, element of
[Records](@ref Records).
"""
struct SingleEntries{T,V} <: AbstractEntries{T,V}
    ts::Vector{T}
    vs::Vector{V}
    function SingleEntries(ts::Vector{T}, vs::Vector{V}) where {T,V}
        length(ts) != length(vs) && throw(ArgumentError("ts and vs must be same length."))
        return new{T,V}(ts, vs)
    end
end

Base.eltype(::Type{<:SingleEntries{T,V}}) where {T,V} = Pair{T,V}
Base.getindex(e::SingleEntries, i::Integer) = ts(e)[i] => vs(e)[i]

vs(e::SingleEntries) = e.vs
ts(e::SingleEntries) = e.ts

"""
    UnionEntries{T,V} <: AbstractEntries{T,V}

Type store changes of multiple variables of type `V` with time of type `T`, created by
[`unione`](@ref unione).
"""
struct UnionEntries{T,V} <: AbstractEntries{T,V}
    ts::Vector{T}
    vs::Matrix{V}
    function UnionEntries(ts::Vector{T}, vs::Matrix{V}) where {T,V}
        length(ts) != size(vs, 1) &&
            throw(ArgumentError("length of ts must be same as the first size of vs."))
        return new{T,V}(ts, vs)
    end
end

Base.eltype(::Type{<:UnionEntries{T,V}}) where {T,V} = Pair{T,Vector{V}}
Base.getindex(e::UnionEntries, i::Integer) = ts(e)[i] => vs(e)[i, :]

vs(e::UnionEntries) = e.vs
ts(e::UnionEntries) = e.ts

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
function gettime(e::SingleEntries, t::Real, indrange::Tuple{Integer,Integer}=(1, length(e)))
    ts_e = ts(e)
    vs_e = vs(e)
    l, h = indrange
    l == 1 && ts_e[1] > t && return (zero(eltype(vs_e)), indrange)
    for i in l:h
        ts_e[i] > t && return vs_e[i-1], (i - 1, h)
    end
    return vs_e[end], (vs_e[end], nothing)
end
function gettime(e::UnionEntries, t::Real, indrange::Tuple{Integer,Integer}=(1, size(e, 1)))
    ts_e = ts(e)
    vs_e = vs(e)
    n = size(vs_e, 2)
    l, h = indrange
    l == 1 && ts_e[1] > t && return (zeros(eltype(vs_e), n), indrange)
    for i in l:h
        ts_e[i] > t && return vs_e[i-1, :], (i - 1, h)
    end
    return vs_e[end, :], (vs_e[end, :], nothing)
end
gettime(::AbstractEntries, ::Real, v::Tuple{Any,Nothing}) = (v[1], v)

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
function unione(e1::AbstractEntries, e2::AbstractEntries)
    ts_new = sort(union(ts(e1), ts(e2)))
    vs1 = vs(e1)
    vs2 = vs(e2)
    V = promote_type(eltype(vs1), eltype(vs2))
    vs_new = Matrix{V}(undef, length(ts_new), size(vs1, 2) + size(vs2, 2))
    state1 = (1, length(e1))
    state2 = (1, length(e2))
    for i in eachindex(ts_new)
        t = ts_new[i]
        v1, state1 = gettime(e1, t, state1)
        v2, state2 = gettime(e2, t, state2)
        vs_new[i, :] = vcat(v1, v2)
    end
    return UnionEntries(ts_new, vs_new)
end
@inline unione(es::Vector{<:AbstractEntries}) = unione(es...)
@inline unione(e1::AbstractEntries) = e1
@inline unione(r::Records) = unione(r...)
function unione(e1::AbstractEntries, e2::AbstractEntries, es::AbstractEntries...)
    return unione(unione(e1, e2), es...)
end
# vim:tw=92:ts=4:sw=4:et
