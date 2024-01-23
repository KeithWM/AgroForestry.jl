using GLMakie

positions = Observable(rand(Point2f, 10))
dragging = false
idx = 1

# f = Figure()
# ax = Axis(f[1, 1], yreversed=true,
#     xautolimitmargin=(0.15, 0.15),
#     yautolimitmargin=(0.15, 0.15)
# )
fig, ax, p = scatter(Point{2,Float32}[])
p = scatter!(
    positions, color=:yellow,
    strokewidth=1, strokecolor=:black
)

on(events(fig).mousebutton, priority=2) do event
    global dragging, idx
    if event.button == Mouse.left
        if event.action == Mouse.press
            plt, i = pick(fig)
            if Keyboard.d in events(fig).keyboardstate && plt == p
                # Delete marker
                deleteat!(positions[], i)
                notify(positions)
                return Consume(true)
            elseif Keyboard.a in events(fig).keyboardstate
                # Add marker
                push!(positions[], mouseposition(ax))
                notify(positions)
                return Consume(true)
            else
                # Initiate drag
                dragging = plt == p
                idx = i
                return Consume(dragging)
            end
        elseif event.action == Mouse.release
            # Exit drag
            dragging = false
            return Consume(false)
        end
    end
    return Consume(false)
end

on(events(fig).mouseposition, priority=2) do mp
    if dragging
        positions[][idx] = mouseposition(ax)
        notify(positions)
        return Consume(true)
    end
    return Consume(false)
end

fig