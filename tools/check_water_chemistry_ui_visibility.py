from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
MAIN_PATH = ROOT / "scenes" / "main" / "Main.gd"
REPORT_PATH = ROOT / "reports" / "m5_1_water_chemistry_ui_visibility_check_summary.json"

REQUIRED_CHINESE_LABELS = [
    "\u6c34\u8d28\u72b6\u6001",
    "\u6c34\u8d28\u8bc4\u5206",
    "\u6e29\u5ea6",
    "\u76d0\u5ea6",
    "pH",
    "NO3",
    "PO4",
    "KH",
    "Ca",
    "\u6a21\u62df",
    "\u5f53\u524d\u9636\u6bb5",
]

OLD_MILESTONE = "current milestone: M4 tier 1 equipment debug"

SCAN_GDSCRIPT = [
    STATUS_PANEL_PATH,
    MAIN_PATH,
    ROOT / "scripts" / "systems" / "TimeSystem.gd",
    ROOT / "scripts" / "systems" / "WaterChemistrySystem.gd",
    ROOT / "scripts" / "systems" / "GameState.gd",
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

    for path in [STATUS_PANEL_PATH, MAIN_SCENE_PATH, MAIN_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""
    combined_text = status_text + "\n" + scene_text

    missing_labels = [label for label in REQUIRED_CHINESE_LABELS if label not in combined_text]
    if missing_labels:
        errors.append({"type": "missing_chinese_labels", "labels": missing_labels})

    if OLD_MILESTONE in combined_text:
        errors.append({"type": "old_m4_milestone_still_visible", "text": OLD_MILESTONE})

    allowed_milestones = [
        "\u5f53\u524d\u9636\u6bb5\uff1aM5 \u6c34\u8d28\u6700\u5c0f\u6a21\u62df",
        "\u5f53\u524d\u9636\u6bb5\uff1aM6 \u751f\u7269\u627f\u8f7d\u4e0e\u6536\u76ca\u5faa\u73af",
        "\u5f53\u524d\u9636\u6bb5\uff1aM7 \u57fa\u7840\u89e3\u9501\u8fdb\u5ea6\u7cfb\u7edf",
    ]
    if not any(text in combined_text for text in allowed_milestones):
        errors.append({"type": "current_milestone_missing"})

    if "\u6a21\u62df\uff1a\u81ea\u52a8\u8fd0\u884c\u4e2d" not in combined_text:
        errors.append({"type": "simulation_running_label_missing"})

    if "\u65f6\u95f4\u500d\u7387\uff1a1\u79d2=10\u5206\u949f" not in combined_text:
        errors.append({"type": "time_scale_label_missing"})

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
        "main_scene": str(MAIN_SCENE_PATH),
        "required_chinese_labels": REQUIRED_CHINESE_LABELS,
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Water chemistry UI visibility check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Water chemistry UI visibility check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
