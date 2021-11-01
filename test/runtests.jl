using Aqua
using Test
using RecordedArrays

@testset "RecordedArrays" begin
    @testset "QA" begin
        _params(T::UnionAll) = _params(T.body)
        _params(T::DataType) = T.parameters
        @testset "Ambiguity" begin
            ambiguities = Test.detect_ambiguities(RecordedArrays)
            filter!(ambiguities) do (m1, m2)
                p1 = _params(m1.sig)
                p2 = _params(m2.sig)
                for (t1, t2) in zip(p1, p2)
                    typeintersect(t1, t2) === Union{} && return false
                end
                return true
            end
            if !isempty(ambiguities)
                for amb in ambiguities
                    println(amb[1])
                    println(amb[2])
                end
            end
            @test isempty(ambiguities)
        end
        Aqua.test_all(RecordedArrays; ambiguities=false, deps_compat=false)
    end

    @testset "Utilities" begin
        include("utils.jl")
    end

    @testset "Clock" begin
        include("clock.jl")
    end

    @testset "Entry" begin
        include("entry.jl")
    end

    @testset "RArray" begin
        include("rarray.jl")
    end

    @testset "RNumber" begin
        include("rnumber.jl")
    end
end

# vim:tw=92:ts=4:sw=4:et
