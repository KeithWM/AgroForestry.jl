module AgroForestry

import CSV
using GLMakie
using Makie.Colors
using Makie.MakieCore: Text
using DataFrames
using JLD2: jldsave, jldopen
using FileIO: load
import Base.convert
using DataFrames: DataFrame
using ConcreteStructs: @concrete
using Unitful: Quantity, 𝐋, FreeUnits, m, @u_str
using UnitfulAngles: °
import Tables

export createplot

left(x::Pair) = first(x)
right(x::Pair) = last(x)

MeterType = Quantity{Float64,𝐋}

include("PlantSpecs.jl")

Base.@kwdef @concrete mutable struct AgroForest2
    img::Observable{Matrix}
    scale::Observable{MeterType}
    plants::Vector{PlantSpecs.Plant}
    positions::Dict{String,Observable{Vector{Point{2,MeterType}}}}
end

include("PlantPlotting.jl")
include("MainPlot.jl")
include("Buttons.jl")
include("Table.jl")
# include("TablesInterface.jl")
include("FileIO.jl")

function loaddata(filepath::AbstractString)
    df = filepath |> CSV.File |> DataFrame
    return df
end

function arrange(plants::AbstractVector{PlantSpecs.Plant}; n_rows=4::Int)
    n = length(plants)
    n_cols = div(n - 1, n_rows) + 1
    is = mod1.(1:2:2*n, 2 * n_rows - 1)
    js = div.((1:2:2*n) .- 1, 2 * n_rows - 1) .+ 1
    staggered = Point2f.(js * 12, -is * 8)
    return staggered
end

function createplot(filepath::AbstractString, background::AbstractString, scale_unitless::Float64)
    createplot(filepath, background, scale_unitless * u"1.0m")
end

function createplot(filepath::AbstractString, background::AbstractString, scale::MeterType)
    df = loaddata(filepath)
    plants = [
        PlantSpecs.Plant(row)
        for row in eachrow(df)
        if !ismissing(row["Wetenschappelijke naam"]) && !ismissing(row["Number/ha"])
    ]
    sort!(plants; by=p -> p.size.width.finish, rev=true)
    img = load(background)

    createplot(img, scale, plants)
end

function createplot(img::Matrix, scale::MeterType, plants::Vector{PlantSpecs.Plant})

    forest = AgroForest2(
        img=Observable{}(img),
        scale=Observable{}(scale),
        plants=plants,
        positions=Dict(plant.name => Observable{}(Point2{MeterType}[]) for plant in plants),
    )
    fig = Figure(; size=(1200, 675) .* 2 ./ 3)
    ax, _img = image(
        fig[1:2, 1], lift(i -> rotr90(i), forest.img),
        axis=(aspect=DataAspect(),)
    )
    fig[1, 2] = buttongrid = GridLayout(tellheight=false)
    tableaxis = Axis(fig[2, 2])
    scale!(_img, forest.scale[] / u"m", forest.scale[] / u"m")
    limits!(ax, (0, size(forest.img[], 2) * forest.scale[] / u"m"), (-60, size(forest.img[], 1) * forest.scale[] / u"m"))
    ax.xrectzoom = false
    ax.yrectzoom = false

    controllers = Dict(
        plant.name => linkcontroller!(forest, plant.name)
        for plant in forest.plants
    )
    menupositions = Dict(
        plant.name => position
        for (plant, position) in zip(plants, arrange(plants))
    )
    viewers = Dict(
        plant.name => createviewer(forest, fig, ax, controllers[plant.name], plant, menupositions[plant.name])
        for plant in forest.plants
    )
    buttons = makebuttons(forest, controllers, buttongrid)
    table = maketable(forest, tableaxis)

    return fig, forest, controllers, viewers, buttons
end

end # module AgroForestry