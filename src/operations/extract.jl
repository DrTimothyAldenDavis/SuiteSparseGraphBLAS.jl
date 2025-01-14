"""
    _outlength(A, I, J)
    _outlength(u, I)
Determine the size of the output for an operation like extract or range-based indexing.
"""
function _outlength(A, I, J)
    if I == ALL
        Ilen = size(A, 1)
    else
        Ilen = length(I)
    end
    if J == ALL
        Jlen = size(A, 2)
    else
        Jlen = length(J)
    end
    return Ilen, Jlen
end

function _outlength(u, I)
    if I == ALL
        wlen = size(u)
    else
        wlen = length(I)
    end
    return wlen
end

"""
    extract!(C::GBMatrix, A::GBMatOrTranspose, I, J; kwargs...)::GBMatrix
    extract!(C::GBVector, A::GBVector, I; kwargs...)::GBVector

Extract a submatrix or subvector from `A` into `C`.

# Arguments
- `C::Union{GBVector, GBMatrix}`: the submatrix or subvector extracted from `A`.
- `A::GBArray`
- `I` and `J`: A colon, scalar, vector, or range indexing A.

# Keywords
- `mask::Union{Nothing, GBArray} = nothing`: mask where
    `size(M) == (max(I), max(J))`.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Union{Nothing, Descriptor} = nothing`

# Returns
- `GBMatrix` or `GBVector`: the modified array `C`, now containing the matrix `A[I, J]` or
    `A[I]` for a vector.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `size(C) != (max(I), max(J))` or `size(C) != size(mask)`.
"""
extract!

function extract!(
    C::GBMatrix, A::GBMatOrTranspose, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    I, ni = idx(I)
    J, nj = idx(J)
    I isa Number && (I = UInt64[I])
    J isa Number && (J = UInt64[J])
    mask === nothing && (mask = C_NULL)
    desc = _handledescriptor(desc; in1 = A)
    libgb.GrB_Matrix_extract(C, mask, getaccum(accum, eltype(C)), parent(A), I, ni, J, nj, desc)
    return C
end

function extract!(
    C::GBMatrix, A::GBMatOrTranspose, ::Colon, J;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract!(C, A, ALL, J; mask, accum, desc)
end

function extract!(
    C::GBMatrix, A::GBMatOrTranspose, I, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract!(C, A, I, ALL; mask, accum, desc)
end

function extract!(
    C::GBMatrix, A::GBMatOrTranspose, ::Colon, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract!(C, A, ALL, ALL; mask, accum, desc)
end

"""
    extract(A::GBMatOrTranspose, I, J; kwargs...)::GBMatrix
    extract(A::GBVector, I; kwargs...)::GBVector

    Extract a submatrix or subvector from `A`

# Arguments
- `A::GBArray`: the array being indexed.
- `I` and `J`: A colon, scalar, vector, or range indexing A.

# Keywords
- `mask::Union{Nothing, GBArray} = nothing`: mask where
    `size(M) == (max(I), max(J))`.
- `accum::Union{Nothing, AbstractBinaryOp} = nothing`: binary accumulator operation
    where `C[i,j] = accum(C[i,j], T[i,j])` where T is the result of this function before accum is applied.
- `desc::Descriptor = nothing`

# Returns
- `GBMatrix`: the submatrix `A[I, J]`.

# Throws
- `GrB_DIMENSION_MISMATCH`: If `(max(I), max(J)) != size(mask)`.
"""
extract

function extract(
    A::GBMatOrTranspose, I, J;
    mask = nothing, accum = nothing, desc = nothing
)
    Ilen, Jlen = _outlength(A, I, J)
    C = similar(A, Ilen, Jlen)
    return extract!(C, A, I, J; mask, accum, desc)
end

function extract(
    A::GBMatOrTranspose, ::Colon, J;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract(A, ALL, J; mask, accum, desc)
end

function extract(
    A::GBMatOrTranspose, I, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract(A, I, ALL; mask, accum, desc)
end

function extract(
    A::GBMatOrTranspose, ::Colon, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract(A, ALL, ALL; mask, accum, desc)
end

function Base.getindex(
    A::GBMatOrTranspose, ::Colon, j;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract(A, ALL, j; mask, accum, desc)
end

function extract!(
    w::GBVector, u::GBVector, I;
    mask = nothing, accum = nothing, desc = nothing
)
    I, ni = idx(I)
    desc = _handledescriptor(desc)
    mask === nothing && (mask = C_NULL)
    libgb.GrB_Matrix_extract(w, mask, getaccum(accum, eltype(w)), u, I, ni, UInt64[1], 1, desc)
    return w
end

function extract!(
    w::GBVector, u::GBVector, ::Colon;
    mask = nothing, accum = nothing, desc = nothing
)
    return extract!(w, u, ALL; mask, accum, desc)
end

function extract(
    u::GBVector, I;
    mask = nothing, accum = nothing, desc = nothing
)
    wlen = _outlength(u, I)
    w = similar(u, wlen)
    return extract!(w, u, I; mask, accum, desc)
end

function extract(u::GBVector, ::Colon; mask = nothing, accum = nothing, desc = nothing)
    extract(u, ALL; mask, accum, desc)
end
