using RecordedArrays: _record
# init test vars
c = DiscreteClock(1) # clock

const Es = (DynamicEntry, StaticEntry)

@testset "resize Vector: $E" for E in Es
    v = rarray(E, c, Int[])
    sizehint!(v, 10)
    for i in 1:10
        push!(v, i)
    end
    @test length(v) == 10
    @test v == 1:10
    @test _record(v).indmap == 1:10
    deleteat!(v, 1:5)
    @test length(v) == 5
    @test v == 6:10
    @test _record(v).indmap == 6:10
    insert!(v, 1, 5)
    @test length(v) == 6
    @test v == 5:10
    @test _record(v).indmap == [11; 6:10]
    append!(c, i, 11:14)
    @test length(v) == 10
    @test v == 5:14
    @test _record(v).indmap == [11; 6:10; 12:15]
    resize!(v, 5)
    @test length(v) == 5
    @test v == 10:14
    @test _record(v).indmap == [10; 12:15]
end
