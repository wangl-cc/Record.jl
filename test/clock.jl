using Base.Iterators: IteratorSize, HasShape, HasLength, SizeUnknown

@testset "DiscreteClock" begin
    c1 = DiscreteClock(3)
    c2 = DiscreteClock(0:3)
    c3 = DiscreteClock(0, 1:3)

    @testset "IteratorSize" begin
        @test IteratorSize(c1) == HasLength()
        @test IteratorSize(c2) == HasLength()
        @test IteratorSize(c3) == HasLength()
    end

    @testset "length" begin
        @test length(c1) == 3
        @test length(c2) == 3
        @test length(c3) == 3
    end

    @testset "eltype" begin
        @test eltype(c1) == Int
        @test eltype(c2) == Int
        @test eltype(c3) == Int
    end

    @testset "collect" begin
        @test collect(c1) == [1, 2, 3]
        @test collect(c2) == [1, 2, 3]
        @test collect(c3) == [1, 2, 3]
    end
end

@testset "ContinuousClock" begin
    c1 = ContinuousClock(3.0)
    c2 = ContinuousClock(3.0; max_epoch=2)
    c3 = ContinuousClock(3.0, 1.0)

    @testset "IteratorSize" begin
        @test IteratorSize(c1) == SizeUnknown()
        @test IteratorSize(c2) == SizeUnknown()
        @test IteratorSize(c3) == SizeUnknown()
    end

    @testset "eltype" begin
        @test eltype(c1) == Float64
        @test eltype(c2) == Float64
        @test eltype(c3) == Float64
    end

    @testset "comprehension" begin
        @test [(increase!(c1, 1); (i, currenttime(c1))) for i in c1] == collect(zip(1:3, 1.0:3.0))
        @test [(increase!(c2, 1); (i, currenttime(c2))) for i in c2] == collect(zip(1:2, 1.0:2.0))
        @test [(increase!(c3, 1); (i, currenttime(c3))) for i in c3] == collect(zip(1:2, 2.0:3.0))
    end

    @testset "auto-initialize" begin
        @test currenttime(c1) == start(c1)
        @test currenttime(c2) != start(c2)
        @test currenttime(c3) == start(c3)
    end
end
