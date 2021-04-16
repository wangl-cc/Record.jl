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

Base.IteratorSize(::Type{<:Records}) = Base.HasShape()
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
toplot(e::Entries) = ts(e), vs(e)

function Base.show(io::IO, ::MIME"text/plain", e::Entries)
    println(io, "Record Entries")
    print(io, "t: ")
    show(io, MIME("text/plain"), ts(e))
    print(io, "\nv: ")
    show(io, MIME("text/plain"), vs(e))
end
# vim:tw=92:ts=4:sw=4:et
