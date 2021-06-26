using RecordedArrays: _testa

function stringshow(x)
    io = IOBuffer()
    show(io, MIME("text/plain"), x)
    return String(take!(io))
end

c = DiscreteClock(1)

@testset "show: dynamic" begin
    S, V = DynamicRArray(c, ones(), ones(1))
    @test stringshow(S) == "recorded 1.0"
    @test stringshow(V) == "recorded 1-element Vector{Float64}:\n 1.0"
    @test stringshow(record(S)) ==
          "record for 0-dimensional dynamic Float64 with time Int64"
    @test stringshow(record(V)) ==
          "record for 1-element dynamic Vector{Float64} with time Int64"
end

@testset "show: static" begin
    S, V = DynamicRArray(c, ones(), ones(1))
    @test stringshow(S) == "recorded 1.0"
    @test stringshow(V) == "recorded 1-element Vector{Float64}:\n 1.0"
    @test stringshow(record(S)) ==
          "record for 0-dimensional dynamic Float64 with time Int64"
    @test stringshow(record(V)) ==
          "record for 1-element dynamic Vector{Float64} with time Int64"
end

@testset "show: test" begin
    S, V, M = _testa(ones(), ones(1), ones(1, 1))
    @test stringshow(S) == "recorded 1.0"
    @test stringshow(V) == "recorded 1-element Vector{Float64}:\n 1.0"
    @test stringshow(M) == "recorded 1×1 Matrix{Float64}:\n 1.0"
    @test stringshow(record(S)) == "record for 0-dimensional Float64 with time Int64"
    @test stringshow(record(V)) == "record for 1-element Vector{Float64} with time Int64"
    @test stringshow(record(M)) == "record for 1×1 Matrix{Float64} with time Int64"
end
