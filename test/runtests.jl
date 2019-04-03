using Fingerprints
const FP = Fingerprints
using Test

abstract type AAbstractType end
struct AStruct end
mutable struct AMutableStruct end
primitive type APrimitiveType 64 end

@testset "namestub" begin
    @test FP.namestub(AAbstractType)   === :AAbstractType
    @test FP.namestub(AStruct)         === :AStruct
    @test FP.namestub(AMutableStruct)  === :AMutableStruct
    @test FP.namestub(APrimitiveType)  === :APrimitiveType
    @test FP.namestub(Vector{Float64}) === :Array
    @test FP.namestub(Vector) === :Array
    @test FP.namestub(Array) === :Array
end

@testset "Kind" begin
    @test FP.Kind(AMutableStruct)      === FP.KindMutable()
    @test FP.Kind(AStruct)             === FP.KindStruct()
    @test FP.Kind(AAbstractType)       === FP.KindAbstract()
    @test FP.Kind(APrimitiveType)      === FP.KindPrimitive()
    @test FP.Kind(Vector)              === FP.KindUnionAll()
    @test FP.Kind(Union{Vector, Int})  === FP.KindUnion()
    @test FP.Kind(AbstractArray)       === FP.KindUnionAll()
    @test FP.Kind(AbstractVector{Int}) === FP.KindAbstract()
    @test FP.Kind(Vector{Int})         === FP.KindBuiltin()
    @test FP.Kind(Matrix{Int})         === FP.KindBuiltin()
    @test FP.Kind(Symbol)              === FP.KindBuiltin()
    @test FP.Kind(String)              === FP.KindBuiltin()
end

module A
    struct S
        x
        y
    end
end

module B
    struct S
        x
        y
    end
    struct T
        x
        y
    end
end

module C
    struct S
        x
        z
    end
end

@testset "Module name invariance" begin
    @test fingerprint(A.S(1,2)) === fingerprint(B.S(1,2))
    @test fingerprint(A.S(1,2)) !== fingerprint(B.T(1,2))
    @test fingerprint(A.S(1,2)) !== fingerprint(C.S(1,2))
end


struct E1 end
struct E2 end

@testset "empty structs" begin
    @test fingerprint(E1())  !== fingerprint(E2())
    @test fingerprint(E1())  !== fingerprint(E1)
    @test fingerprint(E1())  === fingerprint(E1())
    @test fingerprint("hi")  !== fingerprint(:hi)
end

@testset "mutable structs" begin
    mutable struct M1
        x
    end
    @test fingerprint(M1(1)) === fingerprint(M1(1))
    @test fingerprint(M1(1)) !== fingerprint(M1(2))
end

struct Container{T}
    inner::T
end
@testset "persistence" begin
    @test fingerprint(Container(Container("1"))) === 0x182a028725dce688
end

@test fingerprint([1,2]) != fingerprint((1,2))
@test fingerprint((1,2)) != fingerprint((a=1,b=2))
@test fingerprint((a=2,b=1)) != fingerprint((a=1,b=2))
