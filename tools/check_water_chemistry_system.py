from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
WATER_PATH = ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd"
TIME_PATH = ROOT / "scripts" / "systems" / "TimeSystem.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
REPORT_PATH = ROOT / "reports" / "m5_water_chemistry_check_summary.json"

REQUIRED_WATER_FUNCTIONS = [
    "func initialize()",
    "func reset_to_initial_values()",
    "func simulate_tick(delta_seconds: float, equipment_effects_summary: Dictionary)",
    "func apply_natural_drift(delta_seconds: float)",
    "func apply_equipment_stabilization(equipment_effects_summary: Dictionary, delta_seconds: float)",
    "func calculate_parameter_status()",
    "func calculate_water_quality_score()",
    "func get_water_status()",
    "func get_debug_state()",
]

REQUIRED_TIME_FUNCTIONS = [
    "func initialize()",
    "func update_time(delta_seconds: float)",
    "func get_elapsed_seconds()",
    "func get_elapsed_days_debug()",
    "func get_debug_state()",
]

REQUIRED_STATUS_TEXT = [
    "\u6e29\u5ea6",
    "\u76d0\u5ea6",
    "pH",
    "NO3",
    "PO4",
    "KH",
    "Ca",
    "\u6c34\u8d28\u8bc4\u5206",
    "\u6c34\u8d28\u72b6\u6001",
    "\u6570\u636e\uff1a\u7269\u79cd161\uff5c\u8bbe\u590728\uff5c\u4efb\u52a110\uff5c\u4e8b\u4ef67",
    "\u6821\u9a8c\uff1aload=OK\uff5cerrors=0",
    "\u521d\u7ea7\u8bbe\u5907",
    "\u7ba1\u8def\uff1a\u9690\u5f0f\u8fde\u63a5",
    "\u7ba1\u8def\u73a9\u6cd5\uff1a\u5173\u95ed",
]

SCAN_GDSCRIPT = [
    WATER_PATH,
    TIME_PATH,
    GAME_STATE_PATH,
    MAIN_PATH,
    STATUS_PANEL_PATH,
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentPlacementSystem.gd",
]


def load_json(path: Path, errors: list[dict[str, Any]]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:  # noqa: BLE001
        errors.append({"type": "json_error", "path": str(path), "message": str(exc)})
        return None


def record_count(data: Any) -> int:
    if isinstance(data, list):
        return len([item for item in data if isinstance(item, dict)])
    if isinstance(data, dict):
        total = 0
        for value in data.values():
            if isinstance(value, list):
                total += len([item for item in value if isinstance(item, dict)])
        return total
    return 0


def main() -> int:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    for path in [WATER_PATH, TIME_PATH, GAME_STATE_PATH, MAIN_PATH, STATUS_PANEL_PATH, MAIN_SCENE_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    water_text = WATER_PATH.read_text(encoding="utf-8") if WATER_PATH.exists() else ""
    time_text = TIME_PATH.read_text(encoding="utf-8") if TIME_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""

    missing_water_functions = [name for name in REQUIRED_WATER_FUNCTIONS if name not in water_text]
    if missing_water_functions:
        errors.append({"type": "missing_water_functions", "functions": missing_water_functions})

    missing_time_functions = [name for name in REQUIRED_TIME_FUNCTIONS if name not in time_text]
    if missing_time_functions:
        errors.append({"type": "missing_time_functions", "functions": missing_time_functions})

    for token in ["WaterChemistrySystem", "TimeSystem", "EquipmentSystem", "EquipmentPlacementSystem", "simulate_tick"]:
        if token not in game_state_text:
            errors.append({"type": "missing_gamestate_reference", "token": token})

    for token in ["_process", "game_state.update(delta)", "update_water_chemistry_debug"]:
        if token not in main_text:
            errors.append({"type": "missing_main_binding", "token": token})

    combined_ui_text = status_text + "\n" + scene_text
    missing_status_text = [text for text in REQUIRED_STATUS_TEXT if text not in combined_ui_text]
    if missing_status_text:
        errors.append({"type": "missing_statuspanel_water_fields", "texts": missing_status_text})

    variant_inference_hits: list[dict[str, Any]] = []
    for path in SCAN_GDSCRIPT:
        if not path.exists():
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if ":=" in line:
                variant_inference_hits.append({"path": str(path), "line": line_number, "text": line.strip()})
    if variant_inference_hits:
        errors.append({"type": "variant_inference_operator_found", "hits": variant_inference_hits})

    data_errors: list[dict[str, Any]] = []
    species_count = sum(
        record_count(load_json(path, data_errors))
        for path in [
            ROOT / "data" / "species" / "corals_seed.json",
            ROOT / "data" / "species" / "fish_seed.json",
            ROOT / "data" / "species" / "legacy_species_extracted.json",
            ROOT / "data" / "species" / "tool_creatures_seed.json",
        ]
    )
    equipment_count = sum(
        record_count(load_json(path, data_errors))
        for path in [
            ROOT / "data" / "equipment" / "equipment_seed.json",
            ROOT / "data" / "equipment" / "tanks_seed.json",
        ]
    )
    task_count = record_count(load_json(ROOT / "data" / "tasks" / "maintenance_tasks_seed.json", data_errors))
    event_count = record_count(load_json(ROOT / "data" / "events" / "random_events_seed.json", data_errors))
    errors.extend(data_errors)

    counts = {
        "species": species_count,
        "equipment": equipment_count,
        "tasks": task_count,
        "events": event_count,
    }
    if counts != {"species": 161, "equipment": 28, "tasks": 10, "events": 7}:
        errors.append({"type": "dataregistry_count_mismatch", "counts": counts})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "required_files": [str(path) for path in [WATER_PATH, TIME_PATH, GAME_STATE_PATH, MAIN_PATH, STATUS_PANEL_PATH]],
        "dataregistry_counts": counts,
        "required_water_functions": REQUIRED_WATER_FUNCTIONS,
        "required_time_functions": REQUIRED_TIME_FUNCTIONS,
        "variant_inference_hit_count": len(variant_inference_hits),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Water chemistry check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Water chemistry check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
