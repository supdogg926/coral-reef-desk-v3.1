from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
SUMP_VIEW_PATH = ROOT / "scenes" / "tank" / "SumpView.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
TIME_PATH = ROOT / "scripts" / "systems" / "TimeSystem.gd"
WATER_PATH = ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
REPORT_PATH = ROOT / "reports" / "m5_2_ui_readability_dynamic_update_check_summary.json"

REQUIRED_STATUS_LABELS = [
    "\u6570\u636e\uff1a",
    "\u6821\u9a8c\uff1a",
    "\u5f53\u524d\u9636\u6bb5",
    "\u6c34\u8d28\u72b6\u6001",
    "\u6c34\u8d28\u8bc4\u5206",
    "\u6e29\u5ea6",
    "\u76d0\u5ea6",
    "pH",
    "NO3",
    "PO4",
    "KH",
    "Ca",
    "\u521d\u7ea7\u8bbe\u5907",
    "\u7a33\u5b9a\u5ea6",
    "\u627f\u8f7d\u529b",
    "\u7ef4\u62a4\u8d1f\u62c5",
    "\u7ba1\u8def\uff1a\u9690\u5f0f\u8fde\u63a5",
    "\u7ba1\u8def\u73a9\u6cd5\uff1a\u5173\u95ed",
    "\u6a21\u62df\uff1a\u81ea\u52a8\u8fd0\u884c\u4e2d",
    "\u65f6\u95f4\u500d\u7387\uff1a1\u79d2=10\u5206\u949f",
    "\u6e38\u620f\u65f6\u95f4",
    "\u6c34\u8d28\u66f4\u65b0",
    "\u6c34\u8d28\u53d8\u5316",
    "\u6536\u76ca\u53d8\u5316",
]

REQUIRED_SUMP_LABELS = [
    "\u6ee4\u888b\uff5c\u5df2\u88c5",
    "\u86cb\u5206\uff5c\u5df2\u88c5",
    "\u85fb\u7f38\uff5c\u5df2\u88c5",
    "\u56de\u6c34\uff5c\u5df2\u88c5",
    "\u52a0\u70ed\uff5c\u5df2\u88c5",
    "\u6ee4\u6750\uff5c\u5df2\u88c5",
    "\u6d3b\u77f3\uff5c\u5df2\u88c5",
]

FORBIDDEN_SUMP_PRIMARY_TEXT = [
    "storage_state=installed",
    "effective=true",
    "slot_mech_01",
    "slot_skimmer_01",
    "slot_refugium_01",
    "slot_return_01",
    "slot_return_heater_01",
    "slot_mech_media_01",
    "slot_display_rock_01",
    "(filter_sock)",
    "(protein_skimmer)",
    "(refugium)",
    "(return_pump)",
    "(heater)",
    "(filter_media)",
    "(live_rock)",
]

SCAN_GDSCRIPT = [
    STATUS_PANEL_PATH,
    SUMP_VIEW_PATH,
    ROOT / "scenes" / "tank" / "DisplayTankView.gd",
    ROOT / "scenes" / "tank" / "PipeNetworkView.gd",
    MAIN_PATH,
    GAME_STATE_PATH,
    TIME_PATH,
    WATER_PATH,
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

    for path in [STATUS_PANEL_PATH, SUMP_VIEW_PATH, MAIN_PATH, GAME_STATE_PATH, TIME_PATH, WATER_PATH, MAIN_SCENE_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    sump_text = SUMP_VIEW_PATH.read_text(encoding="utf-8") if SUMP_VIEW_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""
    combined_status_text = status_text + "\n" + scene_text

    missing_status_labels = [label for label in REQUIRED_STATUS_LABELS if label not in combined_status_text]
    if missing_status_labels:
        errors.append({"type": "missing_status_labels", "labels": missing_status_labels})

    missing_sump_labels = [label for label in REQUIRED_SUMP_LABELS if label not in sump_text]
    if missing_sump_labels:
        errors.append({"type": "missing_sump_compact_labels", "labels": missing_sump_labels})

    forbidden_sump_hits = [token for token in FORBIDDEN_SUMP_PRIMARY_TEXT if token in sump_text]
    if forbidden_sump_hits:
        errors.append({"type": "forbidden_raw_sump_text_found", "tokens": forbidden_sump_hits})

    for token in ["func _process(delta", "game_state.update(delta)", "update_water_chemistry_debug"]:
        if token not in main_text:
            errors.append({"type": "missing_main_update_flow", "token": token})

    for token in ["time_system.update_time(delta_seconds)", "water_chemistry_system.simulate_tick", "get_water_chemistry_debug_state", "elapsed_game_minutes"]:
        if token not in game_state_text:
            errors.append({"type": "missing_gamestate_dynamic_flow", "token": token})

    for token in ["chemistry_tick_count", "last_chemistry_update_time", "last_parameter_delta_summary"]:
        if token not in status_text and token not in WATER_PATH.read_text(encoding="utf-8"):
            errors.append({"type": "missing_dynamic_water_field", "token": token})

    variant_hits: list[dict[str, Any]] = []
    for path in SCAN_GDSCRIPT:
        if not path.exists():
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if ":=" in line:
                variant_hits.append({"path": str(path), "line": line_number, "text": line.strip()})
    if variant_hits:
        errors.append({"type": "variant_inference_operator_found", "hits": variant_hits})

    data_errors: list[dict[str, Any]] = []
    counts = {
        "species": sum(
            record_count(load_json(path, data_errors))
            for path in [
                ROOT / "data" / "species" / "corals_seed.json",
                ROOT / "data" / "species" / "fish_seed.json",
                ROOT / "data" / "species" / "legacy_species_extracted.json",
                ROOT / "data" / "species" / "tool_creatures_seed.json",
            ]
        ),
        "equipment": sum(
            record_count(load_json(path, data_errors))
            for path in [
                ROOT / "data" / "equipment" / "equipment_seed.json",
                ROOT / "data" / "equipment" / "tanks_seed.json",
            ]
        ),
        "tasks": record_count(load_json(ROOT / "data" / "tasks" / "maintenance_tasks_seed.json", data_errors)),
        "events": record_count(load_json(ROOT / "data" / "events" / "random_events_seed.json", data_errors)),
    }
    errors.extend(data_errors)
    if counts != {"species": 161, "equipment": 28, "tasks": 10, "events": 7}:
        errors.append({"type": "dataregistry_count_mismatch", "counts": counts})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "status_panel": str(STATUS_PANEL_PATH),
        "sump_view": str(SUMP_VIEW_PATH),
        "main": str(MAIN_PATH),
        "game_state": str(GAME_STATE_PATH),
        "dataregistry_counts": counts,
        "required_status_labels": REQUIRED_STATUS_LABELS,
        "required_sump_labels": REQUIRED_SUMP_LABELS,
        "forbidden_sump_hits": forbidden_sump_hits,
        "variant_inference_hit_count": len(variant_hits),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"UI readability dynamic update check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"UI readability dynamic update check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
