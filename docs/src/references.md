# Reference

## Clock

To record changes of array automatically, the array must refer to a time
variable, which defined as a clock. There are different types of clock for
continuous or discrete time. A clock can be iterate by `for` loop and break
when reach to stop.

```@docs
RecordedArray.AbstractClock
```

```@docs
DiscreteClock
```

```@docs
ContinuousClock
```

```@docs
now
```

```@docs
limit
```

```@docs
init!
```

```@docs
increase!
```

## RArray

Create a RArray with a clock and a array, then all changes will be recorded
automatically.

```@docs
RecordedArray.AbstractRArray
```

```@docs
state
```

```@docs
RecordedArray.StaticRArray
```

```@docs
RecordedArray.DynamicRArray
```

## Records

View recorded changes with `records`.
```@docs
records
```

```@docs
RecordedArray.Records
```

```@docs
RecordedArray.AbstractEntries
```

```@docs
RecordedArray.SingleEntries
```

```@docs
RecordedArray.UnionEntries
```

```@docs
gettime
```

```@docs
unione
```
