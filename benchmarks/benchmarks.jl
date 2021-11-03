# INSTRUCTIONS:

# Running this file is fairly straightforward:
# From the terminal call julia with this file as the first argument, as well as one of three other arguments:
# 1. A number, corresponding to the ID of a SuiteSparse: Matrix Collection matrix.
# 2. The path to an .mtx file.
# 3. The path to a file containing either of the above options on each line.

# This would look something like
# >julia benchmarks.jl 1375
# or
# >julia benchmarks.jl ~/mymtx.mtx

# CHANGING THE SHARED LIBRARY.
# Further instructions on changing the shared library programmatically can be found in the docs.
# However, simply changing the LocalPreferences.toml file will suffice for this benchmark script.

# Some options can be found further down under SETTINGS
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using SuiteSparseMatrixCollection
using MatrixMarket
using SuiteSparseGraphBLAS
using BenchmarkTools
using SparseArrays
using LinearAlgebra

BenchmarkTools.DEFAULT_PARAMETERS.samples = 10
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
const suite = BenchmarkGroup()
const ssmc = ssmc_db()

function sptimesfull(S, G)
    printstyled("\nSparse * Full\n", color=:green)
    GC.gc()
    m = rand(size(S, 2), 1000)
    m2 = GBMatrix(m)

    printstyled("\nSparseMatrixCSC:\n", bold=true)
    A = @benchmark $S * $m
    show(stdout, MIME("text/plain"), A)

    printstyled("\nGBMatrix:\n", bold=true)
    gbset(:burble, true)
    G * m2
    gbset(:burble, false)

    B = @benchmark $G * $m2
    show(stdout, MIME("text/plain"), B)

    tratio = ratio(median(A), median(B))
    color = tratio.time >= 1.0 ? :green : :red
    printstyled("\nMedian speedup over SparseArrays using $(gbget(:nthreads)) threads is: $(string(tratio))\n"; bold=true, color)
end

function sptimestranspose(S, G)
    printstyled("\nSparse * Sparse'\n", color=:green)
    GC.gc()

    printstyled("\nSparseMatrixCSC:\n", bold=true)
    A = @benchmark $S * ($S)'
    show(stdout, MIME("text/plain"), A)

    printstyled("\nGBMatrix:\n", bold=true)
    gbset(:burble, true)
    G * G'
    gbset(:burble, false)
    B = @benchmark $G * ($G)'
    show(stdout, MIME("text/plain"), B)

    tratio = ratio(median(A), median(B))
    color = tratio.time >= 1.0 ? :green : :red
    printstyled("\nMedian speedup over SparseArrays using $(gbget(:nthreads)) threads is: $(string(tratio))\n"; bold=true, color)
end

function sptimesfullwithaccum(S, G)
    printstyled("\nFull += Sparse * Full\n", color=:green)
    GC.gc()
    m = rand(size(S, 2), 1000)
    m2 = GBMatrix(m)

    printstyled("\nSparseMatrixCSC:\n", bold=true)
    A = @benchmark $S * $m
    show(stdout, MIME("text/plain"), A)

    C = GBMatrix(size(G, 1), size(m2, 2), 0.0)
    gbset(C, :sparsity_control, :full)

    printstyled("\nGBMatrix:\n", bold=true)
    gbset(:burble, true)
    mul!(C, G, m2; accum=+)
    gbset(:burble, false)
    B = @benchmark mul!($C, $G, $m2; accum=+)
    show(stdout, MIME("text/plain"), B)

    tratio = ratio(median(A), median(B))
    color = tratio.time >= 1.0 ? :green : :red
    printstyled("\nMedian speedup over SparseArrays using $(gbget(:nthreads)) threads is: $(string(tratio))\n"; bold=true, color)
end

# SETTINGS:
# run these functions for benchmarking:
const functorun = [sptimesfullwithaccum]

# run with these nthread settings, add or remove to/from vector.
const threadlist = [4,]

function singlebench(pathornum)
    x = tryparse(Int64, pathornum)
    if x !== nothing
        ssmc[x, :real] == true || throw(ArgumentError("SSMC ID must be for a matrix with real values"))
        path = joinpath(fetch_ssmc(ssmc[x, :group], ssmc[x, :name]), "$(ssmc[x, :name]).mtx")
    elseif isfile(pathornum)
        path = pathornum
    else
        throw(ErrorException("Argument is not a path or SuiteSparseMatrixCollection ID number"))
    end
    name = basename(path)
    S = convert(SparseMatrixCSC{Float64}, MatrixMarket.mmread(path))
    G = GBMatrix(S)
    gbset(G, :format, :byrow)
    diag(G)
    printstyled("Benchmarking $name:\n"; bold=true, color=:green)
    for nthreads ∈ threadlist
        printstyled("\nBenchmarking with $nthreads GraphBLAS threads\n"; bold=true, color=:blue)
        gbset(:nthreads, nthreads)
        for f ∈ functorun
            f(S, G)
        end
    end
end

if length(ARGS) != 0
    if isfile(ARGS[1])
        if splitext(ARGS[1])[2] == ".mtx"
            singlebench(ARGS[1])
        else
            singlebench.(readlines(ARGS[1]))
        end
    elseif tryparse(Int64, ARGS[1]) !== nothing
        singlebench(ARGS[1])
    else
        throw(ArgumentError("The first argument must a file with a list of SuiteSparse ID numbers or paths to MatrixMarket files"))
    end
end