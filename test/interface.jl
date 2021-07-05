c = DiscreteClock(10)
pos = DynamicRArray(c, [0, 0])
for t in c
    if t % 2 == 0
        pos[1] += 1
    else
        pos[2] -= 1
    end
end

r = record(pos)

t1 = vcat(0, 2:2:10)
t2 = vcat(0, 1:2:10)
tu = 0:10

v1 = collect(0:5)
v2 = -collect(0:5)
v1u = sort(repeat(v1, 2))[1:end-1]
v2u = sort(repeat(v2, 2), rev=true)[2:end]
vplus = vcat(repeat([0, -1], 5), 0)
vminus = 0:10

ue = unione(r)

plus(t, x, y) = t, x + y
minus(t, x, y) = t, x - y
plusminus(x, y) = x + y, x - y

@testset "selectrecs" begin
    @test selectrecs(r) == (v1u, v2u)
    @test selectrecs(r, 1) == (t1, v1)
    @test selectrecs(r, 2) == (t2, v2)
    @test selectrecs(r[1], 1) == (t1, v1)
    @test selectrecs(r[2], 1) == (t2, v2)
    @test selectrecs(r, 1, 2) == (v1u, v2u)
    @test selectrecs(r, T0, 1) == (t1, v1)
    @test selectrecs(r, T0, 2) == (t2, v2)
    @test selectrecs(r, T0, 1, 2) == (tu, v1u, v2u)
    @test selectrecs(ue, T0, 1) == (t1, v1)
    @test selectrecs(ue, T0, 2) == (t2, v2)
    @test selectrecs(ue, T0, 1, 2) == (tu, v1u, v2u)
    @test selectrecs(r, T0) == (tu, v1u, v2u)
    @test selectrecs(ue, T0) == (tu, v1u, v2u)
    @test selectrecs(r[1], T0) == (t1, v1)
    @test selectrecs(r[2], T0) == (t2, v2)
    @test selectrecs(r, t1, T0) == (t1, v1, v2)
    @test selectrecs(r, t1, 1) == (t1, v1)
    @test selectrecs(r, t1, 2) == (t1, v2)
    @test selectrecs(plus, r, T0, 1, 2) == (tu, vplus)
    @test selectrecs(minus, r, T0, 1, 2) == (tu, vminus)
    @test selectrecs(plusminus, r, 1, 2) == (vplus, vminus)
    @test selectrecs(plus, r, T0) == (tu, vplus)
    @test selectrecs(minus, r, T0) == (tu, vminus)
    # these are not recommanded, but be keeped for plot
    @test selectrecs(r, plus, T0, 1, 2) == (tu, vplus)
    @test selectrecs(r, minus, T0, 1, 2) == (tu, vminus)
    @test selectrecs(r, plusminus, 1, 2) == (vplus, vminus)
    @test selectrecs(r, plus, T0) == (tu, vplus)
    @test selectrecs(r, minus, T0) == (tu, vminus)
end
