using Test
using RecordedArrays

@testset "RecordedArrays" begin
    @testset "Utilities" begin
        include("utils.jl")
    end

    @testset "Clock" begin
        include("clock.jl")
    end

    @testset "Base" begin
        include("base.jl")


    @testset "Resize" begin
        include("resize.jl")
    end

    @testset "Changes" begin
        include("change.jl")
    end

    @testset "Interfaces" begin
        include("interface.jl")
    end
end

# vim:tw=92:ts=4:sw=4:et
