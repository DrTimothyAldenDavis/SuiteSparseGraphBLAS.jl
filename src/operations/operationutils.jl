function optype(atype, btype)
    #If atype is signed, optype must be signed and at least big enough.
    if atype <: Integer || btype <: Integer
        if atype <: Signed || btype <: Signed
            p = promote_type(atype, btype)
            if p <: Integer
                return signed(p)
            else
                return p
            end
        else
            return promote_type(atype, btype)
        end
    else
        return promote_type(atype, btype)
    end
end

optype(A::GBArray, B::GBArray) = optype(eltype(A), eltype(B))

function _handlectx(ctx, ctxvar, default = nothing)
    if ctx === nothing || ctx === missing
        ctx2 = get(ctxvar)
        if ctx2 !== nothing
            return something(ctx2)
        elseif ctx !== missing
            return default
        else
            throw(ArgumentError("This operation requires an operator specified by the `with` function."))
        end
    else
        return ctx
    end
end

function _handlectx(op, mask, accum, desc, defaultop = nothing)
    return (
        _handlectx(op, ctxop, defaultop),
        _handlectx(mask, ctxmask, C_NULL),
        _handlectx(accum, ctxaccum, C_NULL),
        _handlectx(desc, ctxdesc, Descriptors.NULL)
    )
end

"""
    xtype(op::GrBOp)::DataType

Determine type of the first argument to a typed operator.
"""
function xtype end

"""
    ytype(op::GrBOp)::DataType

Determine type of the second argument to a typed operator.
"""
function ytype end

"""
    ytype(op::GrBOp)::DataType

Determine type of the output of a typed operator.
"""
function ztype end