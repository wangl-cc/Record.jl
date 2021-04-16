# Introduction

A Pkg for record changes of array (and scalar) automatically.

[![Build Status](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArray.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArray.jl/branch/master/graph/badge.svg?token=PB3THCTNJ9)](https://codecov.io/gh/wangl-cc/RecordedArray.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/RecordedArray.jl)](https://github.com/wangl-cc/RecordedArray.jl/blob/master/LICENSE)

## Usage

```jldoctest
julia> using RecordedArray

julia> c = ContinuousClock(3.0); # define a clock

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

julia> v[1] += 1 # change array's element
1

julia> push!(v, 1) # change array size
recorded 3-element Vector{Int64}:
 1
 1
 1

julia> r = records(v) # create a records
records for recorded 3-element Vector{Int64}:
 1
 1
 1

julia> r[1] # show entries of a element
Record Entries
t: 2-element Vector{Float64}:
 0.0
 1.0
v: 2-element Vector{Int64}:
 0
 1
```

## Example

### [Gaussian random walk](https://en.wikipedia.org/wiki/Random_walk) in two dimensions

WIP


<!-- vim: set ts=2 sw=2 spell spl=en: -->
