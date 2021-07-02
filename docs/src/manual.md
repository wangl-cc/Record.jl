# Manual

## Define a `Clock` 

To record changes of array automatically, the array must refer to a time
variable called `Clock`, and you must use a `Clock` storing your time variable. 
There are different types of `Clock`s: [`ContinuousClock`](@ref) for
continuous-time process and [`DiscreteClock`](@ref) for discrete.

Once you have defined a `Clock`, like:
```julia
c = ContinuousClock(10.0)
```
which create a `ContinuousClock` start at ``t=0`` and end at `t=10`.
Your can get the current time by [`currenttime`](@ref), and update the current time by
[`increase!`](@ref) (**you can't updated a `DiscreteClock` by `increase!`**).

`Clock`s also provide the iterator interfaces:
```julia
for epoch in c
    # do something which don't change state
    increase!(c, 1)
    # do something which change state
end
```
which is equivalent to
```julia
t = 0.0
epoch = 0
while t <= 10.0
    global epoch
    epoch += 1
    # do something
    t += 1
    # do something
end
```
Iterate a `Clock` by a `for` loop is recommended, and every operation on `Clock`
and `RArray` should be avoided. Besides, iteration is the only way to update
the current time of `DiscreteClock`. During the loop, some state of `Clock`
were updated automatically and if iteration finished when reach to end, `Clock`
will be initialized by [`init!`](@ref) automatically.

## Create, Use and Mutate `RecordedArray`s

Once a clock `c` is defined, you can create `RecordedArray`s with it, like:
```julia
dV = DynamicRArray(c, fill(10, 10))
rV = StaticRArray(c, rand(10))
```
There are two types of `RecordedArray`: [`DynamicRArray`](@ref), [`StaticRArray`](@ref).

Most operation of linear algebra and broadcasting on `RecordedArray` works the
same on normal `Array`. If there are any commonly used functions were not
implemented or any performance loss, leaving me an issue or create a pull
request on GitHub will be helpful.

However, there are too many functions to implement everyone. Warping your
`RecordedArray` with `state` or convert it `convert` are common solution:
like:
```julia
state(dV)
convert(Vector{eltype(dV)}, dV)
```
which will return a normal `Array`. Note, `state(dV)` don't allocate but may be
unsafe for matrix and higher dimension array because of `unsafe_wrap` and
`unsafe_convert`.

If you want to mutate `RecordedArray`s, they have the same API as `Array`.
You can change the value at given index by `dV[i]` (**only for `DynamicRArray`**)
or push or delete a value by `push!(dV, v)` or `deleteat!(dV, i)` respectively.

The implemented `RecordedArray` and API to mutate `RecordedArrays`:
* `DynamicRArray`
    * `DynamicRScalar`
        * `setindex!`
    * `DynamicRVector`
        * `setindex!`
        * `push!`
        * `insert!`
        * `deleteat!`
* `StaticRArray`
    * `StaticRVector`
        * `push!`
        * `insert!`
        * `deleteat!`


## Use `RecordedArrays` in a simulation

See [example](@ref Example).

## Accessing and Processing `Record`

It's recommended that accessing recorded data by create a `Record` by
[`record`](@ref):
```julia
r = record(dV)
```
The changing history of `dV` at given index `i` can be accessed by `r[i]`, or
by [`selectrecs(r, i)`](@ref selectrecs), where `r[i]` will return a `Entry`
and `selectrecs(r, i)` return a tuple of vector.
Besides the state of `dV` at given time `t` can be accessed by
[`gettime(r, t)`](@ref gettime).
More about `Record`, see reference.

## Plotting

Plotting is provided by recipes to `Plots.jl`. For a `Record` or a `Entry`,
calling `plot(r; vars)` will generate a plot, where `vars` will pass to
[`selectrecs`](@ref).

### Tips about plotting

Plotting changing values of each element of a `Record` `r` can simply call
`plot(r...; vars=T0)`.

Plotting the `r` without `vars` will generate only one path, thus if
`length(r) > 3` will cause a error due it's impossible to draw a plot
more than 3-D. If you want to draw the path of each element, call
`plot(r...; vars=T0)` instead of `plot(r)`. One input `r` will only generate one
path.