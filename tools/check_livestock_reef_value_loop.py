from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
LIVESTOCK_PATH = ROOT / "scripts" / "systems" / "LivestockSystem.gd"
ECONOMY_PATH = ROOT / "scripts" / "systems" / "EconomySystem.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
STARTER_LIVESTOCK_PATH = ROOT / "data" / "livestock" / "starter_livestock_seed.json"
REPORT_PATH = ROOT / "reports" / "m6_livestock_reef_value_check_summary.json"

REQUIRED_LIVESTOCK_FUNCTIONS = [
    "func initialize()",
    "func load_starter_livestock(",
    "func get_livestock_count()",
    "func get_capacity_used()",
    "func get_capacity_limit()",
    "func get_capacity_status()",
    "func calculate_livestock_health_modifier(water_chemistry_state: Dictionary)",
    "func calculate_reef_value(water_chemistry_state: Dictionary, carrying_capacity_score: float)",
    "func calculate_income_rate(water_chemistry_state: Dictionary, carrying_capacity_score: float)",
    "func get_debug_state()",
]

REQUIRED_ECONOMY_FUNCTIONS = [
    "func initialize()",
    "func update_income(delta_seconds: float, income_rate: float)",
    "func add_reef_points(amount: float)",
    "func spend_reef_points(amount: float)",
    "func get_reef_points()",
    "func get_debug_state()",
]

REQUIRED_UI_TEXT = [
    "\u751f\u7269\u6570\u91cf",
    "\u627f\u8f7d\u4f7f\u7528",
    "\u627f\u8f7d\u72b6\u6001",
    "\u73ca\u745a\u7f38\u4ef7\u503c",
    "Reef Points",
    "\u6536\u76ca\u901f\u5ea6",
    "\u751f\u7269\u5065\u5eb7\u7cfb\u6570",
    "\u6c34\u8d28\u6536\u76ca\u7cfb\u6570",
    "\u5f53\u524d\u9636\u6bb5\uff1aM7 \u57fa\u7840\u89e3\u9501\u8fdb\u5ea6\u7cfb\u7edf",
]

FORBIDDEN_SIMULATION_TERMS = [
    "livestock_death",
    "kill_livestock",
    "remove_dead",
    "breeding",
    "breed_",
    "growth",
    "grow_",
    "reproduction",
    "reproduce",
]

FORBIDDEN_TIER_UNLOCK_TERMS = [
    "unlock_equipment(",
    "unlocked_tier = 2",
    "unlocked_tier = 3",
    "tier2_unlocked",
    "tier3_unlocked",
]

FORBIDDEN_PLUMBING_OR_DRAG_TERMS = [
    "pipe_efficiency",
    "manual_pipe",
    "auto_route",
    "pipe_connection_gameplay",
    "free_drag",
    "drag_and_drop",
    "start_drag",
]

SCAN_GDSCRIPT = [
    LIVESTOCK_PATH,
    ECONOMY_PATH,
    GAME_STATE_PATH,
    STATUS_PANEL_PATH,
    MAIN_PATH,
    ROOT / "scripts" / "systems" / "TimeSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentPlacementSystem.gd",
    ROOT / "scenes" / "tank" / "DisplayTankView.gd",
    ROOT / "scenes" / "tank" / "SumpView.gd",
    ROOT / "scenes" / "tank" / "PipeNetworkView.gd",
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


def find_terms(text: str, terms: list[str]) -> list[str]:
    lower_text = text.lower()
    return [term for term in terms if term.lower() in lower_text]


def main() -> int:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    for path in [LIVESTOCK_PATH, ECONOMY_PATH, GAME_STATE_PATH, STATUS_PANEL_PATH, MAIN_PATH, MAIN_SCENE_PATH, STARTER_LIVESTOCK_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    livestock_text = LIVESTOCK_PATH.read_text(encoding="utf-8") if LIVESTOCK_PATH.exists() else ""
    economy_text = ECONOMY_PATH.read_text(encoding="utf-8") if ECONOMY_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""

    missing_livestock_functions = [name for name in REQUIRED_LIVESTOCK_FUNCTIONS if name not in livestock_text]
    if missing_livestock_functions:
        errors.append({"type": "missing_livestock_functions", "functions": missing_livestock_functions})

    missing_economy_functions = [name for name in REQUIRED_ECONOMY_FUNCTIONS if name not in economy_text]
    if missing_economy_functions:
        errors.append({"type": "missing_economy_functions", "functions": missing_economy_functions})

    for token in ["LivestockSystem", "EconomySystem", "livestock_system", "economy_system", "update_income", "calculate_income_rate"]:
        if token not in game_state_text:
            errors.append({"type": "missing_gamestate_reference", "token": token})

    for token in ["update_livestock_economy_debug", "get_livestock_debug_state", "get_economy_debug_state"]:
        if token not in main_text and token not in game_state_text:
            errors.append({"type": "missing_ui_update_binding", "token": token})

    combined_ui_text = status_text + "\n" + scene_text
    missing_ui_text = [text for text in REQUIRED_UI_TEXT if text not in combined_ui_text]
    if missing_ui_text:
        errors.append({"type": "missing_ui_text", "texts": missing_ui_text})

    data_errors: list[dict[str, Any]] = []
    starter_data = load_json(STARTER_LIVESTOCK_PATH, data_errors) if STARTER_LIVESTOCK_PATH.exists() else []
    starter_records = starter_data if isinstance(starter_data, list) else []
    errors.extend(data_errors)
    enabled_starter_count = len([item for item in starter_records if isinstance(item, dict) and item.get("enabled") is True])
    if enabled_starter_count < 5:
        errors.append({"type": "starter_livestock_count_too_low", "count": enabled_starter_count})

    forbidden_text_corpus = "\n".join([livestock_text, economy_text, game_state_text, status_text, main_text])
    forbidden_simulation_hits = find_terms(forbidden_text_corpus, FORBIDDEN_SIMULATION_TERMS)
    if forbidden_simulation_hits:
        errors.append({"type": "forbidden_simulation_terms", "terms": forbidden_simulation_hits})

    forbidden_tier_unlock_hits = find_terms("\n".join([livestock_text, economy_text, game_state_text, main_text]), FORBIDDEN_TIER_UNLOCK_TERMS)
    if forbidden_tier_unlock_hits:
        errors.append({"type": "forbidden_tier_unlock_terms", "terms": forbidden_tier_unlock_hits})

    forbidden_plumbing_or_drag_hits = find_terms("\n".join([livestock_text, economy_text, game_state_text, main_text]), FORBIDDEN_PLUMBING_OR_DRAG_TERMS)
    if forbidden_plumbing_or_drag_hits:
        errors.append({"type": "forbidden_plumbing_or_drag_terms", "terms": forbidden_plumbing_or_drag_hits})

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
        "files": {
            "livestock_system": str(LIVESTOCK_PATH),
            "economy_system": str(ECONOMY_PATH),
            "game_state": str(GAME_STATE_PATH),
            "status_panel": str(STATUS_PANEL_PATH),
            "starter_livestock": str(STARTER_LIVESTOCK_PATH),
        },
        "starter_livestock_count": len(starter_records),
        "enabled_starter_livestock_count": enabled_starter_count,
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "forbidden_simulation_hits": forbidden_simulation_hits,
        "forbidden_tier_unlock_hits": forbidden_tier_unlock_hits,
        "forbidden_plumbing_or_drag_hits": forbidden_plumbing_or_drag_hits,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Livestock reef value loop check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Livestock reef value loop check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
