GLOWCOLORS = Dict(
    1 => :yellow, 3 // 4 => :orange, 1 // 2 => :red, 0 => :white
)

function showname(plant::PlantSpecs.Plant)
    return plant.name
end
function color(m::PlantSpecs.MonthRange)
    return color(m.start, m.finish)
end
color(s::Int, f::Int) = Makie.Colors.HSV((s + f) * 15, 0.8, 0.8)
color(::Missing, ::Missing) = Makie.Colors.HSV(0, 0, 0)
mean(sr::PlantSpecs.SizeRange) = (sr.start + sr.finish) / 2

function makekwargs(plant::PlantSpecs.Plant)
    return Dict(
        :marker => makeshape(plant),
        :color => color(plant.flowering),
        :strokewidth => mean(plant.size.height) / 10,
        :strokecolor => color(plant.harvest),
        :markersize => mean(plant.size.width),
        :glowcolor => GLOWCOLORS[plant.sun],
        :glowwidth => 5,
    )
end

function makeshape(plant::PlantSpecs.Plant)
    plantstring = "m 0,0 c 11.258232,-8.18373 8.636684,-18.3484 -3.243316,-10.99412 1.697144,-11.31428 -5.808113,-19.8 -11.465257,-3.39428 -1.697143,-16.40572 -11.672627,-10.3156 -9.975486,0.99869 -10.74857,-9.05144 -13.218798,-5.84458 -6.430228,7.16685 -11.628673,-1.47308 -13.577141,10.18286 -2.262857,14.70857 -9.051427,10.74857 -0.452914,12.22011 8.598516,4.30012 -1.13143,14.14284 7.599827,14.23743 10.428398,1.79172 9.051429,11.87999 8.127371,-2.13184 8.127371,-2.13184 11.880001,8.48572 11.890067,-2.18373 6.222859,-12.44571 z"
    plantshape = BezierPath(plantstring, fit=true, flipy=true)
    return plantshape
end
