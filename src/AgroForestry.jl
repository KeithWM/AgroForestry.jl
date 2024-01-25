module AgroForestry

import CSV
using GLMakie
using Makie.Colors
using DataFrames
using FileIO: load
import Base.convert
using DataFrames: DataFrame
import Tables

export createplot

include("PlantSpecs.jl")
include("PlantPlotting.jl")
include("TablesInterface.jl")

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

    # fig, ax, p = scatter(Point{2,Float32}[])
    fig = Figure()
    img = load(background)
    ax, _img = image(
        fig[1, 1], rotr90(img),
        axis=(aspect=DataAspect(),)
    )
    scale!(_img, scale, scale)
    limits!(ax, (0, size(img, 2) * scale), (-50, size(img, 1) * scale))
    ax.xrectzoom = false
    ax.yrectzoom = false

    menupoints = arrange(plants)

    dms = Dict(
        plant.name => plantmarkers(fig, ax, plant, menupoint)
        for (plant, menupoint) in zip(plants, menupoints)
    )

    @show xs = Makie.pick_sorted(Makie.get_scene(fig), menupoints[2], 10)
    for x in xs
        @show x |> typeof
    end
    return fig, dms
end

Base.@kwdef mutable struct DraggableMarkers1
    positions::Observable{Vector{Point{2,Float32}}}
    ps::Vector{Plot}
    idx::Int
    dragging::Bool
end

function plantmarkers(fig::Figure, ax::Axis, plant::PlantSpecs.Plant, menupoint::Point2f)
    positions = Observable([menupoint])
    dm = createmarkers(plant, positions)
    plantmarkers(fig, ax, dm, positions)
end

function createmarkers(plant::PlantSpecs.Plant, positions::Observable)
    return DraggableMarkers1(
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

function plantmarkers(fig::Figure, ax::Axis, dm::DraggableMarkers1, positions::Observable)
    on(events(fig).mousebutton, priority=2) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                return handlepress(fig, ax, positions, dm)
            elseif event.action == Mouse.release
                return handlerelease(fig, ax, positions, dm)
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

function handlerelease(fig::Figure, ax::Axis, positions::Observable, dm::DraggableMarkers1)
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

function handlepress(fig::Figure, ax::Axis, positions::Observable, dm::DraggableMarkers1)
    plt, i = pick(fig, events(fig).mouseposition[], 10)
    xs = Makie.pick_sorted(Makie.get_scene(fig), events(fig).mouseposition[], 10)
    found = findfirst(plti -> isa(first(plti), Scatter), xs)
    if !isnothing(found)
        plt, i = xs[found]

        if i == 1 && plt in dm.ps
            # Add marker and drag it immediately
            dm.dragging = plt in dm.ps
            push!(positions[], mouseposition(ax))
            push!(dm.ps[2].text[], dm.ps[2].text[][1])
            notify(dm.positions)
            notify(dm.ps[2].text)
            dm.idx = length(positions[])
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
