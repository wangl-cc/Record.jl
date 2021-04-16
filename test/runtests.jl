using Test
using RecordedArray
using Documenter

DocMeta.setdocmeta!(RecordedArray, :DocTestSetup, :(using RecordedArray); recursive = true)

@testset "RecordedArray" begin
    doctest(RecordedArray; testset = "Doctests")

    @testset "Math" begin
        include("math.jl")
    end

    @testset "Changes" begin
        include("change.jl")
    end
end


# vim:tw=92:ts=4:sw=4:et
