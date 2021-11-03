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

## Entries

```@docs
RecordedArrays.AbstractEntry
StaticEntry
DynamicEntry
getts
getvs
tspan
gettime
RecordedArrays.store!
RecordedArrays.del!
```

## Recorded Types

```@docs
RecordedArrays.AbstractRecArray
RecordedArrays.RArray
RecordedArrays.RecordedNumber
recorded
state
getentries
issubtype
isnum
```

## Utilities

```@docs
RecordedArrays.MCIndices
RecordedArrays.DOKSparseArray
```
