DraggablePlot = Union{Scatter}

Base.@kwdef mutable struct DraggableMarkers1
    name::String
    positions::Observable{Vector{Point{2,Float32}}}
    ps::Vector{Plot}
    idx::Int
    dragging::Bool
end

function plantmarkers(fig::Figure, ax::Axis, plant::PlantSpecs.Plant, poss::Observable)
    dm = createmarkers(plant, poss)
    plantmarkers(fig, ax, dm)
end

function createmarkers(plant::PlantSpecs.Plant, positions::Observable)
    return DraggableMarkers1(
        name=plant.name,
        positions=positions,
        ps=[
            scatter!(
                positions; markerspace=:data, makekwargs(plant)...
            ),
            text!(
                positions;
                text=[showname(plant) for _ in positions[]], align=(:center, :center), visible=true, fontsize=20,
            ),
        ],
        idx=0,
        dragging=false,
    )
end

function plantmarkers(fig::Figure, ax::Axis, dm::DraggableMarkers1)
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

function handlerelease(fig::Figure, ax::Axis, dm::DraggableMarkers1)
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

function handlepress(fig::Figure, ax::Axis, dm::DraggableMarkers1)
    plt, i = pick(fig, events(fig).mouseposition[], 10)
    # found = findfirst(plti -> isa(first(plti), Scatter), xs)
    for plt_i in Makie.pick_sorted(Makie.get_scene(fig), events(fig).mouseposition[], 10)
        r = handlepress(fig, ax, dm, plt_i...)
        r === nothing || return r
        @debug "Found nothing"
    end
end
handlepress(fig::Figure, ax::Axis, dm::DraggableMarkers1, plt::Any, i::Integer) = nothing
handlepress(fig::Figure, ax::Axis, dm::DraggableMarkers1, plt::Text, i::Integer) = nothing

function handlepress(fig::Figure, ax::Axis, dm::DraggableMarkers1, plt::DraggablePlot, i::Integer)
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
