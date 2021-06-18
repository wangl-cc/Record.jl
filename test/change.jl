# init vars
V = [1, 3]
S = 1
C = [0.1]
t = 0.0
T = 0.2
n = 0

c = ContinuousClock(T)
X, Y, _ = DynamicRArray(c, V, S, [1])
Z, _, _ = StaticRArray(c, C, [1], [1])

@test limit(c) ≈ T

# test record
for epoch in c
    global t, V, S, C, T, n
    increase!(c, 0.1)
    n += 1
    t += 0.1
    X[1] += 1
    V[1] += 1
    X[2] -= 1
    V[2] -= 1
    Y[1] += 1
    S += 1
    push!(Z, 0.1)
    push!(C, 0.1)
    @test n == epoch
    @test now(c) == t
    @test state(X) == V
    @test state(Y) == S
    @test Z[end] ≈ 0.1
    @test state(Z) ≈ C
end

@test now(c) ≈ 0.0

@test size(record(X)) == size(X)
@test length(record(X)) == length(X)

for (i, x) in enumerate(record(X))
    @test tspan(x) ≈ T
    @test getts(x) ≈ collect(0:0.1:T)
    if i == 1
        @test getvs(x) == collect(1:3)
    elseif i == 2
        @test getvs(x) == collect(3:-1:1)
    end
end

for (i, y) in enumerate(record(Y))
    @test i == 1
    @test tspan(y) == T
    @test getts(y) == collect(0:0.1:T)
    @test getvs(y) == collect(1:3)
end

for (z, t_) in zip(record(Z), 0:0.1:T)
    @test tspan(z) == T - t_
    @test getts(z) == [t_, T]
    @test getvs(z) == [0.1, 0.1]
end

push!(X, 1)
rX = record(X)
@test state(X) == push!(V, 1)
@test getts(rX[length(rX)]) == [0.0]
@test getvs(rX[length(rX)]) == [1]

deleteat!(X, 1)
@test state(X) == deleteat!(V, 1)

deleteat!(Z, 1)
@test state(Z) == deleteat!(C, 1)
# vim:tw=92:ts=4:sw=4:et
