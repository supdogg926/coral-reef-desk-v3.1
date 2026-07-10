extends SceneTree

func _init() -> void:
	_run()
	quit(0)

func _run() -> void:
	print("[M17-T01] generating placeholder PNGs for new species")
	var LibraryScript: GDScript = load("res://scripts/systems/CardAssetLibrary.gd") as GDScript
	var library: RefCounted = LibraryScript.new()
	library.initialize()

	var new_species: Array[String] = [
		"rescue_seahorse",
		"rescue_hermit_crab",
		"rescue_brain_coral_frag"
	]

	var output_dir: String = "res://assets/cards/placeholder"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))

	for species_id in new_species:
		var path: String = output_dir + "/" + species_id + ".png"
		var result: Dictionary = library.generate_placeholder_png(species_id, path)
		if bool(result.get("success", false)):
			var sha: String = str(result.get("sha256", ""))
			print("  OK: ", species_id, " SHA: ", sha)
		else:
			printerr("  FAIL: ", species_id, " error: ", result.get("error", "unknown"))

	print("[M17-T01] placeholder generation complete")
