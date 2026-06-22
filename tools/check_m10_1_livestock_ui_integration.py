from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SHOP_PANEL_PATH = ROOT / "scenes" / "ui" / "ShopPanel.gd"
LIVESTOCK_PANEL_PATH = ROOT / "scenes" / "ui" / "LivestockPanel.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
GAME_STATE_PATH = ROOT / "scripts" / "systems" / "GameState.gd"
LIVESTOCK_PATH = ROOT / "scripts" / "systems" / "LivestockSystem.gd"
SHOP_DATA_PATH = ROOT / "data" / "shop" / "initial_shop_seed.json"
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
REPORT_PATH = ROOT / "reports" / "m10_1_livestock_ui_integration_check_summary.json"

REQUIRED_UI_TEXT = [
    "\u751f\u7269\u5546\u5e97",
    "\u6211\u7684\u751f\u7269",
    "\u5e26\u56de\u5bb6",
    "\u5bb9\u91cf\u4e0d\u8db3",
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
    "reproduction",
    "reproduce",
]

SCAN_GDSCRIPT = [
    SHOP_PANEL_PATH,
    LIVESTOCK_PANEL_PATH,
    MAIN_PATH,
    STATUS_PANEL_PATH,
    GAME_STATE_PATH,
    LIVESTOCK_PATH,
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scripts" / "systems" / "SaveSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "UnlockSystem.gd",
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

    for path in [SHOP_PANEL_PATH, LIVESTOCK_PANEL_PATH, MAIN_PATH, STATUS_PANEL_PATH, GAME_STATE_PATH, SHOP_DATA_PATH, EQUIPMENT_TIERS_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    shop_text = SHOP_PANEL_PATH.read_text(encoding="utf-8") if SHOP_PANEL_PATH.exists() else ""
    livestock_panel_text = LIVESTOCK_PANEL_PATH.read_text(encoding="utf-8") if LIVESTOCK_PANEL_PATH.exists() else ""
    main_text = MAIN_PATH.read_text(encoding="utf-8") if MAIN_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    game_state_text = GAME_STATE_PATH.read_text(encoding="utf-8") if GAME_STATE_PATH.exists() else ""

    missing_ui = [text for text in REQUIRED_UI_TEXT if text not in (main_text + shop_text + livestock_panel_text)]
    if missing_ui:
        errors.append({"type": "missing_ui_text", "texts": missing_ui})

    if "ShopPanel" not in main_text:
        errors.append({"type": "main_missing_shoppanel"})
    if "LivestockPanel" not in main_text:
        errors.append({"type": "main_missing_livestockpanel"})

    if "buy_livestock_from_shop" not in shop_text:
        errors.append({"type": "shop_missing_buy_call"})

    if "get_shop_items" not in shop_text:
        errors.append({"type": "shop_missing_data_call"})

    if "owned_livestock" not in livestock_panel_text:
        errors.append({"type": "livestockpanel_missing_owned"})

    if "has(\"owned_livestock\")" not in game_state_text:
        warnings.append({"type": "gamestate_missing_save_guard", "note": "starter livestock may be wiped by empty save"})

    data_errors: list[dict[str, Any]] = []
    shop_data = load_json(SHOP_DATA_PATH, data_errors) if SHOP_DATA_PATH.exists() else []
    shop_records = shop_data if isinstance(shop_data, list) else []
    errors.extend(data_errors)

    shop_count = len([item for item in shop_records if isinstance(item, dict)])
    if shop_count != 10:
        errors.append({"type": "shop_species_count", "expected": 10, "actual": shop_count})

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
        "shop_panel": str(SHOP_PANEL_PATH),
        "livestock_panel": str(LIVESTOCK_PANEL_PATH),
        "shop_species_count": shop_count,
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
        print(f"M10.1 livestock UI integration check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M10.1 livestock UI integration check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
