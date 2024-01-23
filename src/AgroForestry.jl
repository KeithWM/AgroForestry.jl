module AgroForestry

import CSV
using GLMakie
using Makie.Colors
using DataFrames
using FileIO: load
import Base.convert

export createplot

include("PlantSpecs.jl")

function loaddata(filepath::AbstractString)
    df = filepath |> CSV.File |> DataFrame
    return df[1:3, :]
end

function showname(plant::PlantSpecs.Plant)
    return plant.name
end
function color(m::PlantSpecs.MonthRange)
    return color(m.start, m.finish)
end
color(s::Int, f::Int) = Makie.Colors.HSV((s + f) * 15, 0.8, 0.8)
color(::Missing, ::Missing) = Makie.Colors.HSV(0, 0, 0)
mean(sr::PlantSpecs.SizeRange) = (sr.start + sr.finish) / 2

function makekwargs(plant::PlantSpecs.Plant, scale::Float64)
    return Dict(
        :color => color(plant.flowering),
        :strokewidth => mean(plant.size.height) / 10,
        :strokecolor => color(plant.harvest),
        :markersize => mean(plant.size.width),
    )
end

function createplot(filepath::AbstractString, background::AbstractString, scale::Float64)
    df = loaddata(filepath)
    plants = [
        PlantSpecs.Plant(row)
        for row in eachrow(df)
    ]

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

    dms = [
        plantmarkers(fig, ax, plant, Point2f(0, i), scale)
        for (i, plant) in enumerate(plants)
    ]

    fig
end

Base.@kwdef mutable struct DraggableMarkers2
    positions::Observable{Vector{Point{2,Float32}}}
    p::Plot
    idx::Int
    dragging::Bool
end

function plantmarkers(fig::Figure, ax::Axis, plant::PlantSpecs.Plant, menupoint::Point2f, scale::Float64)
    positions = Observable([menupoint])
    dm = DraggableMarkers2(
        positions=positions,
        p=scatter!(
            positions; markerspace=:data, makekwargs(plant, scale)...
        ),
        idx=0,
        dragging=false,
    )
    t = text!(
        positions;
        text=showname(plant), align=(:center, :center), visible=true, fontsize=6,
    )

    on(events(fig).mousebutton, priority=2) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                plt, i = pick(fig, events(fig).mouseposition[], 2)
                if Keyboard.d in events(fig).keyboardstate && plt == dm.p
                    # Delete marker
                    deleteat!(dm.positions[], i)
                    notify(dm.positions)
                    return Consume(true)
                elseif Keyboard.a in events(fig).keyboardstate
                    # Add marker
                    push!(positions[], mouseposition(ax))
                    notify(dm.positions)
                    return Consume(true)
                else
                    # Initiate drag
                    dm.dragging = plt == dm.p
                    dm.idx = i
                    return Consume(dm.dragging)
                end
            elseif event.action == Mouse.release
                # Exit drag
                dm.dragging = false
                return Consume(false)
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


end # module AgroForestry
