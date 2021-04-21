using Test
using RecordedArrays
using Documenter

# don't work now
filters = Regex[
    r"Int32|Int64",                 # Int64 <-> Int32
    r"Array{\w+,\s?1}|Vector{\w+}", # Array{X,1} <-> Vector{X} 
    r"Array{\w+,\s?2}|Matrix{\w+}", # Array{X,2} <-> Matrix{X}
]

DocMeta.setdocmeta!(RecordedArrays, :DocTestSetup, :(using RecordedArrays); recursive = true)

@testset "RecordedArray" begin
    if VERSION >= v"1.6" && Int64 == Int # run doctest only for v1.6+ and x64
        doctest(RecordedArray; testset = "Doctests", doctestfilters = filters)
    end

    @testset "Math" begin
        include("math.jl")
    end

    @testset "Changes" begin
        include("change.jl")
    end
end


# vim:tw=92:ts=4:sw=4:et
