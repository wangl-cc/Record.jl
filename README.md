# RecordedArray.jl

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArray.jl/branch/master/graph/badge.svg?token=PB3THCTNJ9)](https://codecov.io/gh/wangl-cc/RecordedArray.jl)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/RecordedArray.jl/dev)

A Pkg for reocrd changes of array (and scalar) automatically.

## Example

```julia
julia> using RecordedArray

julia> c = Clock(1)
Clock{Float64}(0.0, 1.0)

julia> v = DynamicRArray(c, [0, 1])
recorded 2-element Vector{Int64}:
 0
 1

julia> v + v
2-element Vector{Int64}:
 0
 2

julia> increase!(c, 1)
1.0

julia> v[1] += 1
1

julia> v
recorded 2-element Vector{Int64}:
 1
 1

julia> getrecord(v, 1)
t	v
0.0	0
1.0	1
```
