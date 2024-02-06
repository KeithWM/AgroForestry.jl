using ReTest
import AgroForestry

include("AgroForestryTests.jl")

retest(AgroForestry, AgroForestryTests)