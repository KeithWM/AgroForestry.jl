function maketable(forest::AgroForest2, ax::Axis)
    n = length(forest.plants)
    hidedecorations!(ax)
    for (i, plant) in enumerate(sort(forest.plants; by=p -> lowercase(p.latin)))
        anchor = getposition(i - 1, n / 3)
        text!(
            ax, anchor;
            text="$(showname(plant; sep=" ")): ",
            align=(:right, :center), visible=true, fontsize=12,
        )
        text!(
            ax, anchor;
            text=lift(string ∘ length, forest.positions[plant.name]),
            align=(:left, :center), visible=true, fontsize=12,
        )
    end
    limits!(ax, (-1, 2.5), (-n / 3, 1))
    ax.xrectzoom = false
    ax.yrectzoom = false
    ax.xzoomlock = true
    ax.yzoomlock = true
    return nothing
end

function getposition(i, n)
    xy = divrem(i, n |> ceil |> Int)
    return xy[1], -xy[2]
end