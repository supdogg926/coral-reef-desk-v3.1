from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PIPE_PATH = ROOT / "scenes" / "tank" / "PipeNetworkView.gd"
STATUS_PANEL_PATH = ROOT / "scenes" / "ui" / "StatusPanel.gd"
MAIN_SCENE_PATH = ROOT / "scenes" / "main" / "Main.tscn"
REPORT_PATH = ROOT / "reports" / "m6_2_pipe_arrow_deemphasis_check_summary.json"

REQUIRED_PIPE_TEXT = [
    "\u56de\u6c34",
    "\u4e0b\u6c34",
    "\u8865\u6c34",
    "_draw_return_indicator",
    "_draw_drain_indicator",
    "_draw_ato_indicator",
    "z_index = -1",
    "Color(0.26, 0.78, 0.52, 0.25)",
    "Color(0.16, 0.55, 0.78, 0.28)",
    "Color(0.72, 0.78, 0.86, 0.22)",
]

FORBIDDEN_PIPE_TEXT = [
    "595.0",
    "610.0",
    "pipe_efficiency",
    "pipe_connection_gameplay",
    "manual_pipe",
    "auto_route",
    "free_drag",
    "drag_and_drop",
]

REQUIRED_STATUS_TEXT = [
    "\u6570\u636e\u4e0e\u9636\u6bb5",
    "\u6c34\u8d28",
    "\u7cfb\u7edf",
    "\u751f\u7269\u4e0e\u6536\u76ca",
    "\u6536\u76ca",
    "\u6a21\u62df",
]

SCAN_GDSCRIPT = [
    PIPE_PATH,
    STATUS_PANEL_PATH,
    ROOT / "scenes" / "main" / "Main.gd",
    ROOT / "scenes" / "tank" / "DisplayTankView.gd",
    ROOT / "scenes" / "tank" / "SumpView.gd",
    ROOT / "scripts" / "systems" / "GameState.gd",
    ROOT / "scripts" / "systems" / "LivestockSystem.gd",
    ROOT / "scripts" / "systems" / "EconomySystem.gd",
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

    for path in [PIPE_PATH, STATUS_PANEL_PATH, MAIN_SCENE_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    pipe_text = PIPE_PATH.read_text(encoding="utf-8") if PIPE_PATH.exists() else ""
    status_text = STATUS_PANEL_PATH.read_text(encoding="utf-8") if STATUS_PANEL_PATH.exists() else ""
    scene_text = MAIN_SCENE_PATH.read_text(encoding="utf-8") if MAIN_SCENE_PATH.exists() else ""

    missing_pipe_text = [text for text in REQUIRED_PIPE_TEXT if text not in pipe_text]
    if missing_pipe_text:
        errors.append({"type": "missing_pipe_text", "texts": missing_pipe_text})

    forbidden_pipe_hits = [text for text in FORBIDDEN_PIPE_TEXT if text in pipe_text]
    if forbidden_pipe_hits:
        errors.append({"type": "forbidden_pipe_text", "texts": forbidden_pipe_hits})

    missing_status_text = [text for text in REQUIRED_STATUS_TEXT if text not in status_text]
    if missing_status_text:
        errors.append({"type": "missing_status_text", "texts": missing_status_text})

    if scene_text.find("PipeNetworkView") > scene_text.find("StatusPanel"):
        errors.append({"type": "pipe_node_draws_after_status_panel"})

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
        "pipe_view": str(PIPE_PATH),
        "status_panel": str(STATUS_PANEL_PATH),
        "main_scene": str(MAIN_SCENE_PATH),
        "dataregistry_counts": counts,
        "variant_inference_hit_count": len(variant_hits),
        "forbidden_pipe_hits": forbidden_pipe_hits,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"M6.2 pipe arrow deemphasis check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"M6.2 pipe arrow deemphasis check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
