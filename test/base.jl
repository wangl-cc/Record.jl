using RecordedArrays: rsize, rlength, StaticEntries, DynamicEntries

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
    DV1[1] += 1
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

    @test eltype(typeof(Dr1)) == DynamicEntries{Int,Int}
    @test eltype(typeof(Dr2)) == DynamicEntries{Int,Int}
    @test eltype(typeof(Sr1)) == StaticEntries{Int,Int}
    @test eltype(typeof(Sr2)) == StaticEntries{Int,Int}

    @test length(Dr1) == 2
    @test length(Dr2) == 2
    @test length(Sr1) == 2
    @test length(Sr2) == 2
end

# create entries
e1 = Dr1[1]
e2 = Dr1[2]
e3 = Sr2[1]
u1 = unione(e1)
u12 = unione(e1, e2)
u23 = unione(e2, e3)
ur = unione(Dr1)
u123 = unione(u12, e3)
u312 = unione(e3, u12)
u1223 = unione(u12, u23)

@testset "Entries" begin
    @test eltype(e1) == Pair{Int,Int}
    @test eltype(e2) == Pair{Int,Int}
    @test eltype(e3) == Pair{Int,Int}
    @test eltype(u1) == Pair{Int,Vector{Int}}
    @test eltype(u12) == Pair{Int,Vector{Int}}
    @test eltype(u23) == Pair{Int,Vector{Int}}
    @test eltype(ur) == Pair{Int,Vector{Int}}
    @test eltype(u123) == Pair{Int,Vector{Int}}
    @test eltype(u312) == Pair{Int,Vector{Int}}
    @test eltype(u1223) == Pair{Int,Vector{Int}}
    
    @test length(e1) == 2
    @test length(e2) == 1
    @test length(e3) == 2
    @test length(u1) == 2
    @test length(u12) == 2
    @test length(u23) == 2
    @test length(ur) == 2
    @test length(u123) == 2
    @test length(u312) == 2
    @test length(u1223) == 2

    @test getindex(e1, 1) == (0 => 1)
    @test getindex(e1, 2) == (1 => 2)

    @test getindex(e2, 1) == (1 => 2)

    @test getindex(e3, 1) == (0 => 1)
    @test getindex(e3, 2) == (1 => 1)

    @test getindex(u1, 1) == (0 => [1])
    @test getindex(u1, 2) == (1 => [2])

    @test getindex(u12, 1) == (0 => [1, 0])
    @test getindex(u12, 2) == (1 => [2, 2])

    @test getindex(u23, 1) == (0 => [0, 1])
    @test getindex(u23, 2) == (1 => [2, 1])

    @test getindex(ur, 1) == (0 => [1, 0])
    @test getindex(ur, 2) == (1 => [2, 2])

    @test getindex(u123, 1) == (0 => [1, 0, 1])
    @test getindex(u123, 2) == (1 => [2, 2, 1])

    @test getindex(u312, 1) == (0 => [1, 1, 0])
    @test getindex(u312, 2) == (1 => [1, 2, 2])

    @test getindex(u1223, 1) == (0 => [1, 0, 0, 1])
    @test getindex(u1223, 2) == (1 => [2, 2, 2, 1])
end

@testset "gettime" begin
    @test gettime(e1, 0) == 1
    @test gettime(e2, 0) == 0
    @test gettime(e3, 0) == 1
    @test gettime(u1, 0) == [1]
    @test gettime(u12, 0) == [1, 0]
    @test gettime(u23, 0) == [0, 1]
    @test gettime(ur, 0) == [1, 0]
    @test gettime(u123, 0) == [1, 0, 1]
    @test gettime(u312, 0) == [1, 1, 0]
    @test gettime(u1223, 0) == [1, 0, 0, 1]

    @test gettime(e1, 1) == 2
    @test gettime(e2, 1) == 2
    @test gettime(e3, 1) == 1
    @test gettime(u1, 1) == [2]
    @test gettime(u12, 1) == [2, 2]
    @test gettime(u23, 1) == [2, 1]
    @test gettime(ur, 1) == [2, 2]
    @test gettime(u123, 1) == [2, 2, 1]
    @test gettime(u312, 1) == [1, 2, 2]
    @test gettime(u1223, 1) == [2, 2, 2, 1]

    @test gettime(e1, 2) == 2
    @test gettime(e2, 2) == 2
    @test gettime(e3, 2) == 0
    @test gettime(u1, 2) == [2]
    @test gettime(u12, 2) == [2, 2]
    @test gettime(u23, 2) == [2, 0]
    @test gettime(ur, 2) == [2, 2]
    @test gettime(u123, 2) == [2, 2, 0]
    @test gettime(u312, 2) == [0, 2, 2]
    @test gettime(u1223, 2) == [2, 2, 2, 0]
end
