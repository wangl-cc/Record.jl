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
Base.eltype(::Type{<:Records{A}}) where {A} = Entries{timetype(A),eltype(A)}
Base.length(r::Records) = length(r.array)
Base.size(r::Records) = size(r.array)
function Base.iterate(r::Records, state = 1)
    if state <= length(r)
        return r[state]::Entries, state + 1
    else
        return nothing
    end
end
function Base.show(io::IO, ::MIME"text/plain", r::Records)
    print(io, "records for ")
    show(io, MIME("text/plain"), r.array)
end

"""
    Entries{T<:Real,V}

Changes of a specified variable of type `V` with time of type `T`, element of [Records](@ref Records).
"""
struct Entries{T<:Real,V}
    ts::Vector{T}
    vs::Vector{V}
    function Entries(ts::Vector{T}, vs::Vector{V}) where {T,V}
        length(ts) != length(vs) && throw(ArgumentError("ts and xs must be same length."))
        return new{T,V}(ts, vs)
    end
end

Base.IteratorSize(::Type{<:Entries}) = Base.HasLength()
Base.eltype(::Type{<:Entries{T,V}}) where {T,V} = Pair{T,V}
Base.length(e::Entries) = length(e.ts)
Base.getindex(e::Entries, i::Integer) = e.ts[i] => e.vs[i]
function Base.iterate(e::Entries, state = 1)
    if state <= length(e)
        return e[state], state + 1
    else
        return nothing
    end
end

tspan(e::Entries) = e.ts[end] - e.ts[1]
vs(e::Entries) = e.vs
ts(e::Entries) = e.ts
toseries(e::Entries) = ts(e), vs(e)

"""
    getstate_bytime(e::Entries, t::Real, [indrange::Tuple=(1,length)])

Get the state(`v`) of `e` at time `t`, evenif `t` is not in `ts(e)`. If `indrange`
is specified, will only search in `ts(e)[indrange[1]:indrange[2]]`. The return value
is a tuple consists of its state and some information about next state which is useful
during iteration.


Examples
≡≡≡≡≡≡≡≡≡≡
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

julia> getstate_bytime(e, 1.0)
(1, (2, 6))

julia> state = (1, length(e))
(1, 6)

julia> for t in 0:0.5:6
           v, state = getstate_bytime(e, t, state)
           print(v, " ")
       end
0 0 1 1 2 2 3 3 4 4 5 5 5
```
"""
function getstate_bytime(
    e::Entries,
    t::Real,
    indrange::Tuple{Integer,Integer} = (1, length(e)),
)
    ts_e = ts(e)
    vs_e = vs(e)
    l, h = indrange
    l == 1 && ts_e[1] > t && return (false, indrange)
    for i = l:h
        ts_e[i] > t && return vs_e[i-1], (i - 1, h)
    end
    return vs_e[end], (vs_e[end], nothing)
end
getstate_bytime(::Entries, ::Real, v::Tuple{Any,Nothing}) = (v[1], v)

function Base.show(io::IO, ::MIME"text/plain", e::Entries)
    println(io, "Record Entries")
    print(io, "t: ")
    show(io, MIME("text/plain"), ts(e))
    print(io, "\nv: ")
    show(io, MIME("text/plain"), vs(e))
end
# vim:tw=92:ts=4:sw=4:et
