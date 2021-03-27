import Base:iterate, IteratorSize, eltype, length, size

using Base: HasShape

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
struct RecordView{V,T}
    ts::Vector{T}
    vs::Vector{V}
end

tspan(v::RecordView) = v.ts[end] - v.ts[1]
vs(v::RecordView) = v.vs
ts(v::RecordView) = v.ts
toplot(v::RecordView) = ts(v), vs(v)
