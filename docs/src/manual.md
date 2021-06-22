# Manual

## Define a `Clock` 

To record changes of array automatically, the array must refer to a time
variable called `Clock`, and you must use a `Clock` storing your time variable. 
There are different types of `Clock`s: [`ContinuousClock`](@ref) for
continuous-time process and [`DiscreteClock`](@ref) for discrete.

Once you have defined a `Clock`, like:
```@expample manual
c = ContinuousClock(10.0);
```
which create a `ContinuousClock` start at ``t=0`` and end at `t=10`.
Your can get the current time by [`now`](@ref), and update the current time by
[`increase!`](@ref) (**you can't updated a `DiscreteClock` by `increase!`**).

`Clock`s also provide the iterator interfaces:
```@expample manual
for epoch in c
    # do something which don't change state
    increase!(c, 1)
    # do something which change state
end
```
which is equivalent to
```@example equivalent
t = 0.0
epoch = 0
while t <= 10.0
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

## Create and Mutate `RecordedArray`s

TODO

## Get and Processing records

TODO