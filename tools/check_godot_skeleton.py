from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REPORT_PATH = ROOT / "reports" / "m1_skeleton_check_summary.json"

DATA_FILES = [
    ROOT / "data" / "species" / "corals_seed.json",
    ROOT / "data" / "species" / "fish_seed.json",
    ROOT / "data" / "species" / "legacy_species_extracted.json",
    ROOT / "data" / "species" / "tool_creatures_seed.json",
    ROOT / "data" / "equipment" / "equipment_seed.json",
    ROOT / "data" / "equipment" / "tanks_seed.json",
    ROOT / "data" / "tasks" / "maintenance_tasks_seed.json",
    ROOT / "data" / "events" / "random_events_seed.json",
    ROOT / "data" / "formulas" / "formulas_seed.json",
]


def load_json(path: Path, errors: list[dict[str, Any]]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:  # noqa: BLE001 - validation report should keep going.
        errors.append({"path": str(path), "type": "json_error", "message": str(exc)})
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
    files: dict[str, str] = {
        "project": str(ROOT / "project.godot"),
        "main_scene": str(ROOT / "scenes" / "main" / "Main.tscn"),
        "data_registry": str(ROOT / "scripts" / "autoload" / "DataRegistry.gd"),
        "main_script": str(ROOT / "scenes" / "main" / "Main.gd"),
        "smoke_test": str(ROOT / "tests" / "smoke_test.gd"),
        "validation_summary": str(ROOT / "reports" / "validation_summary.json"),
    }

    for label, path_text in files.items():
        path = Path(path_text)
        if not path.exists():
            errors.append({"type": "missing_file", "label": label, "path": str(path)})

    project_text = (ROOT / "project.godot").read_text(encoding="utf-8") if (ROOT / "project.godot").exists() else ""
    if 'config/name="CoralReefIdleV3"' not in project_text:
        errors.append({"type": "project_config_missing", "field": "config/name"})
    if 'run/main_scene="res://scenes/main/Main.tscn"' not in project_text:
        errors.append({"type": "project_config_missing", "field": "run/main_scene"})
    if 'DataRegistry="*res://scripts/autoload/DataRegistry.gd"' not in project_text:
        errors.append({"type": "autoload_missing", "autoload": "DataRegistry"})

    scene_text = (ROOT / "scenes" / "main" / "Main.tscn").read_text(encoding="utf-8") if (ROOT / "scenes" / "main" / "Main.tscn").exists() else ""
    status_panel_text = (ROOT / "scenes" / "ui" / "StatusPanel.gd").read_text(encoding="utf-8") if (ROOT / "scenes" / "ui" / "StatusPanel.gd").exists() else ""
    scene_and_status_text = scene_text + "\n" + status_panel_text
    for required_text in [
        '[node name="Main" type="Control"]',
        "DisplayTankView",
        "SumpView",
        "PipeNetworkView",
        "CoralReefIdleV3 - \u67cf\u6797\u7cfb\u7edf\u9759\u6001\u5e03\u5c40",
        "\u6570\u636e\uff1a\u7269\u79cd",
        "\u6821\u9a8c\uff1aload",
    ]:
        if required_text not in scene_and_status_text:
            errors.append({"type": "main_scene_missing_text", "text": required_text})

    registry_text = (ROOT / "scripts" / "autoload" / "DataRegistry.gd").read_text(encoding="utf-8") if (ROOT / "scripts" / "autoload" / "DataRegistry.gd").exists() else ""
    for method in [
        "func get_species_count()",
        "func get_equipment_count()",
        "func get_task_count()",
        "func get_event_count()",
        "func get_species_by_id(id: String)",
        "func get_equipment_by_id(id: String)",
        "func get_task_by_id(id: String)",
        "func get_load_errors()",
        "func is_loaded_ok()",
    ]:
        if method not in registry_text:
            errors.append({"type": "data_registry_missing_method", "method": method})

    loaded_data: dict[str, Any] = {}
    for path in DATA_FILES:
        if not path.exists():
            errors.append({"type": "missing_data_file", "path": str(path)})
            continue
        loaded_data[str(path)] = load_json(path, errors)

    species_count = sum(
        record_count(loaded_data.get(str(path), []))
        for path in DATA_FILES
        if "\\data\\species\\" in str(path) or "/data/species/" in str(path)
    )
    equipment_count = sum(
        record_count(loaded_data.get(str(path), []))
        for path in DATA_FILES
        if "\\data\\equipment\\" in str(path) or "/data/equipment/" in str(path)
    )
    task_data = loaded_data.get(str(ROOT / "data" / "tasks" / "maintenance_tasks_seed.json"), [])
    event_data = loaded_data.get(str(ROOT / "data" / "events" / "random_events_seed.json"), [])
    task_count = record_count(task_data)
    event_count = record_count(event_data)

    reward_residue: list[dict[str, Any]] = []
    if isinstance(task_data, list):
        for index, task in enumerate(task_data):
            if isinstance(task, dict) and "reward" in task:
                reward_residue.append({"record_index": index, "record_id": task.get("id")})
    else:
        errors.append({"type": "task_data_not_array", "path": str(ROOT / "data" / "tasks" / "maintenance_tasks_seed.json")})

    if reward_residue:
        errors.append({"type": "forbidden_reward_field", "count": len(reward_residue), "records": reward_residue})

    validation_path = ROOT / "reports" / "validation_summary.json"
    validation_passed = False
    if validation_path.exists():
        validation_summary = load_json(validation_path, errors)
        validation_passed = bool(isinstance(validation_summary, dict) and validation_summary.get("schema_validation_passed") is True)
        if not validation_passed:
            errors.append({"type": "phase1_validation_not_passed", "path": str(validation_path)})

    expectations = {
        "species_count_at_least_100": species_count >= 100,
        "equipment_count_at_least_20": equipment_count >= 20,
        "task_count_equals_10": task_count == 10,
        "reward_residue_count_zero": len(reward_residue) == 0,
        "phase1_validation_passed": validation_passed,
    }
    for name, ok in expectations.items():
        if not ok:
            errors.append({"type": "expectation_failed", "expectation": name})

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "files": files,
        "data_files": [str(path) for path in DATA_FILES],
        "counts": {
            "species": species_count,
            "equipment": equipment_count,
            "tasks": task_count,
            "events": event_count,
        },
        "expectations": expectations,
        "reward_residue": reward_residue,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Skeleton check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Skeleton check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
