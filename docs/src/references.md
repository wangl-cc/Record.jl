# References

## Clock

```@docs
RecordedArrays.AbstractClock
DiscreteClock
ContinuousClock
currenttime
limit
start
init!
increase!
```

## Recorded Arrays

```@docs
RecordedArrays.AbstractRArray
RecordedArrays.StaticRArray
RecordedArrays.DynamicRArray
state
setclock
```

## View Record

```@docs
RecordedArrays.Record
record
RecordedArrays.AbstractEntry
RecordedArrays.SingleEntry
RecordedArrays.UnionEntry
gettime
unione
getts
getvs
toseries
tspan
selectrecs
```
