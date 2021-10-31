using RecordedArrays: getentries

@testset "Vector resize!" begin
    c = ContinuousClock(10)
    v = recorded(StaticEntry, c, [1])
    increase!(c, 1) # t = 1
    resize!(v, 2)[2] = 2
    increase!(c, 1) # t = 2
    @test push!(v, 3) == 1:3
    increase!(c, 1) # t = 3
    @test resize!(v, (Bool[0,0,1],)) == [3]
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
    @test resize!(v, 1, Bool[1,0,0,0,1]) == Int[3, 8]
    es = getentries(v)
    @test getts(es[1]) == [0, 3]
    @test getts(es[2]) == [1, 3]
    @test getts(es[3]) == [2]
    @test getts(es[4]) == [4, 5]
    @test getts(es[5]) == [4, 9]
    @test getts(es[6]) == [6, 9]
    @test getts(es[7]) == [7, 9]
    @test getts(es[8]) == [8]
end
