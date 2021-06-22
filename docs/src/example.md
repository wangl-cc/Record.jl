# Example

## Gaussian random walk

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
plot(record(pos); frame=:none, grid=false, legend=false)
```

## Logistic growth

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

plot(record(n)...; frame=:box, grid=false, legend=false) # plot population dynamics
```
