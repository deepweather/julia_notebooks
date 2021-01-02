using BenchmarkTools
using Libdl
using PyCall
using Conda

a = rand(10^7)
C_code = """
#include <stddef.h>
double c_sum(size_t n, double *X) {
    double s = 0.0;
    for (size_t i = 0; i < n; ++i) {
        s += X[i];
    }
    return s;
}
"""
const Clib = tempname()
d = Dict()

open(`gcc -fPIC -O3 -msse3 -xc -shared -o $(Clib * "." * Libdl.dlext) -`, "w") do f
    print(f, C_code) 
end

c_sum(X::Array{Float64}) = ccall(("c_sum", Clib), Float64, (Csize_t, Ptr{Float64}), length(X), X)

if c_sum(a) ≈ sum(a)
    c_bench = @benchmark c_sum($a)
    d["C"] = minimum(c_bench.times) / 1e6 # in millisecods
end

pysum = pybuiltin("sum")

if pysum(a) ≈ sum(a)
    py_list_bench = @benchmark $pysum($a)
    d["Python built-in"] = minimum(py_list_bench.times) / 1e6
end
    

numpy_sum = pyimport("numpy")["sum"]
apy_numpy = PyObject(a)

if numpy_sum(apy_numpy) ≈ sum(a)
    py_numpy_bench = @benchmark $numpy_sum($apy_numpy)
    d["Python numpy"] = minimum(py_numpy_bench.times) / 1e6
end

j_bench = @benchmark sum($a)
d["Julia build-in"] = minimum(j_bench.times) / 1e6

println(d)

