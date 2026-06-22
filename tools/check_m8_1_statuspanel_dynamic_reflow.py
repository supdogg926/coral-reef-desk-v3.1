from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
UNLOCK_DATA_PATH = ROOT / "data" / "unlocks" / "unlock_milestones_seed.json"
REPORT_PATH = ROOT / "reports" / "m8_1_statuspanel_dynamic_reflow_check_summary.json"

REQUIRED_UI_TEXT = [
    "\u6c34\u53d8A",
    "\u6c34\u53d8B",
    "\u6536\u53d8A",
    "\u6536\u53d8B",
    "\u4ed3\u5e93",
    "\u9ad8\u7ea7\uff1a\u672a\u89e3\u9501",
    "\u5f53\u524d\u9636\u6bb5\uff1aM8",
]

REQUIRED_DELTA_LABELS = [
    "\u6e29",
    "\u76d0",
    "pH",
    "NO3",
    "PO4",
    "KH",
    "Ca",
    "\u8bc4",
    "RP",
    "\u4ef7\u503c",
    "\u6536\u76ca",
    "\u5065\u5eb7",
    "\u6c34\u8d28\u6536\u76ca",
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
    STATUS_PANEL_PATH,
    ROOT / "scripts" / "systems" / "GameState.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentSystem.gd",
    ROOT / "scripts" / "systems" / "EquipmentPlacementSystem.gd",
    ROOT / "scripts" / "systems" / "LivestockSystem.gd",
    ROOT / "scripts" / "systems" / "UnlockSystem.gd",
    ROOT / "scripts" / "systems" / "TimeSystem.gd",
    ROOT / "scenes" / "main" / "Main.gd",
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

    for path in [STATUS_PANEL_PATH, EQUIPMENT_TIERS_PATH, UNLOCK_DATA_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""

    missing_ui = [text for text in REQUIRED_UI_TEXT if text not in status_text]
    if missing_ui:
        errors.append({"type": "missing_ui_text", "texts": missing_ui})

    missing_labels = [label for label in REQUIRED_DELTA_LABELS if label not in status_text]
    if missing_labels:
        errors.append({"type": "missing_delta_labels", "labels": missing_labels})

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
                tier2_bad.append({"id": item.get("id"), "storage_state": item.get("storage_state"), "installed_effective": item.get("installed_effective")})
        elif tier == 3:
            if item.get("storage_state") != "locked" or item.get("installed_effective") is not False:
                tier3_bad.append({"id": item.get("id"), "storage_state": item.get("storage_state"), "installed_effective": item.get("installed_effective")})
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
        "status_panel": str(STATUS_PANEL_PATH),
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
        print(f"M8.1 StatusPanel dynamic reflow check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M8.1 StatusPanel dynamic reflow check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
