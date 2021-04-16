# init test vars
V = [1] # vector
S = 1   # scalar 
c = DiscreteClock(1)
X, Y = DynamicRArray(c, V, S)

@testset "Unary Operations: $op" for op in (:+, :-)
    @eval begin
        @test $op(X) == $op(V)
        @test $op(Y) == $op(S)
    end
end

@testset "Binary Operations for Vector: $op" for op in (:+, :-)
    @eval begin
        @test $op(X, X) == $op(X, V) == $op(V, X) == $op(V, V)
    end
end

@testset "Binary Operations for Vector and Scalar: $op" for op in (:*, :/)
    @eval begin
        @test $op(X, Y) == $op(X, S) == $op(V, Y) == $op(V, S)
        @test $op(Y, X) == $op(S, X) == $op(Y, V) == $op(S, V)
    end
end

@testset "Binary Operations for Scalar: $op" for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @test $op(Y, Y) == $op(Y, S) == $op(S, Y) == $op(S, S)
    end
end

@testset "Broadcast: $op" for op in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @test $op.(X, X) == $op.(X, V) == $op.(V, X) == $op.(V, V)
    end
end

@testset "Linear Algebra: $op" for op in (transpose, adjoint)
    @eval @test $op(X) == $op(state(X)) == $op(V)
    for bop in (:+, :-)
        @eval @test $bop($op(X), $op(X)) == $bop($op(V), $op(V))
    end
    for bop in (:*,)
        @eval @test $bop($op(X), X) == $bop($op(V), V)
        @eval @test $bop(X, $op(X)) == $bop(V, $op(V))
    end
end
# vim:tw=92:ts=4:sw=4:et
