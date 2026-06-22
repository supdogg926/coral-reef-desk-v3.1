from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SAVE_SYSTEM_PATH = ROOT / "scripts" / "systems" / "SaveSystem.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
REPORT_PATH = ROOT / "reports" / "m9_save_load_offline_progression_check_summary.json"

REQUIRED_SAVE_FUNCTIONS = [
    "func initialize()",
    "func save_game(",
    "func load_game()",
    "func has_save_file()",
    "func clear_save()",
    "func get_save_path()",
    "func get_last_save_timestamp()",
    "func calculate_offline_seconds(",
    "func get_debug_state()",
]

REQUIRED_UI_TEXT = [
    "\u5b58\u6863",
    "\u81ea\u52a8\u5b58\u6863",
    "\u6700\u8fd1\uff1a",
    "\u79bb\u7ebf\u65f6\u957f",
    "\u79bb\u7ebf\u6536\u76ca",
]

FORBIDDEN_GAMEPLAY_TERMS = [
    "livestock_death",
    "kill_livestock",
    "breeding",
    "breed_",
    "growth",
    "grow_",
    "reproduction",
    "reproduce",
    "pipe_efficiency",
    "manual_pipe",
    "pipe_connection_gameplay",
    "free_drag",
    "drag_and_drop",
]

SCAN_GDSCRIPT = [
    SAVE_SYSTEM_PATH,
    GAME_STATE_PATH,
    STATUS_PANEL_PATH,
    MAIN_PATH,
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "TimeSystem.gd",
    ROOT / "scripts" / "systems" / "UnlockSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentPlacementSystem.gd",
    ROOT / "scripts" / "systems" / "LivestockSystem.gd",
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

    for path in [SAVE_SYSTEM_PATH, GAME_STATE_PATH, STATUS_PANEL_PATH, MAIN_PATH, EQUIPMENT_TIERS_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    save_text = SAVE_SYSTEM_PATH.read_text(encoding="utf-8") if SAVE_SYSTEM_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""

    missing_funcs = [name for name in REQUIRED_SAVE_FUNCTIONS if name not in save_text]
    if missing_funcs:
        errors.append({"type": "missing_save_functions", "functions": missing_funcs})

    if "user://reef_idle_v3_save.json" not in save_text:
        errors.append({"type": "missing_save_path"})

    for token in ["SaveSystem", "save_system", "autosave", "offline"]:
        if token not in game_state_text:
            errors.append({"type": "missing_gamestate_save_token", "token": token})

    for token in ["update_save_debug", "get_save_debug_state"]:
        if token not in main_text:
            errors.append({"type": "missing_main_save_binding", "token": token})

    missing_ui = [text for text in REQUIRED_UI_TEXT if text not in status_text]
    if missing_ui:
        errors.append({"type": "missing_save_ui_text", "texts": missing_ui})

    data_errors: list[dict[str, Any]] = []
    equipment_data = load_json(EQUIPMENT_TIERS_PATH, data_errors) if EQUIPMENT_TIERS_PATH.exists() else []
    equipment_records = equipment_data if isinstance(equipment_data, list) else []
    errors.extend(data_errors)

    tier2_bad: list[dict[str, Any]] = []
    tier3_bad: list[dict[str, Any]] = []
    for item in equipment_records:
        if not isinstance(item, dict):
            continue
        tier = int(item.get("tier", 0))
        if tier == 2:
            if item.get("storage_state") == "installed" or item.get("installed_effective") is not False:
                tier2_bad.append({"id": item.get("id")})
        elif tier == 3:
            if item.get("storage_state") != "locked" or item.get("installed_effective") is not False:
                tier3_bad.append({"id": item.get("id")})
    if tier2_bad:
        errors.append({"type": "tier2_installed_or_effective", "records": tier2_bad})
    if tier3_bad:
        errors.append({"type": "tier3_not_locked", "records": tier3_bad})

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
        "save_system": str(SAVE_SYSTEM_PATH),
        "save_path": "user://reef_idle_v3_save.json",
        "tier2_bad_count": len(tier2_bad),
        "tier3_bad_count": len(tier3_bad),
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"M9 save load offline progression check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M9 save load offline progression check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
