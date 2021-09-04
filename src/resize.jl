# Resize interfaces
# Vector
Base.sizehint!(A::AbstractRVector, sz::Integer) = sizehint!(_state(A), sz)
function Base.push!(A::AbstractRVector, v)
    push!(_state(A), v)
    push!(_record(A), v)
    return A
end
function Base.append!(A::AbstractRVector, vs)
    append!(_state(A), vs)
    append!(_state(A), vs)
    return A
end
function Base.insert!(A::AbstractRVector, i::Integer, v)
    insert!(_state(A), i, v)
    insert!(_record(A), i, v)
    return A
end
function Base.deleteat!(A::AbstractRVector, inds)
    deleteat!(_state(A), inds)
    deleteat!(_record(A), inds)
    return A
end
function Base.resize!(A::AbstractRVector, nl::Integer)
    resize!(_state(A), nl)
    resize!(_record(A), nl)
    return A
end

# Array
Base.sizehint!(A::AbstractRArray{V,R,N}, sz::Vararg{Integer,N}) where {V,R,N} =
    sizehint!(_state(A), prod(sz))

function Base.resize!(A::AbstractRArray{V,R,N}, nsz::Vararg{Integer,N}) where {V,R,N}
    all(>=(0), nsz) && throw(ArgumentError("each dims of new size must be ≥ 0"))
    sz = _size(A)
    sz == nsz && return A
    n = length(A)
    if all(map(>, sz, nsz))
        inds = axes(A)
        _resize!(sz, nsz)
        _growend!(A, prod(nsz)-n)
        copyto!(view(A, inds...), A[1:n]) # this copy is not fast
    elseif all(map(<, sz, nsz))
        inds = map(Base.OneTo, nsz)
        copyto!(A,  A[inds...])
        _resize!(sz, nsz)
        _deleteend!(A, n-prod(nsz))
    else
        throw(ArgumentError(
            "each dims of new size must be large or less than the old one"))
    end
    return A
end
function Base.resize!(A::AbstractRArray{V,R,N}, inds::Vararg{Any,N})where {V,R,N}
    @boundscheck checkbounds(A, inds...)
    nsz = map(_length, inds, size(A))
    _size(A) == nsz && return A
    copyto!(A, A[inds...])
    Base._deleteend!(_state(A), length(A)-prod(nsz))
    _resize!(_size(A), nsz)
    return A
end

_length(itr, ::Integer) = length(itr)
_length(::Colon, n::Integer) = n

function pushdim!(A::AbstractRArray, dim::Integer, n::Integer)
    # grow state and move element
    blk_len, vblk_num, batch_num = _blkinfo(A, dim)
    blk_num = vblk_num + n
    v = _state(A)
    blk_type = zeros(Bool, blk_num)
    blk_type[vblk_num+1:blk_num] .= true
    delta = blk_len * n * batch_num
    ind = length(v)
    Base._growend!(v, delta)
    _moveblkend!(v, ind, blk_len, blk_type, batch_num, delta)
    # change record dim
    pushdim!(_record(A), dim, n)
    return A
end
function deletedim!(A::AbstractRArray, dim::Integer, inds)
    # grow state and move element
    n = length(inds)
    blk_len, blk_num, batch_num = _blkinfo(A, dim)
    v = _state(A)
    blk_type = zeros(Bool, blk_num)
    @simd for ind in inds # if inds is a Integer, broadcast will raise a error
        blk_type[ind] = true
    end
    delta = blk_len * n * batch_num
    _moveblkbegin!(v, blk_len, blk_type, batch_num, delta)
    Base._deleteend!(v, delta)
    # change record dim
    deletedim!(_record(A), dim, inds)
    return A
end

# tools for array
function _moveblkbegin!(
    v::Vector,
    blk_len::Integer,
    blk_type::AbstractVector{Bool},
    batch_num::Integer,
    delta::Integer,
)
    blk_num = length(blk_type)
    ind = 1
    _delta = 0
    for i in 1:batch_num , j in 1:blk_num
        if @inbounds blk_type[j]
            _delta += blk_len
        else
            if _delta != 0 
                for k in ind:(ind+blk_len-1)
                    v[k] = v[k+_delta]
                end
            end
            ind += blk_len
        end
    end
    _delta != delta && error("given delta don't equal to the real delta")
    return v
end
function _moveblkend!(
    v::Vector,
    ind::Integer,
    blk_len::Integer,
    blk_type::AbstractVector{Bool},
    batch_num::Integer,
    delta::Integer
)
    blk_num = length(blk_type)
    for i in batch_num:-1:1, j in blk_num:-1:1
        if @inbounds blk_type[j]
            delta -= blk_len
            delta == 0 && break
        else
            for k in ind:-1:(ind-blk_len+1)
                v[k+delta] = v[k]
            end
            ind -= blk_len
        end
    end
    return v
end

function _blkinfo(A::AbstractArray, dim::Integer)
    dim > ndims(A) && throw(ArgumentError("dim must less than ndims(A)"))
    blk_len = 1
    sz = size(A)
    for i in 1:(dim-1)
        blk_len *= sz[i]
    end
    batch_num = 1
    for i in (dim+1):ndims(A)
        batch_num *= sz[i]
    end
    return blk_len, sz[dim], batch_num
end
