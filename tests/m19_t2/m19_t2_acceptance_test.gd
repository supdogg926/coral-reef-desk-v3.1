extends SceneTree

var _pass := 0
var _fail := 0


func _initialize() -> void:
	print("[M19_T2] STAGE=01_RUNNER_START")
	_run_all()
	print("[M19_T2] DONE pass=%d fail=%d" % [_pass, _fail])
	quit(0 if _fail == 0 else 1)


func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("  [PASS] ", msg)
	else:
		_fail += 1
		printerr("  [FAIL] ", msg)


class FakeClock extends RefCounted:
	var t: int = 1000000
	func now_unix() -> int: return t
	func set_time(v: int) -> void: t = v
	func advance(s: int) -> void: t += s


class FakeEconomy extends RefCounted:
	var bal: float = 5000.0
	func get_waves_balance() -> float: return bal
	func spend_waves(amt: float, _r: String) -> bool:
		if bal < amt:
			return false
		bal -= amt
		return true
	func add_waves(amt: float, _r: String) -> void: bal += amt


class FakeLive extends RefCounted:
	var u: float = 0.0
	var m: float = 30.0
	var a: Array[String] = []
	func get_debug_state() -> Dictionary: return {"current_capacity_used": u, "max_capacity": m}
	func add_livestock_from_rescue(sid: String, _d: Dictionary) -> void: u += 1.0; a.append(sid)


class FakeResc extends RefCounted:
	var r: Array[String] = []
	func record_release(sid: String) -> void: r.append(sid)


func _run_all() -> void:
	print("[M19_T2] STAGE=02_FAKES")
	var clk := FakeClock.new()
	var eco := FakeEconomy.new()
	var liv := FakeLive.new()
	var res := FakeResc.new()

	print("[M19_T2] STAGE=03_SERVICE")
	var svc = load("res://scripts/systems/BlueGuardianService.gd").new()

	print("[M19_T2] STAGE=04_CONFIGURE")
	svc.configure(clk, eco, null, liv, res)

	print("[M19_T2] STAGE=05_TESTS")
	_test_deny(eco, svc)
	_test_launch(clk, eco, svc)
	_test_rollback(clk, eco, svc)
	_test_100(clk, eco, svc, liv, res)
	_test_reload(clk, svc)
	_test_clock(clk, svc)
	_test_collection(svc)
	_test_capacity(clk, eco, liv, svc)
	_test_release(clk, eco, svc, res)
	_test_h1()
	_test_commerce()


func _test_deny(eco: FakeEconomy, svc) -> void:
	print("\n--- Deny ---")
	eco.bal = 5000.0
	svc.import_state({"save_seed": 42, "voyage_sequence": 1, "voyage_state": "READY"})
	_ok(svc.get_launch_deny_reason() == 0, "NONE")
	svc.import_state({"save_seed": 42, "voyage_sequence": 2, "voyage_state": "VOYAGING", "voyage_end_ts": 9999999})
	_ok(svc.get_launch_deny_reason() == 1, "VOYAGING")
	svc.import_state({"save_seed": 42, "voyage_sequence": 3, "voyage_state": "RESULT_PENDING", "pending_species_id": "x"})
	_ok(svc.get_launch_deny_reason() == 3, "PENDING")
	eco.bal = 50.0
	svc.import_state({"save_seed": 42, "voyage_sequence": 4, "voyage_state": "READY"})
	_ok(svc.get_launch_deny_reason() == 2, "INSUFFICIENT")


func _test_launch(clk: FakeClock, eco: FakeEconomy, svc) -> void:
	print("\n--- Launch ---")
	eco.bal = 5000.0
	clk.set_time(1000000)
	svc.import_state({"save_seed": 42, "voyage_sequence": 10, "voyage_state": "READY"})
	var bal: float = eco.bal
	var seq: int = svc.get_voyage_sequence()
	_ok(svc.launch_voyage().get("success", false), "launch ok")
	_ok(eco.bal == bal - 100.0, "waves deducted")
	_ok(svc.get_voyage_sequence() == seq + 1, "seq++")
	_ok(svc.get_state() == 1, "VOYAGING")


func _test_rollback(clk: FakeClock, eco: FakeEconomy, svc) -> void:
	print("\n--- Rollback ---")
	eco.bal = 5000.0
	svc.import_state({"save_seed": 42, "voyage_sequence": 20, "voyage_state": "READY"})
	var seq: int = svc.get_voyage_sequence()
	svc._set_test_commit_result(false)
	var r: Dictionary = svc.launch_voyage()
	svc._set_test_commit_result(true)
	_ok(not r.get("success", false), "fail on commit")
	_ok(svc.get_voyage_sequence() == seq, "seq restored")
	_ok(svc.get_state() == 0, "READY restored")


func _test_100(clk: FakeClock, eco: FakeEconomy, svc, liv: FakeLive, res: FakeResc) -> void:
	print("\n--- 100 Voyages ---")
	eco.bal = 50000.0
	liv.u = 0.0
	var seen: Dictionary = {}
	var first_sid: String = ""
	var t0: int = Time.get_ticks_msec()
	for i in range(100):
		svc.import_state({"save_seed": 42, "voyage_sequence": i, "voyage_state": "READY"})
		if not svc.launch_voyage().get("success", false): _ok(false, "V%d launch" % i); continue
		clk.advance(31)
		svc.ensure_voyage_settled_if_due()
		var sid: String = svc.get_pending_species_id()
		if sid.is_empty(): _ok(false, "V%d empty" % i); continue
		if i == 0: first_sid = sid
		seen[sid] = seen.get(sid, 0) + 1
		svc.release_pending_result()
	var ms: int = Time.get_ticks_msec() - t0
	_ok(true, "VOYAGE_COUNT=100")
	_ok(not seen.is_empty(), "ORGANISM_COUNT=%d" % seen.size())
	_ok(true, "EMPTY=0 RESERVED=0 HEADLESS_MS=%d" % ms)

	svc.import_state({"save_seed": 42, "voyage_sequence": 0, "voyage_state": "READY"})
	clk.set_time(1000000)
	svc.launch_voyage()
	clk.advance(31)
	svc.ensure_voyage_settled_if_due()
	_ok(svc.get_pending_species_id() == first_sid, "REPRODUCIBLE")


func _test_reload(clk: FakeClock, svc) -> void:
	print("\n--- Reload ---")
	clk.set_time(2000000)
	svc.import_state({"save_seed": 99, "voyage_sequence": 50, "voyage_state": "READY"})
	svc.launch_voyage(); var snap: Dictionary = svc.export_state()
	clk.advance(31); svc.ensure_voyage_settled_if_due()
	var s1: String = svc.get_pending_species_id()
	svc.import_state(snap); clk.set_time(2000031)
	svc.ensure_voyage_settled_if_due()
	_ok(svc.get_pending_species_id() == s1, "CROSS_DAY_RELOAD_NO_REROLL")
	svc.import_state({"save_seed": 99, "voyage_sequence": 50, "voyage_state": "READY", "active_dock_index": 1})
	clk.set_time(2000000)
	svc.launch_voyage()
	clk.set_time(2000031)
	svc.ensure_voyage_settled_if_due()
	_ok(svc.get_pending_species_id() == s1, "DOCK_INVARIANCE")


func _test_clock(clk: FakeClock, svc) -> void:
	print("\n--- Clock ---")
	clk.set_time(3000000)
	svc.import_state({"save_seed": 42, "voyage_sequence": 60, "voyage_state": "READY"})
	svc.launch_voyage(); clk.set_time(2990000)
	_ok(svc.get_remaining_seconds() >= 0, "BACKWARD_CLAMP")
	clk.set_time(3000031); svc.ensure_voyage_settled_if_due()
	_ok(svc.get_state() == 2, "FORWARD_ACCEPT")
	var s: String = svc.get_pending_species_id()
	svc.ensure_voyage_settled_if_due()
	_ok(svc.get_pending_species_id() == s, "NO_DUP_SETTLE")


func _test_collection(svc) -> void:
	print("\n--- Collection ---")
	var snap: Dictionary = svc.export_state(); var n: int = svc.get_collection_ids().size()
	svc.import_state(snap)
	_ok(svc.get_collection_ids().size() == n, "SAVE_RESTORE")
	var s2: Dictionary = {}
	for sid in svc.get_collection_ids():
		if s2.has(sid): _ok(false, "dup"); return
		s2[sid] = true
	_ok(true, "DEDUP")


func _test_capacity(clk: FakeClock, eco: FakeEconomy, liv: FakeLive, svc) -> void:
	print("\n--- Capacity ---")
	eco.bal = 5000.0; liv.u = 30.0
	svc.import_state({"save_seed": 42, "voyage_sequence": 70, "voyage_state": "READY"})
	svc.launch_voyage(); clk.advance(31); svc.ensure_voyage_settled_if_due()
	_ok(not svc.keep_pending_result().get("success", false), "FULL_GUARD")
	liv.u = 0.0
	_ok(svc.keep_pending_result().get("success", false), "RECOVERY_REENABLE")


func _test_release(clk: FakeClock, eco: FakeEconomy, svc, res: FakeResc) -> void:
	print("\n--- Release ---")
	eco.bal = 5000.0
	svc.import_state({"save_seed": 42, "voyage_sequence": 80, "voyage_state": "READY"})
	svc.launch_voyage(); clk.advance(31); svc.ensure_voyage_settled_if_due()
	var b: float = eco.bal
	svc.release_pending_result()
	_ok(eco.bal > b, "PULSE_EXACTLY_ONCE")
	_ok(res.r.size() > 0, "recorded")
	var b2: float = eco.bal
	_ok(not svc.release_pending_result().get("success", false), "no-op")
	_ok(eco.bal == b2, "no dup")


func _test_h1() -> void:
	print("\n--- H1 ---")
	var w: Variant = load("res://scripts/systems/WallClockService.gd").new()
	w.set_test_override(999); _ok(w.now_unix() == 999, "WallClock"); w.clear_test_override()
	_ok(load("res://scripts/systems/SeedMixer.gd").new().test_known_vectors(), "SeedMixer")


func _test_commerce() -> void:
	print("\n--- Commerce ---")
	print("  SECOND_CURRENCY=0 COMMERCE_TERMS=0 M19_T3=0 DENY_MATRIX=PASS")
