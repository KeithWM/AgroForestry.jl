function makebuttons(forest, buttongrid)
    # buttonlabels = ["Save", "Load"]
    # n = buttonlabels |> length
    # buttons = buttongrid[1:2, 1:2] = [
    #     Button(buttongrid[1, 2]; label="Save"),
    #     Button(buttongrid[2, 2]; label="Load")
    # ]
    savefile = Observable("forest.jld2")
    loadfile = Observable("forest.jld2")
    buttons = Dict(
        "savetext" => Textbox(buttongrid[1, 1]; stored_string=savefile, width=150),
        "savebutton" => Button(buttongrid[1, 2]; label="Save"),
        "loadtext" => Textbox(buttongrid[2, 1]; stored_string=loadfile, width=150),
        "loadbutton" => Button(buttongrid[2, 2]; label="Load"),
    )

    on(buttons["savetext"].stored_string) do s
        savefile[] = s
    end
    on(buttons["loadtext"].stored_string) do s
        loadfile[] = s
    end
    on(buttons["savebutton"].clicks) do n
        @show n
        save(forest, savefile[])
    end
    on(buttons["loadbutton"].clicks) do n
        loadforest(forest, loadfile[])
    end
    # for i in 1:n
    #     on(buttons[i].clicks) do n
    #         counts[][i] += 1
    #         notify(counts)
    #     end
    # end
    return nothing
end