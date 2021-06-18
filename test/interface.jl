using RecordedArrays: selectvars

c = DiscreteClock(10)
pos = DynamicRArray(c, [0, 0])
for t in c
    if  t % 2 == 0
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
vplus  = vcat(repeat([0, -1], 5), 0)
vminus = 0:10

plus(t, x, y) = t, x + y
minus(t, x, y) = t, x - y
plusminus(x, y) = x + y, x - y

@testset "selectvars" begin
    @test selectvars(r, nothing) == [(t1, v1), (t2, v2)]
    @test selectvars(r, (0, 1)) == (t1, v1)
    @test selectvars(r, (0, 2)) == (t2, v2)
    @test selectvars(r, [(0, 1), (0, 2)]) == [(t1, v1), (t2, v2)]
    @test selectvars(r, (1, 2)) == (v1u, v2u)
    @test selectvars(r, (0, 1, 2)) == (tu, v1u, v2u)
    @test selectvars(r, (1, 1, 2, 2)) == (v1u, v1u, v2u, v2u)
    @test selectvars(r, (plus, 0, 1, 2)) == (tu, vplus)
    @test selectvars(r, (minus, 0, 1, 2)) == (tu, vminus)
    @test selectvars(r, (plusminus, 1, 2)) == (vplus, vminus)
    @test selectvars(r, plus) == (tu, vplus)
    @test selectvars(r, minus) == (tu, vminus)
    @test selectvars(r, [plus, minus]) == [(tu, vplus), (tu, vminus)]
end
