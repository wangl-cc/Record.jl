import Base:iterate, IteratorSize, eltype, length, size, show

using Base: HasShape, HasLength

struct Records{V, T, N, AT<:AbstractRArray}
    array::AT
end
records(A::AbstractRArray{V, T, N}) where {V, T, N} =
    Records{V, T, N, typeof(A)}(A)

IteratorSize(::Type{<:Records}) = HasShape()
eltype(::Type{<:Records{V, T}}) where {V, T} = RecordView{V, T}
length(r::Records) = length(r.array)
size(r::Records) = size(r.array)
function iterate(r::Records, state = 1)
    if state <= length(r)
        return getrecord(r.array, state)::RecordView, state + 1
    else
        return nothing
    end
end

"""
    RecordView{V,T}
"""
struct RecordView{V,T<:Real}
    vs::Vector{V}
    ts::Vector{T}
    function RecordView(ts::Vector, vs::Vector)
        length(ts) != length(vs) && throw(
            ArgumentError("ts and xs must be same length.")
        )
        return new{eltype(vs), eltype(ts)}(vs, ts)
    end
end

IteratorSize(::Type{<:RecordView}) = HasLength()
eltype(::Type{<:RecordView{V,T}}) where {V,T} = Tuple{T, V}
length(v::RecordView) = length(v.ts)
function iterate(v::RecordView, state = 1)
    if state <= length(v)
        return (v.ts[state], v.vs[state]), state + 1
    else
        return nothing
    end
end

tspan(v::RecordView) = v.ts[end] - v.ts[1]
vs(v::RecordView) = v.vs
ts(v::RecordView) = v.ts
toplot(v::RecordView) = ts(v), vs(v)

function show(io::IO, ::MIME"text/plain", v::RecordView)
    println(io, "t", "\tv")
    for (t, x) in v
        println(io, t, "\t", x)
    end
end
