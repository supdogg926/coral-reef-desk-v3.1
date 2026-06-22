from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
SUMP_VIEW_PATH = ROOT / "scenes" / "tank" / "SumpView.gd"
DISPLAY_VIEW_PATH = ROOT / "scenes" / "tank" / "DisplayTankView.gd"
PIPE_VIEW_PATH = ROOT / "scenes" / "tank" / "PipeNetworkView.gd"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
M6_SUMMARY_PATH = ROOT / "reports" / "m6_livestock_reef_value_check_summary.json"
REPORT_PATH = ROOT / "reports" / "m6_1_ui_layout_cleanup_check_summary.json"

REQUIRED_STATUS_TEXT = [
    "\u6570\u636e\u4e0e\u9636\u6bb5",
    "\u6570\u636e\uff1a",
    "\u6821\u9a8c\uff1a",
    "\u5f53\u524d\u9636\u6bb5\uff1aM8 \u4ed3\u5e93\u9884\u89c8\u4e0e\u5168\u91cf\u53d8\u5316\u663e\u793a",
    "\u6c34\u8d28",
    "\u6c34\u8d28\u8bc4\u5206",
    "\u7cfb\u7edf",
    "\u521d\u7ea7\u8bbe\u5907",
    "\u7a33\u5b9a\u5ea6",
    "\u627f\u8f7d\u529b",
    "\u751f\u7269\u4e0e\u6536\u76ca",
    "\u751f\u7269\u6570\u91cf",
    "\u627f\u8f7d\u4f7f\u7528",
    "\u73ca\u745a\u7f38\u4ef7\u503c",
    "Reef Points",
    "\u6536\u76ca\u901f\u5ea6",
    "\u751f\u7269\u5065\u5eb7\u7cfb\u6570",
    "\u6c34\u8d28\u6536\u76ca\u7cfb\u6570",
    "\u52a8\u6001\u786e\u8ba4",
    "\u6a21\u62df",
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
    "\u5e95\u7f38 / \u67cf\u6797\u7cfb\u7edf",
    "ATO \u8865\u6c34\u4ed3",
]

FORBIDDEN_SUMP_TEXT = [
    "storage_state=installed",
    "effective=true",
    "slot_mech_01",
    "slot_skimmer_01",
    "slot_refugium_01",
    "slot_return_01",
]

SCAN_GDSCRIPT = [
    STATUS_PANEL_PATH,
    SUMP_VIEW_PATH,
    DISPLAY_VIEW_PATH,
    PIPE_VIEW_PATH,
    MAIN_PATH,
    ROOT / "scripts" / "systems" / "GameState.gd",
    ROOT / "scripts" / "systems" / "LivestockSystem.gd",
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
    ROOT / "scripts" / "systems" / "TimeSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
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

    for path in [STATUS_PANEL_PATH, SUMP_VIEW_PATH, MAIN_SCENE_PATH, M6_SUMMARY_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    sump_text = SUMP_VIEW_PATH.read_text(encoding="utf-8") if SUMP_VIEW_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""

    for token in ["_build_status_layout", "_create_section", "GridContainer", "columns = 4"]:
        if token not in status_text:
            errors.append({"type": "statuspanel_not_structured", "token": token})

    missing_status_text = [text for text in REQUIRED_STATUS_TEXT if text not in status_text and text not in scene_text]
    if missing_status_text:
        errors.append({"type": "missing_status_text", "texts": missing_status_text})

    missing_sump_labels = [text for text in REQUIRED_SUMP_LABELS if text not in sump_text]
    if missing_sump_labels:
        errors.append({"type": "missing_sump_label", "texts": missing_sump_labels})

    forbidden_sump_hits = [text for text in FORBIDDEN_SUMP_TEXT if text in sump_text]
    if forbidden_sump_hits:
        errors.append({"type": "forbidden_sump_text", "texts": forbidden_sump_hits})

    if "draw_string(font, pos" in sump_text:
        errors.append({"type": "old_loose_sump_slot_draw_string_found"})

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

    m6_summary = load_json(M6_SUMMARY_PATH, errors) if M6_SUMMARY_PATH.exists() else {}
    m6_passed = bool(isinstance(m6_summary, dict) and m6_summary.get("passed") is True)
    if not m6_passed:
        errors.append({"type": "m6_checker_not_passed", "path": str(M6_SUMMARY_PATH)})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "status_panel": str(STATUS_PANEL_PATH),
        "sump_view": str(SUMP_VIEW_PATH),
        "m6_summary": str(M6_SUMMARY_PATH),
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "forbidden_sump_hits": forbidden_sump_hits,
        "m6_checker_passed": m6_passed,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"M6.1 UI layout cleanup check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M6.1 UI layout cleanup check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
