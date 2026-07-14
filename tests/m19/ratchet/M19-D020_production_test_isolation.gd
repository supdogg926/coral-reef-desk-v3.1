extends SceneTree
# D020: Production/test isolation

func _initialize():
	print("D020: START")
	var args = OS.get_cmdline_user_args()
	var has_acceptance = false
	for a in args: if "--acceptance" in a: has_acceptance = true; break
	if not has_acceptance:
		print("D020: MISSING --acceptance flag")
		quit(1); return
	print("D020: Acceptance flag present")
	# Check production Main has no test symbols
	var main_gd_path = "res://scenes/main/Main.gd"
	var f = FileAccess.open(main_gd_path, FileAccess.READ)
	if f != null:
		var content = f.get_as_text(); f.close()
		var forbidden = ["AllPageDriver", "RuntimeGUI", "RuntimeData", "auto_quit", "acceptance_runner"]
		for fb in forbidden:
			if fb in content: print("D020: FAIL forbidden: ", fb); quit(1); return
	print("D020: PASS")
	quit(0)
