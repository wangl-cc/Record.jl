# Introduction

A Pkg for record changes of array (and scalar) automatically.

## Usage

```jldoctest
julia> using RecordedArrays

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

julia> Dict(r[1]) # view as a dict
Dict{Float64, Int64} with 2 entries:
  0.0 => 0
  1.0 => 1
```

## Example

### [Gaussian random walk](https://en.wikipedia.org/wiki/Random_walk) in two dimensions

```@example random_walk
using RecordedArrays
using Plots

c = DiscreteClock(10000)
pos = DynamicRArray(c, [0.0, 0.0])

for t in c
    pos .+= randn(2)
end

r = records(pos)
random_walk_plt = plot(vs.(r)...; frame=:none, grid=false, legend=false)
```

### [Birth–death process](https://en.wikipedia.org/wiki/Birth–death_process) by [Gillespie algorithm](https://en.wikipedia.org/wiki/Gillespie_algorithm)

```@example birth_death
using RecordedArrays
using Plots

c = ContinuousClock(100.0)
n = DynamicRArray(c, 10)

for _ in c
    birth = 0.1 * n
    death = 0.1 * n

    sumed = birth + death
    τ = -log(rand()) / sumed

    increase!(c, τ)

    if rand() * sumed > birth
        n[1] += 1
    else
        n[1] -= 1
    end
    state(n) <= 0 && break
end

r = records(n)
birth_death_plot = plot(toseries(r[1]); frame=:box, grid=false, legend=false)
```
