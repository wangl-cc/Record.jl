# Introduction

During running a simulation, one of the most important but annoying part is
recording and processing the changing values of state.
This package provides "recorded" types,
changes of which will be recorded automatically.

## Installation

This is a registered package, it can be installed with the `add` command in
the Pkg REPL:
```julia
pkg> add RecordedArrays
```

## Quick Start

```@repl
using RecordedArrays # load this package
c = ContinuousClock(3); # define a clock
v = recorded(DynamicEntry, c, [0, 1]) # create a recorded array with the clock
v + v # math operations work as normal array
v .* v # broadcast works as normal array as well
increase!(c, 1) # when time goes and array changes, increase the define clock firstly
v[1] += 1 # change array's element
increase!(c, 1) # when time goes and array changes, increase the define clock firstly
push!(v, 1) # push a new element
es = getentries(v) # view recorded changes
es[1] # the changes of the first element of `v`, which changed to 1 at `t=1`
gettime(es[1], 0:2) # get the value of the first element at time 0, 1 and 2
es[3] # the changes of the third element of `v`, which was pushed at `t=2`
gettime(es[3], 0:2) # get the value of the first element at time 0, 1 and 2
```
