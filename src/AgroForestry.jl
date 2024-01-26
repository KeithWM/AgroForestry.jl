module AgroForestry

import CSV
using GLMakie
using Makie.Colors
using DataFrames
using FileIO: load
import Base.convert
using DataFrames: DataFrame
using ConcreteStructs: @concrete
import Tables

export createplot

include("PlantSpecs.jl")

left(x::Pair) = first(x)
right(x::Pair) = last(x)

Base.@kwdef mutable struct DraggableMarkers
    name::String
    positions::Observable{Vector{Point{2,Float32}}}
    ps::Vector{Plot}
    idx::Int
    dragging::Bool
end

Base.@kwdef @concrete mutable struct AgroForest3
    img::Matrix{<:ColorTypes.RGBA{<:Any}}
    scale::Float64
    plants::Vector{PlantSpecs.Plant}
    positions::Vector{Pair{String,Observable{Vector{Point{2,Float32}}}}}
end

include("PlantPlotting.jl")
# include("TablesInterface.jl")

function loaddata(filepath::AbstractString)
    df = filepath |> CSV.File |> DataFrame
    return df[1:24, :]
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
    menupoints = arrange(plants)

    forest = AgroForest3(
        img=img,
        scale=scale,
        plants=plants,
        positions=[plant.name => [p] for (plant, p) in zip(plants, menupoints)]
    )

    fig = Figure()
    ax, _img = image(
        fig[1, 1], rotr90(img),
        axis=(aspect=DataAspect(),)
    )
    scale!(_img, forest.scale, forest.scale)
    limits!(ax, (0, size(img, 2) * forest.scale), (-50, size(img, 1) * forest.scale))
    ax.xrectzoom = false
    ax.yrectzoom = false

    dms = Dict(
        plant.name => plantmarkers(fig, ax, plant, right(poss))
        for (plant, poss) in zip(forest.plants, forest.positions)
    )

    return fig, dms
end

function plantmarkers(fig::Figure, ax::Axis, plant::PlantSpecs.Plant, poss::Observable)
    dm = createmarkers(plant, poss)
    plantmarkers(fig, ax, dm)
end

function createmarkers(plant::PlantSpecs.Plant, positions::Observable)
    return DraggableMarkers(
        name=plant.name,
        positions=positions,
        ps=[
            scatter!(
                positions; markerspace=:data, makekwargs(plant)...
            ),
            text!(
                positions;
                text=[showname(plant) for _ in positions[]], align=(:center, :center), visible=true, fontsize=10,
            ),
        ],
        idx=0,
        dragging=false,
    )
end

function plantmarkers(fig::Figure, ax::Axis, dm::DraggableMarkers)
    on(events(fig).mousebutton, priority=2) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                return handlepress(fig, ax, dm)
            elseif event.action == Mouse.release
                return handlerelease(fig, ax, dm)
            end
        end
        return Consume(false)
    end

    on(events(fig).mouseposition, priority=2) do mp
        if dm.dragging
            dm.positions[][dm.idx] = mouseposition(ax)
            notify(dm.positions)
            return Consume(true)
        end
        return Consume(false)
    end

    return dm
end

function handlerelease(fig::Figure, ax::Axis, dm::DraggableMarkers)
    # Exit drag
    if dm.dragging && dm.positions[][dm.idx][2] < 0
        # Delete marker
        dm.dragging = false
        deleteat!(dm.positions[], dm.idx)
        deleteat!(dm.ps[2].text[], dm.idx)
        notify(dm.positions)
        notify(dm.ps[2].text)
        return Consume(true)
    else
        dm.dragging = false
        return Consume(false)
    end
end

function handlepress(fig::Figure, ax::Axis, dm::DraggableMarkers)
    plt, i = pick(fig, events(fig).mouseposition[], 10)
    xs = Makie.pick_sorted(Makie.get_scene(fig), events(fig).mouseposition[], 10)
    found = findfirst(plti -> isa(first(plti), Scatter), xs)
    if !isnothing(found)
        plt, i = xs[found]

        if i == 1 && plt in dm.ps
            # Add marker and drag it immediately
            dm.dragging = plt in dm.ps
            push!(dm.positions[], mouseposition(ax))
            push!(dm.ps[2].text[], dm.ps[2].text[][1])
            notify(dm.positions)
            notify(dm.ps[2].text)
            dm.idx = length(dm.positions[])
            return Consume(dm.dragging)
        else
            # Initiate drag
            dm.dragging = plt in dm.ps
            dm.idx = i
            return Consume(dm.dragging)
        end
    end
end

end # module AgroForestry
