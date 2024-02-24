function makebuttons(forest::AgroForest2, controllers::Dict{String,Controller}, buttongrid)
    default = "forest.jld2"
    defaultimg = "notebooks/ontwerp_afstand.png"
    savefile = Observable(default)
    loadfile = Observable(default)
    imagefile = Observable(defaultimg)
    buttons = Dict(
        "savetext" => Textbox(buttongrid[1, 1]; placeholder=default, width=150),
        "savebutton" => Button(buttongrid[1, 2]; label="Save"),
        "loadtext" => Textbox(buttongrid[2, 1]; placeholder=default, width=150),
        "loadbutton" => Button(buttongrid[2, 2]; label="Load"),
        "imagetext" => Textbox(buttongrid[3, 1]; placeholder=defaultimg, width=150),
        "imagebutton" => Button(buttongrid[3, 2]; label="Replace image"),
    )

    on(buttons["savetext"].stored_string) do s
        savefile[] = s
        @show savefile
    end
    on(buttons["loadtext"].stored_string) do s
        loadfile[] = s
    end
    on(buttons["imagetext"].stored_string) do s
        imagefile[] = s
    end
    on(buttons["savebutton"].clicks) do n
        @show n
        save(forest, savefile[])
    end
    on(buttons["loadbutton"].clicks) do n
        loadforest!(forest, controllers, loadfile[])
    end
    on(buttons["imagebutton"].clicks) do n
        replaceimage!(forest, imagefile[])
    end
    return buttons
end