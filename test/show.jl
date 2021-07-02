using RecordedArrays: _testa

function stringshow(x)
    io = IOBuffer()
    show(io, MIME("text/plain"), x)
    return String(take!(io))
end

c = DiscreteClock(1)

@testset "show: dynamic" begin
    for A in DynamicRArray(c, ones(), ones(1))
        @test stringshow(record(A)) == "record for $(summary(A))"
    end
end

@testset "show: static" begin
    for A in StaticRArray(c, ones(1), ones(1)) # the second ones is a placaholder
        @test stringshow(record(A)) == "record for $(summary(A))"
    end
end

@testset "show: test" begin
    for A in _testa(ones(), ones(1), ones(1, 1))
        @test stringshow(record(A)) == "record for $(summary(A))"
    end
end
