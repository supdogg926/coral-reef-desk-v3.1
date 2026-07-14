extends SceneTree
# D023: GameState parser baseline ratchet

func _initialize():
	print("D023: START")
	var gs_path = "res://scripts/systems/GameState.gd"
	var gs = load(gs_path)
	if gs == null: print("D023: FAIL load"); quit(1); return
	var inst = gs.new()
	if inst == null: print("D023: FAIL instantiate"); quit(1); return
	print("D023: GameState instantiated OK")
	if not inst is RefCounted: print("D023: FAIL type"); quit(1); return
	print("D023: PASS")
	quit(0)
