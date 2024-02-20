function save(forest::AgroForest2, output::AbstractString)
    position_points = Dict(
        plant_name => positions[]
        for (plant_name, positions) in forest.positions
    )
    jldsave(output;
        img=forest.img[],
        scale=forest.scale[],
        plants=forest.plants,
        position_points=position_points
    )
end

function loadforest(forest::AgroForest2, controllers::Dict{String,Controller}, input::AbstractString)
    jldopen(input, "r") do f
        forest.img[] = f["img"]
        forest.scale[] = f["scale"]
        forest.plants = f["plants"]
        for (plant_name, points) in f["position_points"]
            forest.positions[plant_name][] = points
        end
        @show forest.positions["Rode Beuk"][]
    end
    for (plant_name, controller) in controllers
        linkcontroller!!(forest, controller, plant_name)
    end
    @show controllers["Rode Beuk"].positions
end