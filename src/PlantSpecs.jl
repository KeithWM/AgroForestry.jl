module PlantSpecs
SUNOPTIONS = Dict(
    "Zon, Half-schaduw" => 3 // 4, "Zon" => 1, "Half-schaduw" => 1 // 2, "Shaduw" => 1 // 4
)
MOISTOPTIONS = Dict("Slecht" => 0, "Goed" => 1)

Base.@kwdef struct SizeRange
    start::Float64
    finish::Float64
end
Base.convert(::Type{SizeRange}, s::AbstractString) = SizeRange(s)
function SizeRange(s::AbstractString)
    sizes = parse.(Float64, split(s, r" ?[-,] ?"))
    return SizeRange(sizes |> first, sizes |> last)
end

Base.@kwdef struct PlantSize
    height::SizeRange
    width::SizeRange
end

Base.@kwdef struct MonthRange
    start::Union{Int,Missing}
    finish::Union{Int,Missing}
end
function MonthRange(s::AbstractString)
    local months
    try
        months = parse.(Int, split(s, r" ?[-,] ?"))
    catch
        months = [missing, missing]
    end
    return MonthRange(months |> first, months |> last)
end

Base.@kwdef struct Plant
    name::String
    latin::String
    size::PlantSize
    flowering::MonthRange
    harvest::MonthRange
    sun::Rational
    moist::Rational
end
function Plant(row)
    return Plant(
        name=row["Naam"], latin=row["Wetenschappelijke naam"],
        size=PlantSize(height=row["Hoogte"], width=row["Breedte"]),
        flowering=MonthRange(row["Bloei"]),
        harvest=MonthRange(row["Oogst"]),
        sun=SUNOPTIONS[row["Zon"]],
        moist=MOISTOPTIONS[row["Natte grond"]]
    )
end
export Plant
end