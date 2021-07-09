# RecordedArrays.jl

[![Build Status](https://github.com/wangl-cc/RecordedArrays.jl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/wangl-cc/RecordedArrays.jl/actions/workflows/ci.yml)
[![pkgeval](https://juliahub.com/docs/RecordedArrays/pkgeval.svg)](https://juliahub.com/ui/Packages/RecordedArrays/TOzPf)
[![codecov](https://codecov.io/gh/wangl-cc/RecordedArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/wangl-cc/RecordedArrays.jl)
[![GitHub](https://img.shields.io/github/license/wangl-cc/RecordedArrays.jl)](https://github.com/wangl-cc/RecordedArrays.jl/blob/master/LICENSE)
[![Docs stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://wangl-cc.github.io/RecordedArrays.jl/stable)
[![Docs dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://wangl-cc.github.io/RecordedArrays.jl/dev)

During running a simulation, one of the most important but annoying part is
recording and processing the changing values of state. This package provides
`RecordedArray` types. Convert arrays to `RecordedArray`s, then all changes will
be recorded automatically. Besides, this package provide some tools to access
and process recorded data.

## Installation

This is a registered package, so it can be installed with the `add` command in
the Pkg REPL:
```
pkg> add RecordedArrays
```

## Quick Start

```julia
julia> using RecordedArrays # load this package

julia> c = ContinuousClock(3.0); # define a clock

julia> v = DynamicRArray(c, [0, 1]) # create a recorded array with the clock
2-element DynamicRVector{Int64, Float64, ContinuousClock{Float64, Nothing}}:
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
1.0

julia> v[1] += 1 # change array's element
1

julia> push!(v, 1) # push a new element
3-element DynamicRVector{Int64, Float64, ContinuousClock{Float64, Nothing}}:
 1
 1
 1

julia> r = record(v) # view recorded changes by creating a record
record for 3-element DynamicRVector{Int64, Float64, ContinuousClock{Float64, Nothing}}

julia> r[1] # show entries of the first element of v, which changed to 1 at `t=1.0`
Record Entry
t: 2-element Vector{Float64}:
 0.0
 1.0
v: 2-element Vector{Int64}:
 0
 1

julia> r[3] # show entries of the third element of v, which was pushed at `t=1.0`
Record Entry
t: 1-element Vector{Float64}:
 1.0
v: 1-element Vector{Int64}:
 1

julia> selectrecs(r, T0) do t, v... # calculate the sum of v at each timestamp
           t, sum(v)
       end
([0.0, 1.0], [1, 3])
```

More about this package, see [docs](https://wangl-cc.github.io/RecordedArrays.jl/stable).

<!-- vim: set ts=2:sw=2:spell:spl=en -->
