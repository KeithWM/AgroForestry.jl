module AgroForestryTests

using ReTest
using AgroForestry
using AgroForestry.PlantSpecs: Plant, PlantSize, SizeRange, MonthRange
using AgroForestry.GLMakie
import AgroForestry.DataFrames

default = Dict(
    :name => "Naam",
    :latin => "Latijn",
    :size => PlantSize(SizeRange(10, 15), SizeRange(5, 10)),
    :flowering => MonthRange(4, 5),
    :harvest => MonthRange(7, 8),
    :sun => 1,
    :moist => 1
)

@testset "Save" begin
    fig = Figure()
    ax = Axis(fig[1, 1])
    plant = Plant(; default...)
    positions = Observable([Point2f(0, 1), Point2f(1, 2)])
    dm = AgroForestry.createmarkers(plant, positions)
    df = DataFrames.DataFrame(dm)
    println(df)

    plant2 = Plant(; default..., name="Second")
    positions2 = Observable([Point2f(20, 21), Point2f(21, 22), Point2f(21, 23)])
    dm2 = AgroForestry.createmarkers(plant2, positions2)
    markerdict = Dict("Zeroth" => dm, "Second" => dm2)
    df2 = DataFrames.DataFrame(markerdict)
    println(df2)
end


end