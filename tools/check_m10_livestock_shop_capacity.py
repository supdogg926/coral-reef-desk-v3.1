from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
LIVESTOCK_PATH = ROOT / "scripts" / "systems" / "LivestockSystem.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
SHOP_PATH = ROOT / "data" / "shop" / "initial_shop_seed.json"
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
REPORT_PATH = ROOT / "reports" / "m10_livestock_shop_capacity_check_summary.json"

REQUIRED_LIVESTOCK_FUNCTIONS = [
    "func add_livestock(",
    "func remove_livestock(",
    "func get_total_income_per_hour(",
    "func get_capacity_used()",
    "func export_state()",
    "func import_state(",
]

REQUIRED_UI_TEXT = [
    "\u751f\u7269\u6570\u91cf",
    "\u5bb9\u91cf",
    "\u7f38\u7b49\u7ea7",
    "\u57fa\u7840\u6536\u76ca",
    "\u6709\u6548\u6536\u76ca",
    "\u6c34\u8d28\u500d\u7387",
    "\u5065\u5eb7\u7cfb\u6570",
    "\u5f53\u524d\u9636\u6bb5\uff1aM10",
]

REQUIRED_SHOP_FIELDS = [
    "species_name",
    "category",
    "rarity",
    "price",
    "base_income_per_hour",
    "tank_slot_cost",
]

REQUIRED_SHOP_SPECIES = [
    "\u8367\u5149\u8349\u76ae",
    "\u95ea\u5343\u624b",
    "\u6d77\u8475",
    "\u7ebd\u6263\u73ca\u745a",
    "\u7eff\u706b\u67f4",
    "\u5b9d\u77f3\u82b1",
    "\u9524\u5934\u73ca\u745a",
    "\u516c\u5b50\u5c0f\u4e11",
    "\u84dd\u540a",
    "\u4e94\u5f69\u9752\u86d9",
]

FORBIDDEN_RARITY = ["\u8001\u7ec3"]

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
    LIVESTOCK_PATH,
    GAME_STATE_PATH,
    STATUS_PANEL_PATH,
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scripts" / "systems" / "SaveSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "UnlockSystem.gd",
    ROOT / "scenes" / "main" / "Main.gd",
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


def main() -> int:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    for path in [LIVESTOCK_PATH, GAME_STATE_PATH, STATUS_PANEL_PATH, SHOP_PATH, EQUIPMENT_TIERS_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    livestock_text = LIVESTOCK_PATH.read_text(encoding="utf-8") if LIVESTOCK_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""

    missing_funcs = [name for name in REQUIRED_LIVESTOCK_FUNCTIONS if name not in livestock_text]
    if missing_funcs:
        errors.append({"type": "missing_livestock_functions", "functions": missing_funcs})

    missing_ui = [text for text in REQUIRED_UI_TEXT if text not in status_text]
    if missing_ui:
        errors.append({"type": "missing_ui_text", "texts": missing_ui})

    if "buy_livestock_from_shop" not in game_state_text:
        errors.append({"type": "missing_buy_function"})

    if "livestock" not in game_state_text.lower():
        errors.append({"type": "gamestate_no_livestock_ref"})

    data_errors: list[dict[str, Any]] = []
    shop_data = load_json(SHOP_PATH, data_errors) if SHOP_PATH.exists() else []
    shop_records = shop_data if isinstance(shop_data, list) else []
    errors.extend(data_errors)

    shop_count = len([item for item in shop_records if isinstance(item, dict)])
    if shop_count != 10:
        errors.append({"type": "shop_species_count_mismatch", "expected": 10, "actual": shop_count})

    shop_names = {str(item.get("species_name", "")) for item in shop_records if isinstance(item, dict)}
    missing_species = [name for name in REQUIRED_SHOP_SPECIES if name not in shop_names]
    if missing_species:
        errors.append({"type": "missing_shop_species", "species": missing_species})

    for item in shop_records:
        if not isinstance(item, dict):
            continue
        rarity = str(item.get("rarity", ""))
        if rarity in FORBIDDEN_RARITY:
            errors.append({"type": "forbidden_rarity_found", "rarity": rarity, "item": item.get("species_name", "")})

    for name in FORBIDDEN_RARITY:
        if name in status_text:
            errors.append({"type": "forbidden_rarity_in_ui", "rarity": name})
    if "\u8001\u7ec3" in livestock_text:
        if "\"普通\", \"精品\", \"稀有\", \"大师\", \"传奇\"" not in livestock_text:
            errors.append({"type": "valid_rarities_missing_稀有"})

    for field in REQUIRED_SHOP_FIELDS:
        missing = [item.get("species_name", "?") for item in shop_records if isinstance(item, dict) and field not in item]
        if missing:
            errors.append({"type": "shop_missing_field", "field": field, "items": missing})

    equipment_data = load_json(EQUIPMENT_TIERS_PATH, data_errors) if EQUIPMENT_TIERS_PATH.exists() else []
    equipment_records = equipment_data if isinstance(equipment_data, list) else []
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
        "livestock_system": str(LIVESTOCK_PATH),
        "shop_path": str(SHOP_PATH),
        "shop_species_count": shop_count,
        "shop_species": sorted(shop_names),
        "default_max_capacity": 30.0,
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
        print(f"M10 livestock shop capacity check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M10 livestock shop capacity check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
