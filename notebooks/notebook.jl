### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 7b226341-cef8-41c2-ac41-553476c59880
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.add(["CSV", "DataFrames", "InlineStrings", "PlutoUI"])	
end

# ╔═╡ 6f1926cf-07f2-4cfd-a194-d10b8c8820f6
begin
	import CSV
	using DataFrames
	import Base.convert
	using PlutoUI
	import PlutoUI: combine
end

# ╔═╡ fc92d3c4-b7df-11ee-0496-a9c23f3b880b
begin
	filepath = "planten.csv"
	df = filepath |> CSV.File |> DataFrame
	df = df[1:24, :]
end

# ╔═╡ c0d33f77-d6a0-4930-aebd-acfdc22ecba5
module PlantSpecs
	@Base.kwdef struct SizeRange
		start::Float64
		finish::Float64
	end
	Base.convert(::Type{SizeRange}, s::AbstractString) = SizeRange(s)
	function SizeRange(s::AbstractString)
		sizes = parse.(Float64, split(s, r" ?[-,] ?"))
		return SizeRange(sizes |> first, sizes |> last)
	end

	@Base.kwdef struct PlantSize
		height::SizeRange
		width::SizeRange
	end

	@Base.kwdef struct MonthRange
		start::Union{Int, Missing}
		finish::Union{Int, Missing}
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

	@Base.kwdef struct Plant
		name::String
		latin::String
		size::PlantSize
		flowering::MonthRange
		harvest::MonthRange
	end
	function Plant(row)
		return Plant(
			name=row["Naam"], latin=row["Wetenschappelijke naam"],
			size=PlantSize(height=row["Hoogte"], width=row["Breedte"]),
			flowering=MonthRange(row["Bloei"]),
			harvest=MonthRange(row["Oogst"])
		)
	end
	export Plant
end

# ╔═╡ 5edb88bb-15a6-47a7-89b8-0adafd6b35d9
plants = [
	PlantSpecs.Plant(row)
	for row in eachrow(df)
]

# ╔═╡ ed821e53-5208-4043-8faf-44e00d637a6c
plantdict = Dict(plant.name=>plant for plant in plants)

# ╔═╡ b2a12b1c-2625-4d42-8d33-c79ff860eff2
MAX_PLANTS = 100

# ╔═╡ 2e5c32cd-7504-4597-9045-8ef7bd710075
begin
	struct Active
		id::Int
		plant::Union{PlantSpecs.Plant, Missing}
	end
	name(plant::PlantSpecs.Plant) = plant.name
	name(::Missing) = ""
end

# ╔═╡ 80d6a0e4-ec22-49c3-8885-f403a4f389a8
actives = [Active(1, missing)]

# ╔═╡ 6a1a5615-4667-4dee-b452-978bff91f148
function select(active::Active)
	return Select(
		getproperty.(plants, :name),
		default=name(active.plant)
	)
end

# ╔═╡ 73eff382-179f-430e-9497-23005aee1876
@bind test select(Active(1, plants[10]))

# ╔═╡ dbb1be4c-afe1-46aa-ad12-9f0d2cb90ccf
function plant_number_input(plants::Vector{PlantSpecs.Plant}, actives::Vector)
	
	return combine() do child
		inputs = [
			md""" $(active.id): $(
				child(active.id |> string, select(active)
				)
			)"""
			for active in actives
		]
		
		md"""
		#### Number per plant
		$(inputs)
		"""
	end
end

# ╔═╡ b349d0e6-6e48-4fa9-87f0-a3669631036e
plant_number_input(plants, actives)

# ╔═╡ 9b53dc99-866e-4c5b-92dd-49c0be731421
# let
# 	add_active
# 	push!(actives, "")
# end

# ╔═╡ 0bff88f4-0c03-472a-859d-f47ba602a2ff
@bind vegetable Select(["potato", "carrot"])

# ╔═╡ f0bf4e1d-3c25-4708-af3a-e0be41fffad9
combine |> methods |> first

# ╔═╡ 22b6d6ee-1224-4898-bb23-da465d23f9cc
@bind x_different NumberField(0:100, default=20)

# ╔═╡ 78db959f-0bda-43e6-9102-4b600fb0c7fa
@bind test2 Select(getproperty.(plants, :name))

# ╔═╡ Cell order:
# ╠═7b226341-cef8-41c2-ac41-553476c59880
# ╠═6f1926cf-07f2-4cfd-a194-d10b8c8820f6
# ╠═fc92d3c4-b7df-11ee-0496-a9c23f3b880b
# ╠═c0d33f77-d6a0-4930-aebd-acfdc22ecba5
# ╠═5edb88bb-15a6-47a7-89b8-0adafd6b35d9
# ╠═ed821e53-5208-4043-8faf-44e00d637a6c
# ╠═b349d0e6-6e48-4fa9-87f0-a3669631036e
# ╠═b2a12b1c-2625-4d42-8d33-c79ff860eff2
# ╠═80d6a0e4-ec22-49c3-8885-f403a4f389a8
# ╠═2e5c32cd-7504-4597-9045-8ef7bd710075
# ╠═6a1a5615-4667-4dee-b452-978bff91f148
# ╠═73eff382-179f-430e-9497-23005aee1876
# ╠═dbb1be4c-afe1-46aa-ad12-9f0d2cb90ccf
# ╠═9b53dc99-866e-4c5b-92dd-49c0be731421
# ╠═0bff88f4-0c03-472a-859d-f47ba602a2ff
# ╠═f0bf4e1d-3c25-4708-af3a-e0be41fffad9
# ╠═22b6d6ee-1224-4898-bb23-da465d23f9cc
# ╠═78db959f-0bda-43e6-9102-4b600fb0c7fa
