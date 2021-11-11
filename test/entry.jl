using RecordedArrays: return_type

@testset "$E" for E in (
    StaticEntry,
    StaticEntry{Int},
    StaticEntry{Int,Float64},
    DynamicEntry,
    DynamicEntry{Int},
    DynamicEntry{Int,Float64},
)
    c = DiscreteClock(3)
    e1 = E(1, c)
    e2 = E(0x2, currenttime(c))
    @test e1 isa return_type(E, 1, c)
    @test e1 isa return_type(E, Int, c)
    @test e2 isa return_type(E, 0x2, c)
    @test e2 isa return_type(E, typeof(0x2), c)

    for t in c
        if E <: DynamicEntry
            store!(e1, t, c)
            t != 3 && store!(e2, t + 1, c)
        end
        t == 2 && del!(e1, c)
        t == 3 && del!(e2, c)
    end

    @test e1 == deepcopy(e1)
    @test e2 == deepcopy(e2)
    @test e1 != e2

    @test gettime(e1, -1) == 0
    @test gettime(e2, -1) == 0
    if E <: StaticEntry
        @test getts(e1) == [0, 2]
        @test getts(e2) == [0, 3]
        @test tspan(e1) == 2
        @test tspan(e2) == 3
        @test getvs(e1) == [1, 1]
        @test getvs(e2) == [2, 2]
        @test gettime(e1, 0) == 1
        @test gettime(e2, 0) == 2
        @test gettime(e1, 1) == 1
        @test gettime(e2, 1) == 2
        @test gettime(e1, 2) == 1
        @test gettime(e2, 2) == 2
        @test gettime(e1, 3) == 0
        @test gettime(e2, 3) == 2
        @test gettime(e1, 1:2) == [1, 1]
        @test gettime(e2, 1:2) == [2, 2]
        @test gettime(e1, 1:3) == [1, 1, 0]
        @test gettime(e2, 1:3) == [2, 2, 2]
        @testset "gettime($alg)" for alg in (LinearSearch(), BinarySearch())
            @test gettime(alg, e1, 0) == 1
            @test gettime(alg, e2, 0) == 2
            @test gettime(alg, e1, 1) == 1
            @test gettime(alg, e2, 1) == 2
            @test gettime(alg, e1, 2) == 1
            @test gettime(alg, e2, 2) == 2
            @test gettime(alg, e1, 3) == 0
            @test gettime(alg, e2, 3) == 2
            @test gettime(alg, e1, 1:2) == [1, 1]
            @test gettime(alg, e2, 1:2) == [2, 2]
            @test gettime(alg, e1, 2:3) == [1, 0]
            @test gettime(alg, e2, 2:3) == [2, 2]
            @test gettime(alg, e1, 1:3) == [1, 1, 0]
            @test gettime(alg, e2, 1:3) == [2, 2, 2]
            @test gettime(alg, e1, -1:3) == [0, 1, 1, 1, 0]
            @test gettime(alg, e2, -1:3) == [0, 2, 2, 2, 2]
        end
    elseif E <: DynamicEntry
        @test getts(e1) == 0:3
        @test getts(e2) == 0:2
        @test tspan(e1) == 3
        @test tspan(e2) == 2
        @test getvs(e1) == [1, 1, 2, 3]
        @test getvs(e2) == [2, 2, 3]
        @test gettime(e1, 0) == 1
        @test gettime(e2, 0) == 2
        @test gettime(e1, 1) == 1
        @test gettime(e2, 1) == 2
        @test gettime(e1, 2) == 2
        @test gettime(e2, 2) == 3
        @test gettime(e1, 3) == 3
        @test gettime(e2, 3) == 3
        @test gettime(e1, 1:2) == [1, 2]
        @test gettime(e2, 1:2) == [2, 3]
        @test gettime(e1, 1:3) == [1, 2, 3]
        @test gettime(e2, 1:3) == [2, 3, 3]
        @test gettime(e1, 1.5:2.5) == [1, 2]
        @test gettime(e2, 1.5:2.5) == [2, 3]
        @test gettime(e1, 1.5:3.5) == [1, 2, 3]
        @test gettime(e2, 1.5:3.5) == [2, 3, 3]
        @testset "gettime($alg)" for alg in (LinearSearch(), BinarySearch())
            @test gettime(alg, e1, 0) == 1
            @test gettime(alg, e2, 0) == 2
            @test gettime(alg, e1, 1) == 1
            @test gettime(alg, e2, 1) == 2
            @test gettime(alg, e1, 2) == 2
            @test gettime(alg, e2, 2) == 3
            @test gettime(alg, e1, 3) == 3
            @test gettime(alg, e2, 3) == 3
            @test gettime(alg, e1, 1:2) == [1, 2]
            @test gettime(alg, e2, 1:2) == [2, 3]
            @test gettime(alg, e1, 1:3) == [1, 2, 3]
            @test gettime(alg, e2, 1:3) == [2, 3, 3]
            @test gettime(alg, e1, 1.5:2.5) == [1, 2]
            @test gettime(alg, e2, 1.5:2.5) == [2, 3]
            @test gettime(alg, e1, 1.5:3.5) == [1, 2, 3]
            @test gettime(alg, e2, 1.5:3.5) == [2, 3, 3]
            @test gettime(alg, e1, -1:3) == [0, 1, 1, 2, 3]
            @test gettime(alg, e2, -1:3) == [0, 2, 2, 3, 3]
        end
    end
end
