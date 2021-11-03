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
pos = recorded(DynamicEntry, c, [0.0, 0.0]) # create a position vector of the particle

for _ in c
    pos .+= randn(2) # walk randomly at each epoch
end

# plot path of particle
phaseportrait(pos; frame=:none, grid=false, legend=false)
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
n = recorded(DynamicEntry, c, 10)   # define a scalar to record population size

const r = 0.5
const K = 100

for _ in c
    # evaluate a_i
    grow = r * n         # intrinsic growth
    comp = r * n * n / K # resource competition

    summed = grow + comp  # sum a_i

    τ = -log(rand()) / summed # compute time interval

    increase!(c, τ) # update current time

    # sample a reaction and adjust population size
    if rand() * summed < grow
        n[1] += 1
    else
        n[1] -= 1
    end

    state(n) <= 0 && break # break if population extinct
end

# plot population dynamics
timeseries(n; frame=:box, grid=false, legend=false)
```

## Stochastic Predator–prey Dynamics

This is a simple implementation of [Gillespie algorithm](https://en.wikipedia.org/wiki/Gillespie_algorithm)
with direct method to simulate a
[Predator–prey Dynamics](https://en.wikipedia.org/wiki/Lotka–Volterra_equations).

```@example predator_prey
using RecordedArrays
using Plots
using Random

Random.seed!(1)

c = ContinuousClock(100.0) # define a clock, the population will growth for 100 time unit
n = recorded(DynamicEntry, c, [100, 100])  # define a vector to record population size (n[1] for prey, n[2] for predator)

const α = 0.5
const β = 0.001
const δ = 0.001
const γ = 0.5

for _ in c
    n[2] == 0 && break

    # evaluate a_i
    grow = α * n[1] # intrinsic growth of prey
    predation_prey = β * n[1] * n[2] # predation cause death of prey
    predation_pred = δ * n[1] * n[2] # predation cause reproduction of predator
    death = γ * n[2] # intrinsic death of prey

    summed = grow + predation_prey + predation_pred + death

    summed <= 0 && break

    τ = -log(rand()) / summed # compute time interval

    increase!(c, τ) # update current time

    # sample a reaction and adjust population size
    r1 = rand() * summed

    if (r1 -= grow; r1 < 0)
        n[1] += 1
    elseif (r1 -= predation_prey; r1 < 0)
        n[1] -= 1
    elseif (r1 -= predation_pred; r1 < 0)
        n[2] += 1
    else
        n[2] -= 1
    end
end

ts = timeseries(n; frame=:box, grid=false, legend=false)
pp = phaseportrait(n; frame=:box, grid=false, legend=false)
plot(ts, pp; titles=["Population dynamics" "Phase portrait"], size=(800, 400))
```

More examples is hard to implement simply.
