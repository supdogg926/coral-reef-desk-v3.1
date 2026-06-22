extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	_run()
	quit(1 if not _failures.is_empty() else 0)


func _run() -> void:
	_assert(FileAccess.file_exists("res://project.godot"), "project.godot exists")
	_assert(load("res://scenes/main/Main.tscn") != null, "Main.tscn loads")

	var registry_script = load("res://scripts/autoload/DataRegistry.gd")
	_assert(registry_script != null, "DataRegistry.gd loads")
	if registry_script == null:
		_print_results()
		return

	var registry = Node.new()
	registry.set_script(registry_script)
	get_root().add_child(registry)
	registry.load_all()

	_assert(registry.is_loaded_ok(), "DataRegistry.is_loaded_ok is true")
	_assert(registry.get_species_count() >= 100, "species count >= 100")
	_assert(registry.get_equipment_count() >= 20, "equipment count >= 20")
	_assert(registry.get_task_count() == 10, "task count == 10")

	var task_file = FileAccess.open("res://data/tasks/maintenance_tasks_seed.json", FileAccess.READ)
	if task_file == null:
		_failures.append("Cannot open maintenance_tasks_seed.json")
	else:
		var tasks = JSON.parse_string(task_file.get_as_text())
		if tasks is Array:
			for task in tasks:
				if task is Dictionary and task.has("reward"):
					_failures.append("reward field found in task: " + String(task.get("id", "<missing id>")))
		else:
			_failures.append("tasks JSON is not an array")

	registry.queue_free()
	_print_results()


func _assert(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		_failures.append(label)
		push_error("FAIL: " + label)


func _print_results() -> void:
	if _failures.is_empty():
		print("SMOKE_TEST_RESULT=PASS")
	else:
		print("SMOKE_TEST_RESULT=FAIL")
		for failure in _failures:
			print("FAILURE: " + failure)
