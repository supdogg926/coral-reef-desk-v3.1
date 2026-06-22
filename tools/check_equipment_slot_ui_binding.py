from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
EQUIPMENT_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
SUMP_VIEW_PATH = ROOT / "scenes" / "tank" / "SumpView.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
REPORT_PATH = ROOT / "reports" / "m4_1_equipment_slot_ui_binding_check_summary.json"

REQUIRED_TIER1 = {
    "filter_sock": "slot_mech_01",
    "protein_skimmer": "slot_skimmer_01",
    "refugium": "slot_refugium_01",
    "return_pump": "slot_return_01",
    "live_rock": "slot_display_rock_01",
    "filter_media": "slot_mech_media_01",
    "heater": "slot_return_heater_01",
}

REQUIRED_UI_TEXT = [
    "\u521d\u7ea7\u8bbe\u5907",
    "\u7a33\u5b9a\u5ea6",
    "\u627f\u8f7d\u529b",
    "\u7ef4\u62a4\u8d1f\u62c5",
    "\u7ba1\u8def\uff1a\u9690\u5f0f\u8fde\u63a5",
    "\u7ba1\u8def\u73a9\u6cd5\uff1a\u5173\u95ed",
    "\u6570\u636e\uff1a\u7269\u79cd161\uff5c\u8bbe\u590728\uff5c\u4efb\u52a110\uff5c\u4e8b\u4ef67",
    "\u6821\u9a8c\uff1aload=OK\uff5cerrors=0",
    "\u4ed3\u5e93",
    "\u9501\u5b9a",
    "\u6ee4\u888b\uff5c\u5df2\u88c5",
    "\u86cb\u5206\uff5c\u5df2\u88c5",
    "\u85fb\u7f38\uff5c\u5df2\u88c5",
]


def load_json(path: Path, errors: list[dict[str, Any]]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:  # noqa: BLE001
        errors.append({"type": "json_error", "path": str(path), "message": str(exc)})
        return None


def main() -> int:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []

    for path in [EQUIPMENT_PATH, SUMP_VIEW_PATH, STATUS_PANEL_PATH, MAIN_SCENE_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    equipment_data = load_json(EQUIPMENT_PATH, errors) if EQUIPMENT_PATH.exists() else []
    equipment = equipment_data if isinstance(equipment_data, list) else []
    tier1 = [item for item in equipment if isinstance(item, dict) and item.get("tier") == 1]
    locked = [item for item in equipment if isinstance(item, dict) and item.get("storage_state") == "locked"]
    tier2_or_tier3_locked = [
        item
        for item in equipment
        if isinstance(item, dict) and item.get("tier") in [2, 3] and item.get("storage_state") == "locked"
    ]

    if len(tier1) != 7:
        errors.append({"type": "tier1_count_mismatch", "expected": 7, "actual": len(tier1)})

    installed_tier1 = [item for item in tier1 if item.get("storage_state") == "installed"]
    if len(installed_tier1) != 7:
        errors.append({"type": "tier1_installed_count_mismatch", "expected": 7, "actual": len(installed_tier1)})

    if len(tier2_or_tier3_locked) <= 0:
        errors.append({"type": "locked_tier2_tier3_missing"})

    bad_pipe_required = [item.get("id") for item in equipment if isinstance(item, dict) and item.get("pipe_connection_required") is not False]
    if bad_pipe_required:
        errors.append({"type": "pipe_connection_required_not_false", "equipment": bad_pipe_required})

    bad_implicit = [item.get("id") for item in equipment if isinstance(item, dict) and item.get("implicit_plumbing") is not True]
    if bad_implicit:
        errors.append({"type": "implicit_plumbing_not_true", "equipment": bad_implicit})

    slot_mismatches: list[dict[str, Any]] = []
    equipment_by_id = {str(item.get("id")): item for item in equipment if isinstance(item, dict)}
    for equipment_id, slot_id in REQUIRED_TIER1.items():
        item = equipment_by_id.get(equipment_id, {})
        if item.get("slot_id") != slot_id:
            slot_mismatches.append({"equipment_id": equipment_id, "expected": slot_id, "actual": item.get("slot_id")})
        if item.get("installed_effective") is not True:
            slot_mismatches.append({"equipment_id": equipment_id, "expected": "installed_effective true", "actual": item.get("installed_effective")})
    if slot_mismatches:
        errors.append({"type": "slot_mismatches", "records": slot_mismatches})

    ui_text = ""
    for path in [SUMP_VIEW_PATH, STATUS_PANEL_PATH, MAIN_SCENE_PATH]:
        if path.exists():
            ui_text += path.read_text(encoding="utf-8") + "\n"

    missing_ui_text = [text for text in REQUIRED_UI_TEXT if text not in ui_text]
    if missing_ui_text:
        errors.append({"type": "missing_ui_text", "texts": missing_ui_text})

    if not (ROOT / "reports" / "m4_1_equipment_slot_ui_binding_report.md").exists():
        warnings.append({"type": "report_not_generated_yet", "path": str(ROOT / "reports" / "m4_1_equipment_slot_ui_binding_report.md")})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "tier1_count": len(tier1),
        "tier1_installed_count": len(installed_tier1),
        "locked_tier2_tier3_count": len(tier2_or_tier3_locked),
        "warehouse_count": len([item for item in equipment if isinstance(item, dict) and item.get("storage_state") == "warehouse"]),
        "locked_count": len(locked),
        "required_ui_files": [str(SUMP_VIEW_PATH), str(STATUS_PANEL_PATH), str(MAIN_SCENE_PATH)],
        "required_tier1_slots": REQUIRED_TIER1,
        "pipe_connection_required_false_for_all": len(bad_pipe_required) == 0,
        "implicit_plumbing_true_for_all": len(bad_implicit) == 0,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Equipment slot UI binding check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Equipment slot UI binding check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
