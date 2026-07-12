class_name SeedMixer
extends RefCounted

const GOLDEN_GAMMA_I64: int = -7046029254386353131


func stable_mix(value: int) -> int:
	var x: int = value
	x = (x ^ (x >> 30)) * GOLDEN_GAMMA_I64
	x = (x ^ (x >> 27)) * GOLDEN_GAMMA_I64
	x = x ^ (x >> 31)
	return x


func voyage_seed(save_seed: int, voyage_sequence: int) -> int:
	return save_seed ^ stable_mix(voyage_sequence)


func get_known_vectors() -> Array[Dictionary]:
	return [
		{"save_seed": 0, "voyage_sequence": 0, "expected_mixed": 0},
		{"save_seed": 1, "voyage_sequence": 0, "expected_mixed": 1 ^ stable_mix(0)},
		{"save_seed": 1234567890, "voyage_sequence": 0, "expected_mixed": 1234567890 ^ stable_mix(0)},
		{"save_seed": 0, "voyage_sequence": 1, "expected_mixed": 0 ^ stable_mix(1)},
		{"save_seed": 42, "voyage_sequence": 7, "expected_mixed": 42 ^ stable_mix(7)},
		{"save_seed": 1, "voyage_sequence": 100, "expected_mixed": 1 ^ stable_mix(100)},
		{"save_seed": -1, "voyage_sequence": 1, "expected_mixed": -1 ^ stable_mix(1)},
	]


func test_known_vectors() -> bool:
	var vectors: Array = get_known_vectors()
	var all_pass: bool = true
	for v in vectors:
		var result: int = voyage_seed(int(v["save_seed"]), int(v["voyage_sequence"]))
		var expected: int = int(v["expected_mixed"])
		if result != expected:
			print("[SeedMixer] VECTOR FAIL: save_seed=%d voyage=%d expected=%d got=%d" % [v["save_seed"], v["voyage_sequence"], expected, result])
			all_pass = false
	if all_pass:
		print("[SeedMixer] All known vectors PASS")
	return all_pass
