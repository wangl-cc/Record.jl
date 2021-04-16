using Test
using RecordedArray
using Documenter

const doctestfilters = [
    # Array{X,1} -> Vector{X} and Array{X,2} -> Matrix{X}
    r"Int32|Int64",
    r"{([a-zA-Z0-9]+,\s?)+[a-zA-Z0-9]+}",
    r"(Array{[a-zA-Z0-9]+,\s?1}|Vector{[a-zA-Z0-9]+})",
    r"(Array{[a-zA-Z0-9]+,\s?2}|Matrix{[a-zA-Z0-9]+})",
]

DocMeta.setdocmeta!(RecordedArray, :DocTestSetup, :(using RecordedArray); recursive = true)

@testset "RecordedArray" begin
    doctest(RecordedArray; testset = "Doctests", doctestfilters = doctestfilters)

    @testset "Math" begin
        include("math.jl")
    end

    @testset "Changes" begin
        include("change.jl")
    end
end


# vim:tw=92:ts=4:sw=4:et
