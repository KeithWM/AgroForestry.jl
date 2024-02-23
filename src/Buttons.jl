function makebuttons(forest::AgroForest2, controllers::Dict{String,Controller}, buttongrid)
    default = "forest.jld2"
    savefile = Observable(default)
    loadfile = Observable(default)
    buttons = Dict(
        "savetext" => Textbox(buttongrid[1, 1]; placeholder=default, width=150),
        "savebutton" => Button(buttongrid[1, 2]; label="Save"),
        "loadtext" => Textbox(buttongrid[2, 1]; placeholder=default, width=150),
        "loadbutton" => Button(buttongrid[2, 2]; label="Load"),
    )

    on(buttons["savetext"].stored_string) do s
        savefile[] = s
        @show savefile
    end
    on(buttons["loadtext"].stored_string) do s
        loadfile[] = s
    end
    on(buttons["savebutton"].clicks) do n
        @show n
        save(forest, savefile[])
    end
    on(buttons["loadbutton"].clicks) do n
        loadforest(forest, controllers, loadfile[])
    end
    return buttons
end