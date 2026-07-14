class_name BlueGuardianConfig
extends RefCounted

const VOYAGE_DURATION_SECONDS: int = 30
const WAVE_COST: float = 100.0
const REGULAR_WEIGHT: int = 85
const SURPRISE_WEIGHT: int = 15
const DROP_POOL_REVISION: int = 2
const ACTIVE_DOCK_COUNT: int = 3

# M19 expanded species pool: 16 active species across 3 regions
# Each species has: id, zh_name, region, rarity_tier, category

static func get_active_species_pool() -> Array[String]:
	return [
		"tomato_clownfish_male",
		"tomato_clownfish_female",
		"rainbow_carpet_anemone",
		"cleaner_shrimp",
		"emerald_crab",
		"pulsing_xenia",
		"green_star_polyp",
		"firefish",
		"royal_gramma",
		"yellow_tang",
		"flame_angel",
		"torch_coral",
		"hammer_coral",
		"seahorse",
		"mandarin_dragonet",
		"blue_tang",
	]


static func get_region_docks() -> Array[Dictionary]:
	return [
		{
			"dock_id": "nearshore",
			"display_name": "近岸救助点",
			"region": "近岸浅海",
			"species": ["tomato_clownfish_male", "tomato_clownfish_female", "rainbow_carpet_anemone", "cleaner_shrimp", "emerald_crab", "firefish"],
		},
		{
			"dock_id": "reef_edge",
			"display_name": "礁缘救助点",
			"region": "礁缘海域",
			"species": ["pulsing_xenia", "green_star_polyp", "royal_gramma", "yellow_tang", "flame_angel", "torch_coral"],
		},
		{
			"dock_id": "deep_reef",
			"display_name": "深礁救助站",
			"region": "深礁海域",
			"species": ["hammer_coral", "seahorse", "mandarin_dragonet", "blue_tang"],
		},
	]


static func get_dock_display_names() -> Array[String]:
	var names: Array[String] = []
	for dock in get_region_docks():
		names.append(str(dock.get("display_name", "")))
	return names


static func get_species_region(species_id: String) -> String:
	for dock in get_region_docks():
		var species: Array = dock.get("species", [])
		for sid in species:
			if str(sid) == species_id:
				return str(dock.get("region", "未知海域"))
	return "未知海域"


static func get_species_rarity_tier(species_id: String) -> String:
	var common := ["tomato_clownfish_male", "tomato_clownfish_female", "cleaner_shrimp", "firefish", "royal_gramma", "yellow_tang"]
	var uncommon := ["rainbow_carpet_anemone", "emerald_crab", "pulsing_xenia", "green_star_polyp", "blue_tang"]
	var rare := ["torch_coral", "hammer_coral", "seahorse", "flame_angel", "mandarin_dragonet"]

	if common.has(species_id): return "常见"
	if uncommon.has(species_id): return "较少见"
	if rare.has(species_id): return "稀有"
	return "常见"


static func get_release_pulse(species_id: String) -> int:
	match get_species_rarity_tier(species_id):
		"常见": return 10
		"较少见": return 18
		"稀有": return 30
	return 10
