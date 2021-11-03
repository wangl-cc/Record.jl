# Manual

## Define a `Clock`

To record changes of recorded variables automatically,
those variables must refer to the time variable of model,
in this package which called as a "Clock".

There are different types of clocks:
- [`ContinuousClock`](@ref) for continuous-time process,
- and [`DiscreteClock`](@ref) for discrete-time process.

A clock can be created like:
```julia
c = ContinuousClock(10.0)
```
which create a `ContinuousClock` start at `t=0` and end at `t=10`.

The current time of clock is accessed by [`currenttime`](@ref).
Obviously, the current time of clock will change at each epoch.
For `DiscreteClock`, the time will update automatically during iteration,
more about iteration, see below.
For `ContinuousClock`, the time must be update manually by [`increase!`](@ref).

Clocks can be iterated, for example, iterating a `ContinuousClock`:
```julia
for epoch in c
    # do something calculating the time step τ
    increase!(c, τ)
    # do something mutating states
end
```
which is equivalent to
```julia
t = 0.0
epoch = 0
while t <= 10.0
    global epoch
    epoch += 1
    # do something calculating the time step τ
    t += τ
    # do something mutating states
end
```

Iterate clocks by `for` loop is recommended,
and any operations on recorded variable should be avoided out of loop.
During the iteration, some states of `Clock` were updated automatically,
and if iteration finished when reach to end,
`Clock` will be initialized by [`init!`](@ref) automatically.
Besides, iteration is the only way to update the current time of `DiscreteClock`.


## Entry type

In this package, an entry stores changes of a single variable, a number or an element of an array.
There are two types of entries:

- [`DynamicEntry`](@ref) for variable which represents a "state" changing overtime,
- [`StaticEntry`](@ref) for variable which represents a "trait"
    which not changes overtime and only assigned once,
    but may be added or deleted with "mutation" and "extinction".

The different entry types determine how the variable is recorded,
and how the changes is accessed.

For example, a "dynamic" variable $d$ firstly assigned to $1$ at time $t_1$
and changed to $2$ at time $t_2$,
thus the value of it is $0$ for $t < t_1$,
$1$ for $t_1 \leq t < t_2$, and $2$ for $t_2 \leq t$.

But, for a "static" variable $s$ added with value $1$ at time $t_1$
and deleted at time $t_2$,
the value of it is $1$ for $t_1 \leq t \leq t_2$,
and $0$ for $t \leq t_1$ or $t_2 \leq t$.

## Recorded variable

With a clock `c` and an entry type `E`
recorded variables can be created by [`recorded`](@ref):
```julia
recorded(E, c, 1) # create a recorded number
recorded(E, c, [1, 2, 3]) # create a recorded array
```

For recorded arrays, most operation and functions for array,
like linear algebra operation and broadcasting, works the same as normal `Array`.
Besides, with the support of my another package
[`ResizingTools`](https://github.com/wangl-cc/ResizingTools.jl),
recorded arrays can be resized by `resize!` at each dimensions.
See its documentation for more details.

For recorded numbers, most operation for number works the same as normal `Number` as well.
Besides, because a recorded number type is not a subtype of the specific number type,
for example, `typeof(recorded(E, c, 1))` is not a subtype of `Int`,
there are two function to test type of recorded number:

- [`issubtype`](@ref): test if a recorded number type is a subtype of given normal number type,
- [`isnum`](@ref): test if a recorded number type is the given type number type.

For example, for a record number `n = recorded(E, c, 1)`
`isnum(Integer, n)` and `issubtype(Integer, typeof(n))` return `true`,
and `isnum(AbstractFloat, n)` and `issubtype(AbstractFloat, typeof(n))` return `false`.

If there are any commonly used functions were not implemented or
there are any performance loss comparing to the normal number and array,
leave me an issue or create a pull request on GitHub.

However, for custom functions. Warping recorded variables with [`state`](@ref)
or convert it to a normal type by `convert` are common solution:
like:
```julia
state(recorded(E, c, 1)) # warp a recorded number to a state
convert(Array, recorded(E, c, [1, 2, 3])) # convert a recorded array to an array
```
!!! note
    `state` don't allocate but may be unsafe for matrix and higher dimension array
    because of `Base.unsafe_wrap` and `Base.unsafe_convert`.
    I'm not sure if it would cause any problem or not.
    If anybody know more about it, please leave me an issue.

## Accessing changes

As shown above, the changes of recorded variables are stored in entries.
To access the changes, use [`getentries`](@ref) to get the entries:
```julia
e = getentries(n) # get the entry of a recorded number n
es = getentries(A) # get entries of a recorded array A
```

There are some methods to access the changes stored in entries:

- [`getts`](@ref) to get the time of each change,
- [`getvs`](@ref) to get the value of each change,
- [`tspan`](@ref) to get the time span of the entry,
- [`gettime`](@ref) to get the value at given time(s).

## Plotting

There is a two user recipes for `Plots.jl`:

- `timeseries` plots time series of given recorded variables,
- `phaseportrait` plots phase portrait of given recorded variables.

Both of them accept arguments with there types:

- a recorded variable, like `timeseries(v)` where `v` is a recorded variable;
- a collection of entries, like `timeseries(es)`, where `es` is a collection of entries;
- multiple entries, like `timeseries(e1, e2)`, where `e1` and `e2` are entries.

See example for more information.
