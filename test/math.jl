V = [1] # vector
S = 1   # scalar

c = Clock(0.1)
X, Y = DynamicRArray(c, V, S)

# unary ops
for op in (:+, :-)
    @eval begin
        @test $op(X) == $op(V)
        @test $op(Y) == $op(S)
    end
end

# binary ops for vector
for op in (:+, :-)
    @eval begin
        @test $op(X, X) == $op(X, V) == $op(V, X) == $op(V, V)
    end
end

# binary ops for vector and scalar
for op in (:*, :/)
    @eval begin
        @test $op(X, Y) == $op(X, S) == $op(V, Y) == $op(V, S)
        @test $op(Y, X) == $op(S, X) == $op(Y, V) == $op(S, V)
    end
end

# binary ops for scalar
for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @test $op(Y, Y) == $op(Y, S) == $op(S, Y) == $op(S, S)
    end
end

# broadcast
for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @test $op.(X, X) == $op.(X, V) == $op.(V, X) == $op.(V, V)
    end
end

# linear algebra ops
for op in (transpose, adjoint)
    @eval @test $op(X) == $op(state(X)) == $op(V)
end
