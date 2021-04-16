using Test
using RecordedArray
using Documenter

const setup_expr = :(begin
    using RecordedArray
    DocTestFilters = [
        r"Int\d+",
        r"Vector{\w+}",
        r"Matrix{\w+}",
        r"Array{\w+,[12]}"
    ]
end)

DocMeta.setdocmeta!(RecordedArray, :DocTestSetup, setup_expr; recursive = true)

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
