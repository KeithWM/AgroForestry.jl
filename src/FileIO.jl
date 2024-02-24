function save(forest::AgroForest2, output::AbstractString)
    @debug "Saving forest to $output"
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

function loadforest!(forest::AgroForest2, controllers::Dict{String,Controller}, input::AbstractString)
    @debug "Loading forest from $input"
    jldopen(input, "r") do f
        forest.img[] = f["img"]
        forest.scale[] = f["scale"]
        union!(forest.plants, f["plants"])
        for (plant_name, points) in f["position_points"]
            forest.positions[plant_name][] = points
        end
    end
    for plant in forest.plants
        linkcontroller!!(forest, controllers[plant.name], plant.name)
    end
end

function replaceimage!(forest::AgroForest2, input::AbstractString)
    @debug "Replacing background image from $input"
    forest.img[] = load(input)
    notify(forest.img)
end