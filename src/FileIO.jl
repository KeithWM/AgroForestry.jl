function save(forest::AgroForest3, output::AbstractString)
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

function loadforest(forest::AgroForest3, input::AbstractString)
    jldopen(input, "r") do f
        @show f["position_points"]
        forest.img[] = f["img"]
        forest.scale[] = f["scale"]
        forest.plants = f["plants"]
        for (plant_name, points) in f["position_points"]
            forest.points[plant_name] = points
        end
    end
end