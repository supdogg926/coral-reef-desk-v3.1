extends SceneTree
# D019: Clean production baseline

func _initialize():
	print("D019: START")
	var main_path = ProjectSettings.get_setting("application/run/main_scene", "")
	if main_path == "": print("D019: FAIL no main_scene"); quit(1); return
	print("D019: main_scene=", main_path)
	var s = load(main_path)
	if s == null: print("D019: FAIL load"); quit(1); return
	var mn = s.instantiate()
	root.add_child(mn)
	await create_timer(3.0).timeout
	# Check no auto-navigation
	var secondary_visible = false
	for child in mn.get_children():
		if child is Control and child.visible and "BlueGuardian" in str(child.name):
			secondary_visible = true; break
	if secondary_visible: print("D019: FAIL auto_nav"); quit(1); return
	print("D019: PASS")
	quit(0)
