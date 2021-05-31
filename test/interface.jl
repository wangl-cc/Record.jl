using RecordedArrays: _toplot

c = DiscreteClock(10)
pos = DynamicRArray(c, [0, 0])
for t in c
    if  t % 2 == 0
        pos[1] += 1
    else
        pos[2] -= 1
    end
end

r = records(pos)

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

@testset "_toplot" begin
    @test _toplot(r, nothing) == ([t1, t2], [v1, v2])
    @test _toplot(r, [(0, 1), (0, 2)]) == [(t1, v1), (t2, v2)]
    @test _toplot(r, (0, 1)) == (t1, v1)
    @test _toplot(r, (0, 2)) == (t2, v2)
    @test _toplot(r, (1, 2)) == (v1u, v2u)
    @test _toplot(r, (0, 1, 2)) == (tu, v1u, v2u)
    @test _toplot(r, (plus, 0, 1, 2)) == (tu, vplus)
    @test _toplot(r, (minus, 0, 1, 2)) == (tu, vminus)
end
