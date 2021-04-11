# RecordedArray.jl

A Pkg for reocrd changes of array (and scalar) automatically.

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![Build Status](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArray.jl/branch/master/graph/badge.svg?token=PB3THCTNJ9)](https://codecov.io/gh/wangl-cc/RecordedArray.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/RecordedArray.jl)](https://github.com/wangl-cc/RecordedArray.jl/blob/master/LICENSE)

A Pkg for record changes of array (and scalar) automatically.

## Usage

```jldoctest
julia> using RecordedArray

julia> c = Clock(1) # define a clock
Clock{Float64}(0.0, 1.0)

julia> v = DynamicRArray(c, [0, 1]) # init an array with clock
recorded 2-element Vector{Int64}:
 0
 1

julia> v + v # math operators works as normal
2-element Vector{Int64}:
 0
 2

julia> increase!(c, 1) # when time goes, increase the define clock
1.0

julia> v[1] += 1 # change array's element as normal
1

julia> v
recorded 2-element Vector{Int64}:
 1
 1

julia> getrecord(v, 1) # all changes are recorded automatically
t	v
0.0	0
1.0	1
```

## Example

WIP
