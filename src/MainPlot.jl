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

function linkcontroller(plant::PlantSpecs.Plant, forest::AgroForest2)
    points = map(x -> x / u"m", positions)
    controller = Controller(
        name=plant.name,
        positions=points,
        ps=[
            scatter!(
                lift(points); markerspace=:data, makekwargs(plant)...
            ),
            text!(
                lift(points);
                text=lift(p -> [showname(plant) for _ in p], points),
                align=(:center, :center), visible=true, fontsize=20,
            ),
        ],
        idx=0,
        dragging=false,
        offset=Point2f(0, 0),
    )
    return controller
end

function plantmarkers(fig::Figure, ax::Axis, dm::Controller)
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
            dm.positions[][dm.idx] = mouseposition(ax) - dm.offset
            notify(dm.positions)
            return Consume(true)
        end
        return Consume(false)
    end

    return dm
end

function handlerelease(fig::Figure, ax::Axis, dm::Controller)
    # Exit drag
    if dm.dragging && dm.positions[][dm.idx][2] < 0
        # Delete marker
        dm.dragging = false
        deleteat!(dm.positions[], dm.idx)
        notify(dm.positions)
        return Consume(true)
    else
        dm.dragging = false
        return Consume(false)
    end
end

function handlepress(fig::Figure, ax::Axis, dm::Controller)
    plt, i = pick(fig, events(fig).mouseposition[], 10)
    for plt_i in Makie.pick_sorted(Makie.get_scene(fig), events(fig).mouseposition[], 10)
        r = handlepress(fig, ax, dm, plt_i...)
        r === nothing || return r
        @debug "Found nothing"
    end
end
handlepress(fig::Figure, ax::Axis, dm::Controller, plt::Any, i::Integer) = nothing
handlepress(fig::Figure, ax::Axis, dm::Controller, plt::Text, i::Integer) = nothing

function handlepress(fig::Figure, ax::Axis, dm::Controller, plt::DraggablePlot, i::Integer)
    if i == 1 && plt in dm.ps
        @debug "Add marker and drag it immediately"
        # Add marker and drag it immediately
        dm.dragging = plt in dm.ps
        dm.offset = Point2f(0, 0)
        push!(dm.positions[], mouseposition(ax))
        notify(dm.positions)
        dm.idx = length(dm.positions[])
        @show dm.positions
        @show dm.ps[1].positions
        return Consume(dm.dragging)
    else
        @debug "Initiate drag"
        # Initiate drag
        dm.dragging = plt in dm.ps
        if dm.dragging
            dm.offset = mouseposition(ax) - dm.positions[][i]
        end
        dm.idx = i
        return Consume(dm.dragging)
    end
end
