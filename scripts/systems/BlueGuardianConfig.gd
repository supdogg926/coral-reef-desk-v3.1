class_name BlueGuardianConfig
extends RefCounted

const VOYAGE_DURATION_SECONDS: int = 30
const WAVE_COST: float = 100.0
const REGULAR_WEIGHT: int = 85
const SURPRISE_WEIGHT: int = 15
const DROP_POOL_REVISION: int = 1
const ACTIVE_DOCK_COUNT: int = 2

static func get_active_species_pool() -> Array[String]:
	return [
		"tomato_clownfish_male",
		"tomato_clownfish_female",
		"rainbow_carpet_anemone",
		"cleaner_shrimp",
		"emerald_crab",
		"pulsing_xenia",
	]

static func get_dock_display_names() -> Array[String]:
	return ["近岸救助点", "礁缘救助点"]
