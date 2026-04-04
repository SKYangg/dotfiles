
using Pkg
env = dirname(@__FILE__)
Pkg.activate(env)

Pkg.add("CSV")
Pkg.add("DataFrames")
Pkg.add("StatsBase")
Pkg.add("Distributions")

