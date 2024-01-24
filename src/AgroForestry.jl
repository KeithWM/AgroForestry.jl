module AgroForestry

import CSV
using GLMakie
using Makie.Colors
using DataFrames
using FileIO: load
import Base.convert

export createplot

include("PlantSpecs.jl")
include("TreeShape.jl")
export maketree

function loaddata(filepath::AbstractString)
    df = filepath |> CSV.File |> DataFrame
    return df[1:6, :]
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
    treestring = "m 61.097143,135.77143 c 11.258232,-8.18373 8.636684,-18.3484 -3.243316,-10.99412 1.697144,-11.31428 -5.808113,-19.8 -11.465257,-3.39428 -1.697143,-16.40572 -11.672627,-10.3156 -9.975486,0.99869 -10.74857,-9.05144 -13.218798,-5.84458 -6.430228,7.16685 -11.628673,-1.47308 -13.577141,10.18286 -2.262857,14.70857 -9.051427,10.74857 -0.452914,12.22011 8.598516,4.30012 -1.13143,14.14284 7.599827,14.23743 10.428398,1.79172 9.051429,11.87999 8.127371,-2.13184 8.127371,-2.13184 11.880001,8.48572 11.890067,-2.18373 6.222859,-12.44571 z"
    treeshape = BezierPath(treestring, fit=true, flipy=true)
    return Dict(
        :marker => treeshape,
        :color => color(plant.flowering),
        :strokewidth => mean(plant.size.height) / 10,
        :strokecolor => color(plant.harvest),
        :markersize => mean(plant.size.width),
    )
end

function arrange(plants::AbstractVector{PlantSpecs.Plant}; n_rows=3::Int)
    n_cols = (length(plants) + 1) ÷ n_rows
    map(1:length(plants)) do n
        i, j = fldmod1(n, n_rows)
        ii = mod(j, 2) == 1 ? i : n_cols + 1 - i
        Point2f(ii * 15, -j * 15)
    end
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

    dms = [
        plantmarkers(fig, ax, plant, menupoint, scale)
        for (plant, menupoint) in zip(plants, menupoints)
    ]

    @show xs = Makie.pick_sorted(Makie.get_scene(fig), menupoints[2], 10)
    for x in xs
        @show x |> typeof
    end
    dms
    return fig
end

Base.@kwdef mutable struct DraggableMarkers1
    positions::Observable{Vector{Point{2,Float32}}}
    ps::Vector{Plot}
    idx::Int
    dragging::Bool
end

function plantmarkers(fig::Figure, ax::Axis, plant::PlantSpecs.Plant, menupoint::Point2f, scale::Float64)
    positions = Observable([menupoint])
    dm = DraggableMarkers1(
        positions=positions,
        ps=[
            scatter!(
                positions; markerspace=:data, makekwargs(plant, scale)...
            ),
            text!(
                positions;
                text=[showname(plant)], align=(:center, :center), visible=true, fontsize=10,
            ),
        ],
        idx=0,
        dragging=false,
    )

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
