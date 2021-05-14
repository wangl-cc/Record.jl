using RecordedArrays: rsize, rlength, SingleEntries

# init test vars
c = DiscreteClock(1)
DS, DV1, DV2 = DynamicRArray(c, 1, [1], [1, 2])
SV1, SV2 = StaticRArray(c, [1], [1, 2])

@testset "length and size" begin
    @test length(DS)  == 1
    @test length(DV1) == 1
    @test length(DV2) == 2
    @test length(SV1) == 1
    @test length(SV2) == 2

    @test size(DS)  == (1,)
    @test size(DV1) == (1,)
    @test size(DV2) == (2,)
    @test size(SV1) == (1,)
    @test size(SV2) == (2,)
end

# push! and delateat!
for _ in c
    push!(SV1, 2)
    push!(DV1, 2)
    deleteat!(SV2, 1)
    deleteat!(DV2, 1)
end

@testset "length and size after change" begin
    @test length(DS)  == 1
    @test length(DV1) == 2
    @test length(DV2) == 1
    @test length(SV1) == 2
    @test length(SV2) == 1

    @test size(DS)  == (1,)
    @test size(DV1) == (2,)
    @test size(DV2) == (1,)
    @test size(SV1) == (2,)
    @test size(SV2) == (1,)
end

@testset "rlength and rsize" begin
    @test rlength(DS)  == 1
    @test rlength(DV1) == 2
    @test rlength(DV2) == 2
    @test rlength(SV1) == 2
    @test rlength(SV2) == 2

    @test rsize(DS)  == (1,)
    @test rsize(DV1) == (2,)
    @test rsize(DV2) == (2,)
    @test rsize(SV1) == (2,)
    @test rsize(SV2) == (2,)
end

# get records
Dr1 = records(DV1)
Dr2 = records(DV2)
Sr1 = records(SV1)
Sr2 = records(SV2)

@testset "Records" begin
    @test Base.IteratorSize(typeof(Dr1)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Dr2)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Sr1)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Sr2)) == Base.HasShape{1}()
    @test eltype(typeof(Dr1)) == SingleEntries{Int,Int}
    @test eltype(typeof(Dr2)) == SingleEntries{Int,Int}
    @test eltype(typeof(Sr1)) == SingleEntries{Int,Int}
    @test eltype(typeof(Sr2)) == SingleEntries{Int,Int}
end

# create entries
e1 = Dr1[1]
e2 = Dr1[2]
e3 = Dr2[1]
u2 = unione(e1, e2)
u3 = unione(u2, e3)

@testset "Entries" begin
    @test eltype(e1) == Pair{Int,Int}
    @test eltype(e2) == Pair{Int,Int}
    @test eltype(u2) == Pair{Int,Vector{Int}}
    @test eltype(u3) == Pair{Int,Vector{Int}}

    @test getindex(e1, 1) == (0 => 1)
    @test getindex(e2, 1) == (1 => 2)
    @test getindex(u2, 1) == (0 => [1, 0])
    @test getindex(u2, 2) == (1 => [1, 2])
    @test getindex(u3, 1) == (0 => [1, 0, 1])
    @test getindex(u3, 2) == (1 => [1, 2, 1])
end
