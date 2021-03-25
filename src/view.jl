"""
    RecordView{V,T}
"""
abstract type RecordView{V,T} end

toplot(r::RecordView) = ts(r), vs(r)

struct DynamicView{V,T} <: RecordView{V,T}
    ts::Vector{T}
    vs::Vector{V}
end
tspan(v::DynamicView) = v.ts[end] - v.ts[1]
vs(v::DynamicView) = v.vs
ts(v::DynamicView) = v.ts

struct StaticView{V,T} <: RecordView{V,T}
    v::V
    s::T
    e::T
end
tspan(v::StaticView) = v.e - v.s
vs(v::StaticView) = [v.v, v.v]
ts(v::StaticView) = [v.s, v.e]

