using RecordedArrays: getdim

@testset "MCIndices" begin
    im = MCIndices(([1, 2, 3], [1, 3, 4], [2, 4, 5]))
    @test size(im) == (3, 3, 3)
    for i in ndims(im)
        @test getdim(im, i) == im.indices[i]
    end
    for (i, ind) in enumerate(im)
        Is = Base._ind2sub(im, i)
        @test map(getindex, im.indices, Is) == ind
    end
    for i in ndims(im)
        push!(getdim(im, i), 6)
        @test im.indices[i][end] == 6
        @test length(im.indices[i]) == 4
    end
end

@testset "DOKSparseArray" begin
    s = DOKSparseArray(Dict{Tuple{},Int}(()=>1), Size())
    @test s[] == 1
    s[] = 2
    @test get(s, (), 1) == 2
end
