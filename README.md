# RecordedArray.jl

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArray.jl/branch/master/graph/badge.svg?token=PB3THCTNJ9)](https://codecov.io/gh/wangl-cc/RecordedArray.jl)

A Pkg for reocrd changes automatically.

## Example

```julia
julia> using RecordedArray

julia> c = Clock(1)
Clock{Float64}(0.0, 1.0)

julia> v = DynamicRArray(c, [0, 1])
recorded 2-element Vector{Int64}:
 0
 1

julia> increase!(c, 1)
1.0

julia> v[1] += 1
1

julia> v
recorded 2-element Vector{Int64}:
 1
 1

julia> r = getrecord(v, 1)
RecordedArray.RecordView{Int64, Float64}([0.0, 1.0], [0, 1])

julia> ts(r)
2-element Vector{Float64}:
 0.0
 1.0

julia> vs(r)
2-element Vector{Int64}:
 0
 1
```
