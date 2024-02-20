DraggablePlot = Union{Scatter}

Base.@kwdef mutable struct Controller
    name::String
    positions::Observable{Vector{Point{2,Float32}}}
    idx::Int
    dragging::Bool
    offset::Point{2,Float32}
end

Base.@kwdef mutable struct Viewer
    name::String
    ps::Vector{Plot}
end

function linkcontroller!(forest::AgroForest2, plant_name::String)
    controller = Controller(
        name=plant_name,
        positions=Observable(Point2f[]),
        idx=0,
        dragging=false,
        offset=Point2f(0, 0),
    )
    linkcontroller!!(forest, controller, plant_name)
    return controller
end

function linkcontroller!!(forest::AgroForest2, controller::Controller, plant_name::String)
    empty!(controller.positions[])
    controller.positions[] = map(x -> x / u"m", forest.positions[plant_name][])
    forest.positions[plant_name] = lift(x -> x * u"m", controller.positions)
    return forest
end

function createviewer(forest::AgroForest2, fig::Figure, ax::Axis, dm::Controller, plant::PlantSpecs.Plant)
    points = lift(x -> x / u"m", forest.positions[dm.name])
    viewer = Viewer(
        name=dm.name,
        ps=[
            scatter!(
                points; markerspace=:data, makekwargs(plant)...
            ),
            text!(
                points;
                text=lift(p -> [showname(plant) for _ in p], points),
                align=(:center, :center), visible=true, fontsize=20,
            ),
        ],
    )

    on(events(fig).mousebutton, priority=2) do event
        if event.button == Mouse.left
            if event.action == Mouse.press
                return handlepress(fig, ax, dm, viewer)
            elseif event.action == Mouse.release
                return handlerelease(fig, ax, dm)
            end
        end
        return Consume(false)
    end

    on(events(fig).mouseposition, priority=2) do mp
        if dm.dragging
            dm.positions[][dm.idx] = mouseposition(ax) - dm.offset
            notify(dm.positions)
            return Consume(true)
        end
        return Consume(false)
    end

    return viewer
end

function handlerelease(fig::Figure, ax::Axis, dm::Controller)
    # Exit drag
    if dm.dragging && dm.positions[][dm.idx][2] < 0
        # Delete marker
        @debug "Delete marker"
        dm.dragging = false
        deleteat!(dm.positions[], dm.idx)
        notify(dm.positions)
        return Consume(true)
    else
        dm.dragging = false
        return Consume(false)
    end
end

function handlepress(fig::Figure, ax::Axis, dm::Controller, v::Viewer)
    plt, i = pick(fig, events(fig).mouseposition[], 10)
    for plt_i in Makie.pick_sorted(Makie.get_scene(fig), events(fig).mouseposition[], 10)
        r = handlepress(ax, dm, v, plt_i...)
        r === nothing || return r
        @debug "Found nothing"
    end
end
handlepress(ax::Axis, dm::Controller, v::Viewer, plt::Any, i::Integer) = nothing
handlepress(ax::Axis, dm::Controller, v::Viewer, plt::Text, i::Integer) = nothing

function handlepress(ax::Axis, dm::Controller, v::Viewer, plt::DraggablePlot, i::Integer)
    if i == 1 && plt in v.ps
        @debug "Add marker and drag it immediately"
        # Add marker and drag it immediately
        dm.dragging = plt in v.ps
        dm.offset = Point2f(0, 0)
        push!(dm.positions[], mouseposition(ax))
        notify(dm.positions)
        dm.idx = length(dm.positions[])
        @show dm.positions
        @show v.ps[1].positions
        return Consume(dm.dragging)
    else
        @debug "Initiate drag"
        # Initiate drag
        dm.dragging = plt in v.ps
        if dm.dragging
            dm.offset = mouseposition(ax) - dm.positions[][i]
        end
        dm.idx = i
        return Consume(dm.dragging)
    end
end
