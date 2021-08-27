using RecordedArrays: Size, IndexMap, pushdim!, insertdim!, deletedim!

@testset "Size" begin
    sz = Size(2, 2, 2)
    @test length(sz) == 3
    tp = sz.sz
    sz[3] = 3
    @test tp[3] == 2
    @test sz[3] == 3
    @test tp == (2, 2, 2)
    @test sz.sz == (2, 2, 3)
end

@testset "IndexMap" begin
    indmap = IndexMap((
        [1, 2, 3],
        [1, 3, 4],
        [2, 4, 5],
    ))
    for (ind, sub) in enumerate(indmap)
        @test map(getindex, indmap.Is, Base._ind2sub(indmap, ind)) == sub
    end

    @test pushdim!(indmap, 1, 4)[4, 2, 1] == (4, 3, 2)
    @test insertdim!(indmap, 2, 2, 2)[4, 2, 1] == (4, 2, 2)
    @test deletedim!(indmap, 3, 1)[4, 2, 1] == (4, 2, 4)
end
