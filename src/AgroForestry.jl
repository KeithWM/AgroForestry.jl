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
import Tables

export createplot

left(x::Pair) = first(x)
right(x::Pair) = last(x)

include("PlantSpecs.jl")

Base.@kwdef @concrete mutable struct AgroForest5
    img::Observable{Matrix}
    scale::Observable{Float64}
    plants::Vector{PlantSpecs.Plant}
    positions::Dict{String,Observable{Vector{Point{2,Float32}}}}
end

include("PlantPlotting.jl")
include("MainPlot.jl")
include("Buttons.jl")
include("TablesInterface.jl")
include("FileIO.jl")

function loaddata(filepath::AbstractString)
    df = filepath |> CSV.File |> DataFrame
    return df[1:findfirst(ismissing.(df[!, :Naam]))-1, :]
end

function arrange(plants::AbstractVector{PlantSpecs.Plant}; n_rows=3::Int)
    n = length(plants)
    n_cols = div(n - 1, n_rows) + 1
    is = mod1.(1:2:2*n, 2 * n_rows - 1)
    js = div.((1:2:2*n) .- 1, 2 * n_rows - 1) .+ 1
    staggered = Point2f.(js * 16, -is * 8)
    return staggered
end

function createplot(filepath::AbstractString, background::AbstractString, scale::Float64)
    df = loaddata(filepath)
    plants = [
        PlantSpecs.Plant(row)
        for row in eachrow(df)
    ]
    sort!(plants; by=p -> p.size.width.finish, rev=true)
    img = load(background)
    points = Dict(
        plant.name => [position]
        for (plant, position) in zip(plants, arrange(plants))
    )

    createplot(img, scale, plants, points)
end

function createplot(img::Matrix, scale::Number, plants::Vector{PlantSpecs.Plant}, points::Dict{String,<:Vector})
    @show points
    forest = AgroForest5(
        img=Observable{}(img),
        scale=Observable{}(scale),
        plants=plants,
        positions=points
    )
    fig = Figure(; size=(1200, 675))
    ax, _img = image(
        fig[1, 1], rotr90(forest.img[]),
        axis=(aspect=DataAspect(),)
    )
    # fig[1, 2] = buttongrid = GridLayout(width=15)
    fig[1, 2] = buttongrid = GridLayout(tellheight=false)
    scale!(_img, forest.scale[], forest.scale[])
    limits!(ax, (0, size(forest.img[], 2) * forest.scale[]), (-50, size(forest.img[], 1) * forest.scale[]))
    ax.xrectzoom = false
    ax.yrectzoom = false

    dms = Dict(
        plant.name => plantmarkers(fig, ax, plant, forest.positions[plant.name])
        for plant in forest.plants
    )
    buttons = makebuttons(forest, buttongrid)

    return fig, forest
end

end # module AgroForestry