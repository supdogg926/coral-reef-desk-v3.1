extends Node

const TEST_ROOT := "user://m19_h1_test_save"
const FAULTS := ["TEMP_OPEN", "TEMP_WRITE", "TEMP_VALIDATE", "BACKUP_OR_REPLACE", "FINAL_VALIDATE"]

var _all := true


func _ready() -> void:
	print("[M19_H1] Starting atomic save tests...")
	_clean()
	DirAccess.make_dir_absolute(TEST_ROOT)

	_test_success()
	_test_faults()
	_test_recovery()
	_test_10_saves()
	_test_seed()
	_test_clock()
	_test_vectors()

	if _all:
		print("[M19_H1] ALL TESTS PASS")
	else:
		printerr("[M19_H1] SOME TESTS FAILED")
	_clean()
	get_tree().quit(0 if _all else 1)


func _ss() -> SaveSystem:
	var s := SaveSystem.new()
	s.set_test_save_root(TEST_ROOT)
	s.initialize()
	return s


func _wf(path: String, d: Dictionary) -> void:
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(d, "\t"))


func _mk(balance: float) -> Dictionary:
	return {"waves_balance": balance, "save_version": 4, "save_schema": "x"}


func _clean() -> void:
	var d := DirAccess.open(TEST_ROOT)
	if d != null:
		for fn in ["final.json", "tmp.json", "bak.json"]:
			d.remove(fn)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  [PASS] ", msg)
	else:
		printerr("  [FAIL] ", msg)
		_all = false


func _test_success() -> void:
	print("\n--- Atomic Success ---")
	var s := _ss()
	_ok(s.save_game(_mk(100.0)), "save ok")
	_ok(s.save_exists, "save_exists")
	var ld := _ss().load_game()
	_ok(not ld.is_empty(), "reload ok")
	_ok(ld.get("waves_balance") == 100.0, "value matches")
	_ok(FileAccess.file_exists(TEST_ROOT + "/final.json"), "final exists")
	_ok(not FileAccess.file_exists(TEST_ROOT + "/tmp.json"), "tmp cleaned")
	_ok(not FileAccess.file_exists(TEST_ROOT + "/bak.json"), "bak cleaned")


func _test_faults() -> void:
	print("\n--- Fault Matrix ---")
	for fault in FAULTS:
		_clean()
		DirAccess.make_dir_absolute(TEST_ROOT)
		_wf(TEST_ROOT + "/final.json", _mk(50.0))
		var s := _ss()
		s.set_test_fault_point(fault, true)
		var ok := s.save_game(_mk(999.0))
		_ok(not ok, "%s: returns false" % fault)
		var raw_w: Variant = _ss().load_game().get("waves_balance", -1.0); var w: float = float(raw_w)
		var valid: bool = w == 50.0 or w == 999.0
		_ok(valid, "%s: old(50) or new(999) got %.1f" % [fault, w])


func _test_recovery() -> void:
	print("\n--- Recovery ---")
	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	_wf(TEST_ROOT + "/final.json", _mk(111.0))
	_wf(TEST_ROOT + "/tmp.json", _mk(999.0))
	_ok(_ss().load_game().get("waves_balance") == 111.0, "A: final beats tmp")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	_wf(TEST_ROOT + "/final.json", _mk(222.0))
	FileAccess.open(TEST_ROOT + "/tmp.json", FileAccess.WRITE).store_string("NOPE")
	_ok(_ss().load_game().get("waves_balance") == 222.0, "B: corrupt tmp")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	_wf(TEST_ROOT + "/bak.json", _mk(333.0))
	_ok(_ss().load_game().get("waves_balance") == 333.0, "C: bak recovery")
	_ok(FileAccess.file_exists(TEST_ROOT + "/final.json"), "C: restored")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	FileAccess.open(TEST_ROOT + "/final.json", FileAccess.WRITE).store_string("CORRUPT")
	_wf(TEST_ROOT + "/bak.json", _mk(444.0))
	_ok(_ss().load_game().get("waves_balance") == 444.0, "D: corrupt final")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	_wf(TEST_ROOT + "/final.json", _mk(555.0))
	_wf(TEST_ROOT + "/bak.json", _mk(111.0))
	_ok(_ss().load_game().get("waves_balance") == 555.0, "E: final > bak")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	var s6 := _ss()
	_ok(s6.load_game().is_empty(), "F: first run")
	_ok(not s6.save_exists, "F: no save")

	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	FileAccess.open(TEST_ROOT + "/final.json", FileAccess.WRITE).store_string("BAD_F")
	FileAccess.open(TEST_ROOT + "/bak.json", FileAccess.WRITE).store_string("BAD_B")
	_wf(TEST_ROOT + "/tmp.json", _mk(777.0))
	var g := _ss().load_game()
	_ok(g.get("waves_balance") == 777.0 or g.is_empty(), "G: tmp or empty")


func _test_10_saves() -> void:
	print("\n--- 10 Saves ---")
	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	for i in range(10):
		var s := _ss()
		_ok(s.save_game(_mk(float(i * 10))), "R%d save" % i)
		var ld := _ss().load_game()
		_ok(ld.get("waves_balance") == float(i * 10), "R%d value %.0f" % [i, ld.get("waves_balance", -1.0)])


func _test_seed() -> void:
	print("\n--- Seed Stability ---")
	_clean(); DirAccess.make_dir_absolute(TEST_ROOT)
	var wc := WallClockService.new()
	wc.set_test_override(1000000)
	var s := _ss()
	s.initialize(wc)
	var bg := {"schema_version": 1, "save_seed": 12345, "voyage_sequence": 0, "voyage_state": "READY", "voyage_end_ts": 0, "pending_result": {}}
	var d := _mk(0.0)
	d["blue_guardian_state"] = bg
	_ok(s.save_game(d), "seed save")

	var bg2: Dictionary = _ss().load_game().get("blue_guardian_state", {})
	_ok(bg2.get("save_seed") == 12345, "seed preserved")
	_ok(bg2.get("voyage_sequence") == 0, "seq=0")
	_ok(bg2.get("voyage_state") == "READY", "state=READY")

	var bg3: Dictionary = _ss().load_game().get("blue_guardian_state", {})
	_ok(bg2.get("save_seed") == bg3.get("save_seed"), "seed stable")


func _test_clock() -> void:
	print("\n--- WallClock ---")
	var wc := WallClockService.new()
	_ok(not wc.has_test_override(), "no override")
	_ok(wc.now_unix() > 1700000000, "real time")
	wc.set_test_override(1000)
	_ok(wc.now_unix() == 1000, "set 1000")
	wc.advance_test_override(500)
	_ok(wc.now_unix() == 1500, "advance")
	wc.clear_test_override()
	_ok(not wc.has_test_override(), "cleared")


func _test_vectors() -> void:
	print("\n--- Known Vectors ---")
	_ok(SeedMixer.new().test_known_vectors(), "vectors")
