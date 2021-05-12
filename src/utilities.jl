"""
    State{T}

A box to store a variable of type `T` whose value can be update.


# Examples

```jldoctest
julia> x = State(0)
0

julia> value(x)::Int
0

julia> update!(x, 1)
1
```
"""
mutable struct State{T}
    x::T
end

function Base.show(io::IO, ::MIME"text/plain", x::State)
    return show(io, MIME("text/plain"), value(x))
end

"""
    value(x::State)

Get current value of State `x`.
"""
@inline value(x::State) = x.x

"""
    update!(x::State, new)

Update current value of State `x` to `new`.
"""
@inline update!(x::State{T}, new::T) where {T} = x.x = new
@inline update!(x::State{T}, new) where {T} = x.x = convert(T, new)

"""
    plus!(x::State, y)

Update current value of State `x` to `value(x) + y`.
"""
@inline plus!(x::State{T}, y::T) where {T} = x.x += y
@inline plus!(x::State{T}, y) where {T} = x.x += convert(T, y)
