@recipe function f(r::Union{Records, AbstractEntries}; vars=nothing)
    seriestype --> :path
    return _toplot(r, vars)
end


_toplot(r::Records, ::Nothing) = ts.(r), vs.(r)
_toplot(r::Records, T::Tuple) = _toplot(r, T...)
function _toplot(r::Records, v1::Integer, vs::Integer...)
    any(==(0), vs) && throw(ArgumentError("0 must be the first variable"))
    if v1 == 0
        inds = collect(vs)
        ue = unione(r[inds])
        ts_e = ts(ue)
        return ts_e, (gettime(e, ts_e) for e in ue.es)...
    else
        inds = [v1, vs...]
        ue = unione(r[inds])
        ts_e = ts(ue)
        return Tuple(gettime(e, ts_e) for e in ue.es)
    end
end
function _toplot(r::Records, f, vs::Integer...)
    series = _toplot(r, vs...)::Tuple
    at = f.(series...)
    return Tuple(getindex.(at, i) for i in 1:length(at[1]))
end
