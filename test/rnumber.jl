
c = ContinuousClock(10)

x = recorded(DynamicEntry, c, 1.0)
y = recorded(DynamicEntry, c, 1.0 + 1.0im)

@test isnum(Real, x)
@test isnum(Complex, y)
@test isnum(Complex, x + y)
@test issubtype(typeof(x), Real)
@test issubtype(typeof(y), Complex)
@test issubtype(typeof(x + y), Complex)

@test promote_type(RReal{Int}, Int) == Int
@test promote_type(RNumber{Int}, Int) == Int
@test promote_type(RReal{Float64}, Int) == Float64
@test promote_type(RNumber{Float64}, Int) == Float64
@test promote_type(RReal{Float64}, RReal{Int}) == Float64
@test promote_type(RReal{Float64}, RNumber{Int}) == Float64
@test promote_type(RNumber{Float64}, RReal{Int}) == Float64
@test promote_type(RNumber{Float64}, RNumber{Int}) == Float64

@test x + x == 2
@test y + y == 2 + 2im
@test x - x == 0
@test y - y == 0
@test x * x == 1
@test y * y == 2im
@test x / x == 1
@test y / y == 1
@test x \ x == 1
@test y \ y == 1
@test x^x == 1
@test y^y == (1 + im)^(1 + im)

@test convert(Int, x) == 1
@test convert(RNumber{Int}, x) == 1

xs = [x[1]]
ys = [y[1]]

increase!(c, 1) # t = 1
x[] = x + x
y[] += 1

@test x == 2
@test y == 2 + 1im
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 2
x[] += UInt(1)
y[] = y + 2im

@test x == 3
@test y == 2 + 3im
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 3

x[] = x - UInt(1)
y[] = y' - 1

@test x == 2
@test y == 1 - 3im
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 4
x[] = x * x
y[] = y / y

@test x == 4
@test y == 1
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 5
x[] = x^2
y[] = (y^2) * im

@test x == 16
@test y == 1im
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 6
x[] += real(y)
y[] += imag(y)

@test x == 16
@test y == 1 + 1im
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 7
x[] = 2 \ x
y[] = y^y

@test x == 8
@test y == (1 + im)^(1 + im)
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 8

x[] = exp(x)
y[] = float(y)

@test x == exp(8)
@test y == (1 + 1im)^(1 + 1im)
push!(xs, x)
push!(ys, y)

increase!(c, 1) # t = 9

x[] = x / x
y[] = y[1]' + y[1, 1]

@test x == 1
@test y == 2 * real((1 + 1im)^(1 + 1im))
push!(xs, x)
push!(ys, y)

e1 = getentries(x)
e2 = getentries(y)

@test getts(e1) == 0:9
@test getts(e2) == 0:9
@test getvs(e1) == xs
@test getvs(e2) == ys
