using RecordedArrays: TimeSeries, PhasePortrait

@testset "Scalar" begin
    c = DiscreteClock(10)
    s = recorded(DynamicEntry, c, fill(0))
    @test size(s) == ()
    for t in c
        s[] = t
        @test s[] == t
    end
    e1 = getentries(s)
    @test e1 == RecordedArrays.getrecord(s)[]
    @test getts(e1) == 0:10
    @test getvs(e1) == 0:10
    @test ArrayInterface.parent_type(getrecord(s)) == DynamicEntry{Int,Int}
end

@testset "Vector" begin
    @testset "Static" begin
        c = ContinuousClock(10)
        v = recorded(StaticEntry, c, [1])
        increase!(c, 1) # t = 1
        resize!(v, 2)[2] = 2
        increase!(c, 1) # t = 2
        @test push!(v, 3) == 1:3
        increase!(c, 1) # t = 3
        @test resize!(v, (Bool[0, 0, 1],)) == [3]
        increase!(c, 1) # t = 4
        resize!(v, (3,))
        v[2:3] = 4:5 # this a setindex!
        increase!(c, 1) # t = 5
        @test deleteat!(v, 2) == [3, 5]
        increase!(c, 1) # t = 6
        @test insert!(v, 2, 6) == [3, 6, 5]
        increase!(c, 1) # t = 7
        @test append!(v, [7]) == [3, 6, 5, 7]
        increase!(c, 1) # t = 8
        @test append!(v, 8) == [3, 6, 5, 7, 8]
        increase!(c, 1) # t = 9
        @test resize!(v, 1, Bool[1, 0, 0, 0, 1]) == [3, 8]
        increase!(c, 1) # t = 10
        @test resize!(v, 1) == [3]
        es = getentries(v)
        @test getts(es[1]) == [0, 3]
        @test getts(es[2]) == [1, 3]
        @test getts(es[3]) == [2]
        @test getts(es[4]) == [4, 5]
        @test getts(es[5]) == [4, 9]
        @test getts(es[6]) == [6, 9]
        @test getts(es[7]) == [7, 9]
        @test getts(es[8]) == [8, 10]
        @test gettime(es, 0) == [1, 0, 0, 0, 0, 0, 0, 0]
        @test gettime(es, 1) == [1, 2, 0, 0, 0, 0, 0, 0]
        @test gettime(es, 2) == [1, 2, 3, 0, 0, 0, 0, 0]
        @test gettime(es, 3) == [1, 2, 3, 0, 0, 0, 0, 0]
        @test gettime(es, 4) == [0, 0, 3, 4, 5, 0, 0, 0]
        @test gettime(es, 5) == [0, 0, 3, 4, 5, 0, 0, 0]
        @test gettime(es, 6) == [0, 0, 3, 0, 5, 6, 0, 0]
        @test gettime(es, 7) == [0, 0, 3, 0, 5, 6, 7, 0]
        @test gettime(es, 8) == [0, 0, 3, 0, 5, 6, 7, 8]
        @test gettime(es, 9) == [0, 0, 3, 0, 5, 6, 7, 8]
        @test gettime(es, 10) == [0, 0, 3, 0, 0, 0, 0, 8]
        @test gettime(es, 11) == [0, 0, 3, 0, 0, 0, 0, 0]
        @test gettime(es, -0.5) == [0, 0, 0, 0, 0, 0, 0, 0]
        @test gettime(es, 1.5) == [1, 2, 0, 0, 0, 0, 0, 0]
        @test gettime(es, 3.5) == [0, 0, 3, 0, 0, 0, 0, 0]
        @test gettime(es, 9.5) == [0, 0, 3, 0, 0, 0, 0, 8]
        ts = -0.5:0.5:10.5
        m = gettime(es, ts)
        for (i, t) in enumerate(ts)
            @test m[i, :] ==
                  gettime(es, t) ==
                  map(&, gettime(es, round(t, RoundUp)), gettime(es, round(t, RoundDown)))
        end
    end
    @testset "Dynamic" begin
        c = ContinuousClock(10)
        v = recorded(DynamicEntry, c, [1])
        increase!(c, 1) # t = 1
        resize!(v, 2)[:] = 2:3
        @test v == 2:3
        increase!(c, 1) # t = 2
        v[2] = 4
        @test v == [2, 4]
        increase!(c, 1) # t = 3
        @test resize!(v, (1,)) == [2]
        increase!(c, 1) # t = 4
        v[1] = 5
        increase!(c, 1) # t = 5
        resize!(v, (3,))[2:3] = 6:7
        @test v == 5:7
        es = getentries(v)
        @test getts(es[1]) == [0, 1, 4]
        @test getts(es[2]) == [1, 2]
        @test getts(es[3]) == [5]
        @test getts(es[4]) == [5]
        @test getvs(es[1]) == [1, 2, 5]
        @test getvs(es[2]) == [3, 4]
        @test getvs(es[3]) == [6]
        @test getvs(es[4]) == [7]

        @test gettime(es, 0) == [1, 0, 0, 0]
        @test gettime(es, 1) == [2, 3, 0, 0]
        @test gettime(es, 2) == [2, 4, 0, 0]
        @test gettime(es, 3) == [2, 4, 0, 0]
        @test gettime(es, 4) == [5, 4, 0, 0]
        @test gettime(es, 5) == [5, 4, 6, 7]
        @test gettime(es, -0.5) == [0, 0, 0, 0]
        @test gettime(es, 1.5) == [2, 3, 0, 0]
        @test gettime(es, 2.5) == [2, 4, 0, 0]
        @test gettime(es, 3.5) == [2, 4, 0, 0]
        @test gettime(es, 0:2:4) == [1 0 0 0; 2 4 0 0; 5 4 0 0]
        @test gettime(es, -1:2:5) == [0 0 0 0; 2 3 0 0; 2 4 0 0; 5 4 6 7]
        ts = 0:0.5:5.5
        a = gettime(es, ts)
        for (i, t) in enumerate(ts)
            @test a[i, :] == gettime(es, t) == gettime(es, round(t, RoundDown))
        end
    end
end

@testset "Matrix" begin
    @testset "Static" begin
        c = ContinuousClock(10)
        m = recorded(StaticEntry, c, fill(1, 1, 1))
        increase!(c, 1) # t = 1
        resize!(m, (2, 2))[2:4] = 2:4
        increase!(c, 1) # t = 2
        resize!(m, 2, 3)[5:6] = 5:6
        @test vec(m) == 1:6
        increase!(c, 1) # t = 3
        @test resize!(m, (:, 2:3)) == reshape(3:6, 2, 2)
        increase!(c, 1) # t = 4
        @test resize!(m, 1, 1) == [3 5]
        increase!(c, 1) # t = 5
        resize!(m, 1, 3)[not(1), :] = reshape(7:10, 2, 2)
        increase!(c, 1) # t = 6
        resize!(m, 2, 3)[:, 3] = reshape(11:13, 1, 3)
        @test m == [
            3 5 11
            7 9 12
            8 10 13
        ]
        increase!(c, 1) # t = 7
        @test resize!(m, (not(2), not(2))) |> vec == [3, 8, 11, 13]
        es = getentries(m)
        @test getts(es[1, 1]) == [0, 3] # 1
        @test getts(es[2, 1]) == [1, 3] # 2
        @test getts(es[1, 2]) == [1]    # 3
        @test getts(es[2, 2]) == [1, 4] # 4
        @test getts(es[1, 3]) == [2, 7] # 5
        @test getts(es[2, 3]) == [2, 4] # 6
        @test getts(es[3, 2]) == [5, 7] # 7
        @test getts(es[4, 2]) == [5]    # 8
        @test getts(es[3, 3]) == [5, 7] # 9
        @test getts(es[4, 3]) == [5, 7] # 10
        @test getts(es[1, 4]) == [6]    # 11
        @test getts(es[3, 4]) == [6, 7] # 12
        @test getts(es[4, 4]) == [6]    # 13
        @test gettime(es, 0) == [1 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 1) == [1 3 0 0; 2 4 0 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 2) == [1 3 5 0; 2 4 6 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 3) == [1 3 5 0; 2 4 6 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 4) == [0 3 5 0; 0 4 6 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 5) == [0 3 5 0; 0 0 0 0; 0 7 9 0; 0 8 10 0]
        @test gettime(es, 6) == [0 3 5 11; 0 0 0 0; 0 7 9 12; 0 8 10 13]
        @test gettime(es, 7) == [0 3 5 11; 0 0 0 0; 0 7 9 12; 0 8 10 13]
        @test gettime(es, 8) == [0 3 0 11; 0 0 0 0; 0 0 0 0; 0 8 0 13]
        @test gettime(es, -0.5) == [0 0 0 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 0.5) == gettime(es, 0)
        @test gettime(es, 1.5) == gettime(es, 1)
        @test gettime(es, 3.5) == gettime(es, 4)
        @test gettime(es, 4.5) == [0 3 5 0; 0 0 0 0; 0 0 0 0; 0 0 0 0]
        @test gettime(es, 6.5) == gettime(es, 6)
        ts = 0:0.5:7.5
        a = gettime(es, ts)
        for (i, t) in enumerate(ts)
            @test a[i, :, :] ==
                  gettime(es, t) ==
                  map(&, gettime(es, round(t, RoundUp)), gettime(es, round(t, RoundDown)))
        end
    end
    @testset "DynamicEntry" begin
        c = ContinuousClock(10)
        m = recorded(DynamicEntry, c, fill(1, 1, 1))
        increase!(c, 1) # t = 1
        resize!(m, (2, 2))[2:4] = 2:4
        increase!(c, 1) # t = 2
        m[1] = 5
        increase!(c, 1) # t = 3
        resize!(m, 2, 3)[5:6] = 6:7
        increase!(c, 1) # t = 4
        m[2, 3] = 8
        increase!(c, 1) # t = 5
        resize!(m, (:, not(2))) |> vec == [5, 2, 6, 8]
        increase!(c, 1) # t = 6
        m[2] = 9
        increase!(c, 1) # t = 7
        m[3] = 10
        @test m[:] == [5, 9, 10, 8]
        increase!(c, 1) # t = 8
        resize!(m, (3, :))[3, :] = 11:12
        increase!(c, 1) # t = 9
        m[3, 1] = 13
        @test m == [5 10; 9 8; 13 12]
        es = getentries(m)
        @test getts(es[1, 1]) == [0, 2]
        @test getts(es[2, 1]) == [1, 6]
        @test getts(es[1, 2]) == [1]
        @test getts(es[2, 2]) == [1]
        @test getts(es[1, 3]) == [3, 7]
        @test getts(es[2, 3]) == [3, 4]
        @test getts(es[3, 1]) == [8, 9]
        @test getts(es[3, 3]) == [8]

        @test getvs(es[1, 1]) == [1, 5]
        @test getvs(es[2, 1]) == [2, 9]
        @test getvs(es[1, 2]) == [3]
        @test getvs(es[2, 2]) == [4]
        @test getvs(es[1, 3]) == [6, 10]
        @test getvs(es[2, 3]) == [7, 8]
        @test getvs(es[3, 1]) == [11, 13]
        @test getvs(es[3, 3]) == [12]

        @test gettime(es, 0) == [1 0 0; 0 0 0; 0 0 0]
        @test gettime(es, 1) == [1 3 0; 2 4 0; 0 0 0]
        @test gettime(es, 2) == [5 3 0; 2 4 0; 0 0 0]
        @test gettime(es, 3) == [5 3 6; 2 4 7; 0 0 0]
        @test gettime(es, 4) == [5 3 6; 2 4 8; 0 0 0]
        @test gettime(es, 5) == [5 3 6; 2 4 8; 0 0 0]
        @test gettime(es, 6) == [5 3 6; 9 4 8; 0 0 0]
        @test gettime(es, 7) == [5 3 10; 9 4 8; 0 0 0]
        @test gettime(es, 8) == [5 3 10; 9 4 8; 11 0 12]
        @test gettime(es, 9) == [5 3 10; 9 4 8; 13 0 12]
        ts = 0:0.5:9.5
        a = gettime(es, ts)
        for (i, t) in enumerate(ts)
            @test a[i, :, :] == gettime(es, t) == gettime(es, round(t, RoundDown))
        end
    end
end

@testset "MISC" begin
    @testset "Recipes" begin
        v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
        test_recipe(TimeSeries((v,)), [([0], [1]), ([0], [2])])
        test_recipe(TimeSeries((getentries(v),)), [([0], [1]), ([0], [2])])
        test_recipe(TimeSeries((getentries(v)...,)), [([0], [1]), ([0], [2])])
        test_recipe(PhasePortrait((v,)), [([1], [2])])
        test_recipe(PhasePortrait((getentries(v),)), [([1], [2])])
        test_recipe(PhasePortrait((getentries(v)...,)), [([1], [2])])
        m = recorded(DynamicEntry, ContinuousClock(10), [1 2])
        # the order may be different, thus only test TimeSeries
        test_recipe(TimeSeries((m,)), [([0], [1]), ([0], [2])])
        test_recipe(TimeSeries((getentries(m),)), [([0], [1]), ([0], [2])])
        test_recipe(TimeSeries((getentries(m)...,)), [([0], [1]), ([0], [2])])
    end
    @testset "Show" begin
        v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
        test_show(v, "2-element recorded(::$(Vector{Int}):\n 1\n 2")
        r = getrecord(v)
        test_show(r, "2-element $(typeof(r))")
        e = getentries(v)[1]
        test_show(e, "$(typeof(e)) with timestamps:\n 0")
    end
    @testset "sizehint!" begin
        # run one time for compile
        v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
        sizehint!(v, 3)
        sizehint!(getrecord(v), 3)
        @test begin
            v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
            sizehint!(v, 3)
            @allocated resize!(v, 3)
        end < begin
            v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
            @allocated resize!(v, 3)
        end
        @test begin
            v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
            sizehint!(getrecord(v), 3)
            @allocated resize!(v, 3)
        end < begin
            v = recorded(DynamicEntry, ContinuousClock(10), [1, 2])
            @allocated resize!(v, 3)
        end
    end
end
