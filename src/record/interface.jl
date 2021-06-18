# recipe for AbstractEntry is not implemented
@recipe function f(r::Union{Record, AbstractEntry}; vars=nothing)
    seriestype --> :path
    return selectvars(r, vars)
end

"""
    selectvars(r::Record, [vars])

Select and process values in `r`.
`var` can be:
* empty or `nothing`: return a vector of tuple each tuple containts `ts` and `vs`,
  works as `map(e -> (getts(e), getvs(e)), r)`.
* a tuple of `Integer` index, like `(i1, i2, ..., in)`: return a tuple of values of
  given index, besides the index `0` means time and should be the first index.
* a tuple like `(f, i1, i2, ..., in)` where `f` is a function accpect n parameters
  and return a tuple: return a tuple of vector processed by `f`, see example.
* a function `f` which accpect `length(r)+1` parameters and return tuple:
  return a tuple of vector process by `f`, see example.
* a vector whose element can each of above type: return a vector of the return of
  given type.

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

julia> selectvars(r) # select without vars
2-element Vector{Tuple{Vector{Int64}, Vector{Int64}}}:
 ([0, 2, 4, 6, 8, 10], [0, 1, 2, 3, 4, 5])
 ([0, 1, 3, 5, 7, 9], [0, -1, -2, -3, -4, -5])

julia> selectvars(r, (0, 1, 2)) # select with a tuple of indices
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5], [0, -1, -1, -2, -2, -3, -3, -4, -4, -5, -5])

julia> f(t, x, y) = t, x + y; # define a process function

julia> selectvars(r, (f, 0, 1, 2)) # select with a function and indices
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0])

julia> selectvars(r, f) # select with a function
([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0])

julia> selectvars(r, [(1, 2), f]) # select with a vector
2-element Vector{Tuple{Vector{Int64}, Vector{Int64}}}:
 ([0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5], [0, -1, -1, -2, -2, -3, -3, -4, -4, -5, -5])
 ([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, -1, 0, -1, 0, -1, 0, -1, 0, -1, 0])
```
"""
function selectvars end
selectvars(r::Record) = vec(map(toseries, r))
selectvars(r::Record, ::Nothing) = selectvars(r)
selectvars(r::Record, V::Vector) = map(vs -> selectvars(r, vs), V)
selectvars(r::Record, t::Tuple) = selectvars(r, t...)
function selectvars(r::Record, v1::Integer, vs::Vararg{Integer, N}) where {N}
    any(==(0), vs) && throw(ArgumentError("0 must be the first variable"))
    if v1 == 0
        return _selectvars_0(r, vs)
    else
        return _selectvars_1(r, v1, vs)
    end
end

function selectvars(r::Record, f, v1::Integer, vs::Vararg{Integer,N}) where {N}
    any(==(0), vs) && throw(ArgumentError("0 must be the first variable"))
    if v1 == 0 # vars name with true for better type inference
        series0 = _selectvars_0(r, vs)::Tuple
        vt0 = map(f, series0...)
        return vt2tv(vt0)
    else
        series1 = _selectvars_1(r, v1, vs)::Tuple
        vt1 = map(f, series1...)
        return vt2tv(vt1)
    end
end

function selectvars(r::Record, f)
    ue = unione(r)
    ts = getts(ue)
    series = (ts, map(e -> gettime(e, ts), ue.es)...)
    vt = map(f, series...)
    return vt2tv(vt)
end

function _selectvars_0(r::Record, vs::NTuple{N,Integer}) where {N}
    es = _getindex_tuple(r, vs...)
    ts = sort(union(map(getts, es)...))
    return ts, map(e -> gettime(e, ts), es)...
end
function _selectvars_1(r::Record, v1::Integer, vs::NTuple{N,Integer}) where {N}
    es = _getindex_tuple(r, v1, vs...)
    ts = sort(union(map(getts, es)...))
    return map(e -> gettime(e, ts), es)
end

_getindex_tuple(r::Record, i1) = (r[i1],)
_getindex_tuple(r::Record, i1, i2) = r[i1], r[i2]
_getindex_tuple(r::Record, i1, i2, i3) = r[i1], r[i2], r[i3]
_getindex_tuple(r::Record, i1, i2, is...) = r[i1], r[i2], _getindex_tuple(r, is...)...

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
