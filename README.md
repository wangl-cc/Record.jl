# RecordedArrays.jl

[![Build Status](https://github.com/wangl-cc/RecordedArrays.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArrays.jl/actions/workflows/ci.yml)
[![pkgeval](https://juliahub.com/docs/RecordedArrays/pkgeval.svg)](https://juliahub.com/ui/Packages/RecordedArrays/TOzPf)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/wangl-cc/RecordedArrays.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/RecordedArrays.jl)](https://github.com/wangl-cc/RecordedArrays.jl/blob/master/LICENSE)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wangl-cc.github.io/RecordedArrays.jl/stable)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/RecordedArrays.jl/dev)

During running a simulation, one of the most important but annoying part is
recording and processing the changing values of state.
This package provides "recorded" types,
changes of which will be recorded automatically.

**Note:** This are huge changes between `v0.3` and `v0.4`.
You can not load and process data of `v0.3` with `v0.4`.

## Installation

This is a registered package, it can be installed with the `add` command in
the Pkg REPL:
```
pkg> add RecordedArrays
```

## Quick Start

```julia
julia> using RecordedArrays # load this package

julia> c = ContinuousClock(3); # define a clock

julia> v = recorded(DynamicEntry, c, [0, 1]) # create a recorded array with the clock
2-element recorded(::Vector{Int64}):
 0
 1

julia> v + v # math operations work as normal array
2-element Vector{Int64}:
 0
 2

julia> v .* v # broadcast works as normal array as well
2-element Vector{Int64}:
 0
 1

julia> increase!(c, 1) # when time goes and array changes, increase the define clock firstly
1

julia> v[1] += 1 # change array's element
1

julia> increase!(c, 1) # when time goes and array changes, increase the define clock firstly
2

julia> push!(v, 1) # push a new element
3-element recorded(::Vector{Int64}):
 1
 1
 1

julia> es = getentries(v) # view recorded changes
3-element Vector{DynamicEntry{Int64, Int64}}:
 DynamicEntry{Int64, Int64}([0, 1], [0, 1])
 DynamicEntry{Int64, Int64}([1], [0])
 DynamicEntry{Int64, Int64}([1], [2])

julia> es[1] # the changes of the first element of `v`, which changed to 1 at `t=1`
DynamicEntry{Int64, Int64} with timestamps:
 0
 1

julia> gettime(es[1], 0:2) # get the value of the first element at time 0, 1 and 2
3-element Vector{Int64}:
 0
 1
 1

julia> es[3] # the changes of the third element of `v`, which was pushed at `t=2`
DynamicEntry{Int64, Int64} with timestamps:
 2

julia> gettime(es[3], 0:2) # get the value of the first element at time 0, 1 and 2
3-element Vector{Int64}:
 0
 0
 1
```
