# Introduction

A Pkg for record changes of array (and scalar) automatically.

## Basic Usage

```jldoctest
julia> using RecordedArrays

julia> c = ContinuousClock(3.0); # define a clock

julia> v = DynamicRArray(c, [0, 1]) # create a recorded array with the clock
recorded 2-element Vector{Int64}:
 0
 1

julia> v + v # do math operations as normal array
2-element Vector{Int64}:
 0
 2

julia> increase!(c, 1) # when time goes and array changes, increase the define clock firstly
1.0

julia> v[1] += 1 # change array's element
1

julia> push!(v, 1) # push a new element
recorded 3-element Vector{Int64}:
 1
 1
 1

julia> r = record(v) # view recorded changes by creating a record
record for 3-element dynamic Vector{Int64} with time Float64

julia> r[1] # show entries of the first element of v
Record Entry
t: 2-element Vector{Float64}:
 0.0
 1.0
v: 2-element Vector{Int64}:
 0
 1

julia> Dict(r[1]) # or view it as a dict
Dict{Float64, Int64} with 2 entries:
  0.0 => 0
  1.0 => 1

julia> toseries(r[1]) # to the form accepted by plot
([0.0, 1.0], [0, 1])
```

## Example

### Gaussian random walk

This is a simple implementation to simulate a 2-D
[Gaussian random walk](https://en.wikipedia.org/wiki/Random_walk).

```@example random_walk
using RecordedArrays
using Plots
using Random

Random.seed!(1)

c = DiscreteClock(10000) # define a clock, the particle will walk 10000 epoch
pos = DynamicRArray(c, [0.0, 0.0]) # create a pos vector of the particle

for t in c
    pos .+= randn(2) # walk randomly at each epoch
end

# plot path of particle
plot(record(pos); vars=(1,2), frame=:none, grid=false, legend=false)
```

### Logistic growth

This is a simple implementation of [Gillespie algorithm](https://en.wikipedia.org/wiki/Gillespie_algorithm)
with direct method to simulate a
[Logistic growth population](https://en.wikipedia.org/wiki/Logistic_function#In_ecology:_modeling_population_growth)
with growth rate $r=0.5$ and carrying capacity $K=100$.

```@example logistic
using RecordedArrays
using Plots
using Random

Random.seed!(1)

c = ContinuousClock(100.0) # define a clock, the population will growth for 100 time unit
n = DynamicRArray(c, 10)   # define a scalar to record population size

const r = 0.5
const K = 100

for _ in c
    # eval a_i
    grow = r * n         # intrinsic growth
    comp = r * n * n / K # resource competition

    sumed = grow + comp  # sum a_i

    τ = -log(rand()) / sumed # compute time intervel

    increase!(c, τ) # update current time

    # sample a reation and adjust population size
    if rand() * sumed < grow
        n[1] += 1
    else
        n[1] -= 1
    end

    state(n) <= 0 && break # break if population extinct
end

plot(record(n); frame=:box, grid=false, legend=false) # plot population dynamics
```

