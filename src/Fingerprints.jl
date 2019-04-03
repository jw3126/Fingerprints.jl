module Fingerprints
export fingerprint

function namestub(T::Type)::Symbol
   T.name.name
end

function namestub(T::UnionAll)::Symbol
    namestub(T.body)
end

abstract type Kind end
struct KindStruct <: Kind end
struct KindMutable <: Kind end
struct KindAbstract <: Kind end
struct KindPrimitive <: Kind end
struct KindBuiltin <: Kind end
struct KindUnionAll <: Kind end
struct KindUnion <: Kind end

@generated function Kind(::Type{T}) where {T}
    K = if T isa UnionAll
        KindUnionAll
    elseif T isa Union
        KindUnion
    elseif T.abstract
        KindAbstract
    elseif T <: Array
        KindBuiltin
    elseif T <: Symbol
        KindBuiltin
    elseif T <: String
        KindBuiltin
    elseif T <: Tuple
        KindBuiltin
    elseif isempty(fieldnames(T)) && (sizeof(T) > 0)
        KindPrimitive
    elseif T.mutable
        KindMutable
    else
        KindStruct
    end
    :($K())
end

function fingerprint(::Type{O}, h=zero(UInt64))::UInt64 where {O}
    hash(namestub(O), h)
end

function fingerprint(o, h=zero(UInt64))::UInt64
    _fingerprint(o, h, Kind(typeof(o)))
end

function _fingerprint(o, h, ::Union{KindPrimitive})
    hash(o, h)
end

function _fingerprint(o::Union{Symbol, String}, h, ::KindBuiltin)
    h = fingerprint(typeof(o), h)
    hash(o, h)
end

function _fingerprint(o::Union{Tuple,Array}, h, ::KindBuiltin)
    h = fingerprint(typeof(o), h)
    for x in o
        h = fingerprint(x, h)
    end
    h
end

function _fingerprint_fieldnames_impl(T)
    ret = quote
        salt = one(UInt64)
        h = fingerprint(salt, h)
        h = fingerprint($T, h)
    end
    for s in fieldnames(T)
        ex = :(
            h = fingerprint($(QuoteNode(s)), h);
            h = fingerprint(o.$s, h))
        push!(ret.args, ex)
    end
    push!(ret.args, :h)
    ret
end

@generated function _fingerprint(o, h, ::Union{KindStruct, KindMutable})
    _fingerprint_fieldnames_impl(o)
end

end # module
