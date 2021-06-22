# This API is inspired ny `plot` API of DifferentialEquations.jl
# but they are not same or compatible for all vars
const RecEntry = Union{Record,AbstractEntry}

@recipe function f(r::RecEntry; vars=())
    seriestype --> :path
    return selectrecs(r, vars)
end

const T0 = Val(:t)
const T0_T = Val{:t}

const RA_INDEX = Union{Integer,Base.AbstractCartesianIndex}
const RA_TIME  = AbstractArray{<:Real}

"""
    selectrecs(r::Union{Record,AbstractEntry}, [vars])

Select and process values in `r`.
`vars` can be a Tuple `([f], [ts], [T0], [inds...])` and return a tuple of values:

* `f` is a function for process data at each time which should accpect n
  parameters where n is the number of index and return a tuple. If `f` is not
  given, data will not be processed.
* `ts` should be an iterator of real number, this function will get values at
  each `t` in `ts`.  If `ts` is not given, `ts` will be a vector contains each
  time given value changed.
* `T0` is a constant, if `T0` is given, this function will return `ts` as first
  element of returned tuple.
* `inds` are indices, like `(i1, i2, ..., in)`, only the values at given indices
  will be selected and processed. If `inds` is not given, all values will be
  selected and processed.

`vars` can also be unpacked, like `selectrecs(r, f, ts, T0, inds...)`.

# Example
```jldoctest
julia> c = DiscreteClock(10); # create a clock

julia> pos = DynamicRArray(c, [0, 0]); # create a rarray

julia> for t in c # do some changes
           if  t % 2 == 0
               pos[1] += 1
           else
               pos[2] -= 1
           end
       end

julia> r = record(pos); # create a record

julia> selectrecs(r) # select without vars will return all value
([0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5], [0, -1, -1, -2, -2, -3, -3, -4, -4, -5, -5])

julia> selectrecs(r, (T0, 1, 2)) # select with T0 and indices
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5], [0, -1, -1, -2, -2, -3, -3, -4, -4, -5, -5])

julia> selectrecs(r, (0:2:10, T0, 1, 2)) # select with ts and indices
(0:2:10, [0, 1, 2, 3, 4, 5], [0, -1, -2, -3, -4, -5])

julia> f(t, x, y) = t, x + y; # define a process function

julia> selectrecs(r, (f, T0, 1, 2)) # select with a function and indices
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0])
```
"""
function selectrecs end
# API
selectrecs(r::RecEntry, t::Tuple) = selectrecs(r, t...)

# without vars
# select without ts
function selectrecs(r::RecEntry, ::T0_T, is::Integer...)
    ts, vars = _selectrecs(r, is...)
    return ts, vars...
end
selectrecs(r::RecEntry, is::RA_INDEX...) = _selectrecs(r, is...)[2]
function _selectrecs(r::RecEntry, is::RA_INDEX...)
    es = _getindex_tuple(r, is...)
    ts = sort(union(map(getts, es)...))
    return ts, map(e -> gettime(e, ts), es)
end

# select with ts
selectrecs(r::RecEntry, ts::RA_TIME, ::T0_T, is::RA_INDEX...) = ts, _selectrecs(r, ts, is...)...
selectrecs(r::RecEntry, ts::RA_TIME, is::RA_INDEX...) = _selectrecs(r, ts, is...)
function _selectrecs(r::RecEntry, ts::RA_TIME, is::RA_INDEX...)
    es = _getindex_tuple(r, is...)
    return map(e -> gettime(e, ts), es)
end

# select with only one index
selectrecs(r::RecEntry, i1::Integer) = selectrecs(r, T0, i1)
selectrecs(r::RecEntry, ts::RA_TIME, i1::Integer) = selectrecs(r, ts, T0, i1)

# select with function
function selectrecs(r::RecEntry, f::Base.Callable, vars...)
    series = selectrecs(r, vars...)::Tuple
    vt = map(f, series...)
    return vt2tv(vt)
end

_getindex_tuple(r::Record) = (r...,)
_getindex_tuple(r::Record, is...) = map(i -> r[i], is)
_getindex_tuple(e::SingleEntry) = (e,)
_getindex_tuple(e::SingleEntry, ::Vararg{Integer,N}) where {N} = ntuple(i -> e, Val(N))
_getindex_tuple(u::UnionEntry) = u.es
_getindex_tuple(u::UnionEntry, is...) = map(i -> u.es[i], is)

# type stable convert vector of tuple to tuple to vector
@generated function vt2tv(vt)
    Ts = vt.parameters[1].parameters
    return quote
        tv = ($(map(T -> :(Vector{$T}(undef, length(vt))), Ts)...),)
        @simd for j in 1:length(vt)
            $((:(@inbounds tv[$i][j] = vt[j][$i]) for i in eachindex(Ts))...)
        end
        return tv
    end
end
