# References

## Clock

To record changes of array automatically, the array must refer to a time
variable, which defined as a clock. There are different types of clock for
continuous time `ContinuousClock` or discrete time `DiscreteClock`.

```@docs
RecordedArrays.AbstractClock
DiscreteClock
ContinuousClock
now
limit
init!
increase!
```

## Recorded Arrays

Create a recorded array with a clock and a array, then all changes will be recorded
automatically. There are two types of recorded array: `StaticRArray` for array whose
values of elements never change but new element will be pushed, `DynamicRArray` for
array whose values of elements will change.

```@docs
RecordedArrays.AbstractRArray
state
RecordedArrays.StaticRArray
RecordedArrays.DynamicRArray
setclock
```

## View Records

You can't access the recorded entries of your recorded array `A` directly but you can
access it by create a `Records` with `r = records(A)` and get entries by `r[i]`.

```@docs
records
RecordedArrays.Records
RecordedArrays.AbstractEntries
RecordedArrays.SingleEntries
RecordedArrays.UnionEntries
gettime
unione
ts
vs
tspan
```

```@docs
toseries
```
