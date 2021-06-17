using RecordedArrays: rsize, rlength, StaticEntries, DynamicEntries

# init test vars
c = DiscreteClock(1)
DS1, DS2, DV1, DV2 = DynamicRArray(c, 1, fill(1), [1], 1:2)
SV1, SV2, _ = StaticRArray(c, [1], 1:2, 1:3)

@testset "create rarray with {V}" begin 
    UDS1, UDS2, UDV1, UDV2 = DynamicRArray{UInt}(c, 1, fill(1), [1], 1:2)
    USV1, USV2, USV3 = StaticRArray{UInt}(c, [1], 1:2, 1:3)
    for (D, UD) in Dict(DS1 => UDS1, DV1 => UDV1, SV1 => USV1)
        for i in 1:nfields(D)
            xi = getfield(D, i)
            xi_u = getfield(UD, i)
            if xi isa RecordedArrays.AbstractClock
                @test xi === c
                @test xi_u === c
            else
                @test xi == xi_u 
            end
        end
    end
end

@testset "setclock" begin
    cn = DiscreteClock(1)
    @test cn !== c
    for D in (DS1, DV1, SV1)
        D_copy = setclock(D, cn)
        for i in 1:nfields(D_copy)
            xi = getfield(D, i)
            xi_copy = getfield(D_copy, i)
            if xi isa RecordedArrays.AbstractClock
                @test xi === c
                @test xi !== cn
                @test xi_copy === cn
                @test xi_copy !== c
            else
                @test xi == xi_copy
                @test xi !== xi_copy
            end
        end
    end
end

@testset "length and size" begin
    @test length(DS1)  == 1
    @test length(DS2)  == 1
    @test length(DV1) == 1
    @test length(DV2) == 2
    @test length(SV1) == 1
    @test length(SV2) == 2

    @test size(DS1)  == (1,)
    @test size(DS2)  == (1,)
    @test size(DV1) == (1,)
    @test size(DV2) == (2,)
    @test size(SV1) == (1,)
    @test size(SV2) == (2,)
end

# push! and delateat!
for _ in c
    DS1[1] += 1
    DS2[1] += 1
    push!(SV1, UInt(2)) # test convert
    push!(DV1, UInt(2)) # test convert
    DV1[1] += 1
    deleteat!(SV2, 1)
    deleteat!(DV2, 1)
end

@testset "length and size after change" begin
    @test length(DS1) == 1
    @test length(DS2) == 1
    @test length(DV1) == 2
    @test length(DV2) == 1
    @test length(SV1) == 2
    @test length(SV2) == 1

    @test size(DS1)  == (1,)
    @test size(DS2)  == (1,)
    @test size(DV1) == (2,)
    @test size(DV2) == (1,)
    @test size(SV1) == (2,)
    @test size(SV2) == (1,)
end

@testset "rlength and rsize" begin
    @test rlength(DS1) == 1
    @test rlength(DS2) == 1
    @test rlength(DV1) == 2
    @test rlength(DV2) == 2
    @test rlength(SV1) == 2
    @test rlength(SV2) == 2

    @test rsize(DS1) == (1,)
    @test rsize(DS2) == (1,)
    @test rsize(DV1) == (2,)
    @test rsize(DV2) == (2,)
    @test rsize(SV1) == (2,)
    @test rsize(SV2) == (2,)
end

# get records
Dr1 = records(DV1)
Dr2 = records(DV2)
Dr3 = records(DS1)
Sr1 = records(SV1)
Sr2 = records(SV2)

@testset "rarray" begin
    @test rarray(Dr1) === DV1
    @test rarray(Dr2) === DV2
    @test rarray(Dr3) === DS1
    @test rarray(Sr1) === SV1
    @test rarray(Sr2) === SV2
end

@testset "Records" begin
    @test Base.IteratorSize(typeof(Dr1)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Dr2)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Dr3)) == Base.HasShape{0}()
    @test Base.IteratorSize(typeof(Sr1)) == Base.HasShape{1}()
    @test Base.IteratorSize(typeof(Sr2)) == Base.HasShape{1}()

    @test eltype(typeof(Dr1)) == DynamicEntries{Int,Int}
    @test eltype(typeof(Dr2)) == DynamicEntries{Int,Int}
    @test eltype(typeof(Dr3)) == DynamicEntries{Int,Int}
    @test eltype(typeof(Sr1)) == StaticEntries{Int,Int}
    @test eltype(typeof(Sr2)) == StaticEntries{Int,Int}

    @test length(Dr1) == 2
    @test length(Dr2) == 2
    @test length(Dr3) == 1
    @test length(Sr1) == 2
    @test length(Sr2) == 2
end

# create entries
e1 = Dr1[1]
e2 = Dr1[2]
e3 = Sr2[1]
e4 = Dr3[1]
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
    @test eltype(e4) == Pair{Int,Int}
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
    @test length(e4) == 2
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

    @test getindex(e4, 1) == (0 => 1)
    @test getindex(e4, 2) == (1 => 2)

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

@testset "gettime $alg" for alg in (LinearSearch(), BinarySearch())
    @test gettime(alg, e1, 0) == 1
    @test gettime(alg, e2, 0) == 0
    @test gettime(alg, e3, 0) == 1
    @test gettime(alg, e4, 0) == 1
    @test gettime(alg, u1, 0) == [1]
    @test gettime(alg, u12, 0) == [1, 0]
    @test gettime(alg, u23, 0) == [0, 1]
    @test gettime(alg, ur, 0) == [1, 0]
    @test gettime(alg, u123, 0) == [1, 0, 1]
    @test gettime(alg, u312, 0) == [1, 1, 0]
    @test gettime(alg, u1223, 0) == [1, 0, 0, 1]

    @test gettime(alg, e1, 1) == 2
    @test gettime(alg, e2, 1) == 2
    @test gettime(alg, e3, 1) == 1
    @test gettime(alg, e4, 1) == 2
    @test gettime(alg, u1, 1) == [2]
    @test gettime(alg, u12, 1) == [2, 2]
    @test gettime(alg, u23, 1) == [2, 1]
    @test gettime(alg, ur, 1) == [2, 2]
    @test gettime(alg, u123, 1) == [2, 2, 1]
    @test gettime(alg, u312, 1) == [1, 2, 2]
    @test gettime(alg, u1223, 1) == [2, 2, 2, 1]

    @test gettime(alg, e1, 2) == 2
    @test gettime(alg, e2, 2) == 2
    @test gettime(alg, e3, 2) == 0
    @test gettime(alg, e4, 2) == 2
    @test gettime(alg, u1, 2) == [2]
    @test gettime(alg, u12, 2) == [2, 2]
    @test gettime(alg, u23, 2) == [2, 0]
    @test gettime(alg, ur, 2) == [2, 2]
    @test gettime(alg, u123, 2) == [2, 2, 0]
    @test gettime(alg, u312, 2) == [0, 2, 2]
    @test gettime(alg, u1223, 2) == [2, 2, 2, 0]

    @test gettime(alg, e1, 0:2) == [1, 2, 2]
    @test gettime(alg, e2, 0:2) == [0, 2, 2]
    @test gettime(alg, e3, 0:2) == [1, 1, 0]
    @test gettime(alg, e4, 0:2) == [1, 2, 2]
    @test gettime(alg, u1, 0:2) == hcat([1; 2; 2])
    @test gettime(alg, u12, 0:2) == [1 0; 2 2; 2 2]
    @test gettime(alg, u23, 0:2) == [0 1; 2 1; 2 0]
    @test gettime(alg, ur, 0:2) == [1 0; 2 2; 2 2]
    @test gettime(alg, u123, 0:2) == [1 0 1; 2 2 1; 2 2 0]
    @test gettime(alg, u312, 0:2) == [1 1 0; 1 2 2; 0 2 2]
    @test gettime(alg, u1223, 0:2) == [1 0 0 1; 2 2 2 1; 2 2 2 0]
end
