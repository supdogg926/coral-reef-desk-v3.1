from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
UNLOCK_PATH = ROOT / "scripts" / "systems" / "UnlockSystem.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
UNLOCK_DATA_PATH = ROOT / "data" / "unlocks" / "unlock_milestones_seed.json"
REPORT_PATH = ROOT / "reports" / "m7_basic_unlock_progression_check_summary.json"

REQUIRED_UNLOCK_FUNCTIONS = [
    "func initialize()",
    "func update_unlocks(economy_state: Dictionary)",
    "func get_current_stage()",
    "func get_next_unlock_target()",
    "func get_unlock_progress()",
    "func is_unlocked(unlock_id: String)",
    "func get_unlocked_preview_items()",
    "func get_locked_preview_items()",
    "func get_debug_state()",
]

REQUIRED_UI_TEXT = [
    "\u73a9\u5bb6\u9636\u6bb5",
    "\u4e0b\u4e2a\u76ee\u6807",
    "\u89e3\u9501\u8fdb\u5ea6",
    "\u5df2\u89e3\u9501",
    "\u9884\u89c8\u8bbe\u5907",
    "\u51b7\u6c34\u673a",
    "\u6740\u83cc\u706f",
    "\u85fb\u7f38\u706f",
    "\u9020\u6d41\u6cf5",
    "\u9ad8\u7ea7\u7cfb\u7edf\uff1a\u672a\u89e3\u9501",
]

FORBIDDEN_GAMEPLAY_TERMS = [
    "pipe_efficiency",
    "manual_pipe",
    "pipe_connection_gameplay",
    "free_drag",
    "drag_and_drop",
    "livestock_death",
    "kill_livestock",
    "breeding",
    "breed_",
    "growth",
    "grow_",
    "reproduction",
    "reproduce",
]

SCAN_GDSCRIPT = [
    UNLOCK_PATH,
    GAME_STATE_PATH,
    STATUS_PANEL_PATH,
    MAIN_PATH,
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentPlacementSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "LivestockSystem.gd",
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scenes" / "tank" / "PipeNetworkView.gd",
    ROOT / "scenes" / "tank" / "SumpView.gd",
    ROOT / "scenes" / "tank" / "DisplayTankView.gd",
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

    for path in [UNLOCK_PATH, GAME_STATE_PATH, STATUS_PANEL_PATH, MAIN_PATH, EQUIPMENT_TIERS_PATH, UNLOCK_DATA_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    unlock_text = UNLOCK_PATH.read_text(encoding="utf-8") if UNLOCK_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""

    missing_functions = [name for name in REQUIRED_UNLOCK_FUNCTIONS if name not in unlock_text]
    if missing_functions:
        errors.append({"type": "missing_unlock_functions", "functions": missing_functions})

    for token in ["UnlockSystem", "unlock_system", "update_unlocks", "get_unlock_debug_state"]:
        if token not in game_state_text:
            errors.append({"type": "missing_gamestate_unlock_reference", "token": token})

    if "update_unlock_debug" not in main_text:
        errors.append({"type": "missing_main_unlock_ui_binding"})

    missing_ui_text = [text for text in REQUIRED_UI_TEXT if text not in status_text and text not in unlock_text and text not in (UNLOCK_DATA_PATH.read_text(encoding="utf-8") if UNLOCK_DATA_PATH.exists() else "")]
    if missing_ui_text:
        errors.append({"type": "missing_unlock_ui_text", "texts": missing_ui_text})

    data_errors: list[dict[str, Any]] = []
    equipment_data = load_json(EQUIPMENT_TIERS_PATH, data_errors) if EQUIPMENT_TIERS_PATH.exists() else []
    equipment_records = equipment_data if isinstance(equipment_data, list) else []
    unlock_data = load_json(UNLOCK_DATA_PATH, data_errors) if UNLOCK_DATA_PATH.exists() else []
    unlock_records = unlock_data if isinstance(unlock_data, list) else []
    errors.extend(data_errors)

    tier2_bad: list[dict[str, Any]] = []
    tier3_bad: list[dict[str, Any]] = []
    tier2_effect_records: list[dict[str, Any]] = []
    for item in equipment_records:
        if not isinstance(item, dict):
            continue
        tier = int(item.get("tier", 0))
        effects = item.get("effects", {})
        has_nonzero_effect = False
        if isinstance(effects, dict):
            has_nonzero_effect = any(float(value) != 0.0 for value in effects.values() if isinstance(value, (int, float)))
        if tier == 2:
            if item.get("storage_state") == "installed" or item.get("installed_effective") is not False:
                tier2_bad.append({"id": item.get("id"), "storage_state": item.get("storage_state"), "installed_effective": item.get("installed_effective")})
            if has_nonzero_effect:
                tier2_effect_records.append({"id": item.get("id"), "effects": effects})
        elif tier == 3:
            if item.get("storage_state") != "locked" or item.get("installed_effective") is not False:
                tier3_bad.append({"id": item.get("id"), "storage_state": item.get("storage_state"), "installed_effective": item.get("installed_effective")})
    if tier2_bad:
        errors.append({"type": "tier2_installed_or_effective", "records": tier2_bad})
    if tier3_bad:
        errors.append({"type": "tier3_not_locked", "records": tier3_bad})
    if tier2_effect_records:
        errors.append({"type": "tier2_nonzero_effects", "records": tier2_effect_records})

    unlock_ids = {str(item.get("unlock_id")) for item in unlock_records if isinstance(item, dict)}
    required_unlock_ids = {
        "tier1_running",
        "tier2_equipment_preview",
        "tier2_sump_space_preview",
        "tier3_advanced_system_preview",
    }
    if unlock_ids != required_unlock_ids:
        errors.append({"type": "unlock_id_mismatch", "expected": sorted(required_unlock_ids), "actual": sorted(unlock_ids)})

    forbidden_hits: list[dict[str, Any]] = []
    for path in SCAN_GDSCRIPT:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8").lower()
        for term in FORBIDDEN_GAMEPLAY_TERMS:
            if term.lower() in text:
                forbidden_hits.append({"path": str(path), "term": term})
    if forbidden_hits:
        errors.append({"type": "forbidden_gameplay_terms", "hits": forbidden_hits})

    variant_hits: list[dict[str, Any]] = []
    for path in SCAN_GDSCRIPT:
        if not path.exists():
            continue
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if ":=" in line:
                variant_hits.append({"path": str(path), "line": line_number, "text": line.strip()})
    if variant_hits:
        errors.append({"type": "variant_inference_operator_found", "hits": variant_hits})

    count_errors: list[dict[str, Any]] = []
    counts = {
        "species": sum(
            record_count(load_json(path, count_errors))
            for path in [
                ROOT / "data" / "species" / "corals_seed.json",
                ROOT / "data" / "species" / "fish_seed.json",
                ROOT / "data" / "species" / "legacy_species_extracted.json",
                ROOT / "data" / "species" / "tool_creatures_seed.json",
            ]
        ),
        "equipment": sum(
            record_count(load_json(path, count_errors))
            for path in [
                ROOT / "data" / "equipment" / "equipment_seed.json",
                ROOT / "data" / "equipment" / "tanks_seed.json",
            ]
        ),
        "tasks": record_count(load_json(ROOT / "data" / "tasks" / "maintenance_tasks_seed.json", count_errors)),
        "events": record_count(load_json(ROOT / "data" / "events" / "random_events_seed.json", count_errors)),
    }
    errors.extend(count_errors)
    if counts != {"species": 161, "equipment": 28, "tasks": 10, "events": 7}:
        errors.append({"type": "dataregistry_count_mismatch", "counts": counts})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "unlock_system": str(UNLOCK_PATH),
        "unlock_data": str(UNLOCK_DATA_PATH),
        "unlock_ids": sorted(unlock_ids),
        "tier2_bad_count": len(tier2_bad),
        "tier3_bad_count": len(tier3_bad),
        "tier2_effect_record_count": len(tier2_effect_records),
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Basic unlock progression check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Basic unlock progression check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
