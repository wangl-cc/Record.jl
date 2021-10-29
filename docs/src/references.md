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
RecordedArrays.AbstractRecArray
RecordedArrays.StaticRArray
RecordedArrays.DynamicRArray
state
setclock
```

## View AbstractRecord

```@docs
RecordedArrays.AbstractRecord
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
