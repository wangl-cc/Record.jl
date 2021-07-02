const BENCH = parse(Bool, get(ENV, "JULIA_RA_DOBENCH", "false"))

# test equal and benchmark
macro testbench(ex::Expr)
    if ex.head == :call && ex.args[1] == :(==)
        exs = ex.args[2:3]
    elseif ex.head == :comparison && all(ex.args[2:2:end] .== :(==))
        exs = ex.args[1:2:end]
    end
    return quote
        @test $ex
        if BENCH # benchmark test only for set true in ENV
            trials = ($((:(@benchmark $(Expr(:$, sub))) for sub in exs)...),)
            # use the last ex as benchmark
            benchmark_allocs = allocs(trials[end])  # no more allocs
            benchmark_time = mean(trials[end].times) * 2 # less than 2× time
            @test all(t -> (allocs(t) <= benchmark_allocs), trials)
            @test all(t -> (mean(t.times) <= benchmark_time), trials)
        end
    end
end

# init test vars
S = rand(ComplexF64)          # scalar 
V = rand(ComplexF64, 2)       # vector
M = rand(ComplexF64, 2, 2)    # matrix
A = rand(ComplexF64, 2, 2, 2) # 3-rank array

c = DiscreteClock(1)
tS, tV = DynamicRArray(c, S, V)
tM, tA = RecordedArrays._testa(M, A) # test arrays

@testset "Unary Operations: $f" for f in (:+, :-, :conj, :real, :imag)
    @eval begin
        @test $f(tS) == $f(S)
        @test $f(tV) == $f(V)
        @test $f(tM) == $f(M)
        @test $f(tA) == $f(A)
    end
end

@testset "reverse" begin
    @test reverse(tV) == reverse(V)
    if VERSION >= v"1.6"
        @test reverse(tM) == reverse(M)
        @test reverse(tA) == reverse(A)
    end
    @test reverse(tM; dims=1) == reverse(M; dims=1)
    @test reverse(tA; dims=1) == reverse(A; dims=1)
end

@testset "Binary Operations: $f" for f in (:+, :-)
    @eval begin
        @testbench $f(tS, tS) == $f(tS, S) == $f(S, tS) == $f(S, S)
        @testbench $f(tV, tV) == $f(tV, V) == $f(V, tV) == $f(V, V)
        @testbench $f(tM, tM) == $f(tM, M) == $f(M, tM) == $f(M, M)
        @testbench $f(tA, tA) == $f(tA, A) == $f(A, tA) == $f(A, A)
    end
end

@testset "N-ary Operations: $f" for f in (:+,)
    @eval begin
        @testbench $f(tS, tS, tS) == $f(S, S, S)
        @testbench $f(tV, tV, tV) == $f(V, V, V)
        @testbench $f(tM, tM, tM) == $f(M, M, M)
        @testbench $f(tA, tA, tA) == $f(A, A, A)
    end
end

@testset "Binary Operations for Array and Scalar: $f" for f in (:*, :/, :\)
    if f !== :/
        @eval @testbench $f(tS, tV) == $f(tS, V) == $f(S, tV) == $f(S, V)
        @eval @testbench $f(tS, tM) == $f(tS, M) == $f(S, tM) == $f(S, M)
        @eval @testbench $f(tS, tA) == $f(tS, A) == $f(S, tA) == $f(S, A)
    end
    if f !== :\
        @eval @testbench $f(tV, tS) == $f(V, tS) == $f(tV, S) == $f(V, S)
        @eval @testbench $f(tM, tS) == $f(M, tS) == $f(tM, S) == $f(M, S)
        @eval @testbench $f(tA, tS) == $f(A, tS) == $f(tA, S) == $f(A, S)
    end
end

@testset "Binary Operations for Scalar: $f" for f in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @testbench $f(tS, tS) == $f(tS, S) == $f(S, tS) == $f(S, S)
    end
end

@testset "Broadcast: $f" for f in (:+, :-, :*, :/, :\, :^)
    @eval begin
        @testbench $f.(tV, tV) == $f.(tV, V) == $f.(V, tV) == $f.(V, V)
    end
end

@testset "Linear Algebra: $f" for f in (transpose, adjoint)
    @eval @testbench $f(tV) == $f(state(tV)) == $f(V)
    @eval @testbench $f(tM) == $f(state(tM)) == $f(M)
    for bf in (:+, :-)
        @eval @testbench $bf($f(tV), $f(tV)) == $bf($f(V), $f(V))
        @eval @testbench $bf($f(tM), $f(tM)) == $bf($f(M), $f(M))
    end
    for bf in (:*,)
        @eval begin
            @testbench $bf($f(tV), tV) == $bf($f(V), V)
            @testbench $bf(tV, $f(tV)) == $bf(V, $f(V))
            @testbench $bf($f(tM), tM) == $bf($f(M), M)
            @testbench $bf(tM, $f(tM)) == $bf(M, $f(M))
        end
    end
end

@testset "Linear Algebra: M $f V and M $f M" for f in (:*, :\)
    @eval begin
        @testbench $f(tM, tV) == $f(tM, V) == $f(M, tV) == $f(M, V)
        @testbench $f(tM, tM) == $f(tM, M) == $f(M, tM) == $f(M, M)
    end
end

# vim:tw=92:ts=4:sw=4:et
