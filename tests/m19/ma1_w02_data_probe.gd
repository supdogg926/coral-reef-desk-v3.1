extends Node
var _frame = 0; var _done = false; var _results = {}

func _process(_delta):
	if _done: return; _frame += 1
	if _frame == 90:
		var root = get_tree().root; var mn = null
		for child in root.get_children():
			if str(child.name) == "Main": mn = child; break
		if mn == null: _done = true; get_tree().quit(1); return
		var gs = mn.get("game_state")
		if gs == null: _results["ERROR"] = "no GameState"; _done = true; get_tree().quit(1); return
		_results["entry"] = "PASS"
		_results["wave_balance"] = gs.get("economy_system").call("get_waves_balance") if gs.get("economy_system") else -1
		var water = gs.call("get_water_chemistry_debug_state") if gs.has_method("get_water_chemistry_debug_state") else {}
		_results["water_params"] = {}
		for k in ["temperature","salinity","nitrate","phosphate","ph","alkalinity","calcium"]:
			_results["water_params"][k] = water.get(k, "MISSING")
		var ds = gs.call("get_device_state") if gs.has_method("get_device_state") else {}
		_results["devices"] = ds.get("devices", {}).size()
		_results["light_intensity"] = gs.get("light_intensity") if "light_intensity" in gs else -1
		_results["light_color_temp"] = gs.get("light_color_temp") if "light_color_temp" in gs else -1
		_results["m19_ui"] = false
		for child in mn.get_children():
			if "M19" in str(child.name): _results["m19_ui"] = true; break
		_results["legacy_visible"] = 0
		for child in mn.get_children():
			if child is Control and child.visible and str(child.name) in ["TitleBar","DisplayTankView","SumpView"]:
				_results["legacy_visible"] += 1
		var nodes = []; _collect(root, nodes)
		_results["node_count"] = nodes.size()
		_results["ui_nodes"] = nodes
		mkdir_r("reports/m19/ma1/w02")
		var f = FileAccess.open("user://../reports/m19/ma1/w02/runtime_ui_snapshot.json", FileAccess.WRITE)
		if f != null: f.store_string(JSON.stringify(_results,"\t")); f.close()
		_done = true; get_tree().quit(0)

func _collect(node: Node, result: Array):
	for child in node.get_children():
		var cls = child.get_class()
		if cls in ["Label","Button","RichTextLabel","ProgressBar"]:
			var info = {"name": str(child.name), "class": cls, "path": str(child.get_path())}
			if child is Label or child is Button: info["text"] = str(child.text)
			if child is Button: info["disabled"] = child.disabled
			if child is Control:
				var c = child as Control
				info["global_rect"] = [c.global_position.x, c.global_position.y, c.size.x, c.size.y]
				info["visible"] = c.visible
			result.append(info)
		_collect(child, result)

static func mkdir_r(path: String):
	var d = DirAccess.open("res://")
	if d: d.make_dir_recursive(path)
