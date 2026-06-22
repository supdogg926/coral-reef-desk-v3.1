from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
EQUIPMENT_TIERS_PATH = ROOT / "data" / "equipment" / "equipment_tiers_seed.json"
PLACEMENT_ZONES_PATH = ROOT / "data" / "equipment" / "placement_zones_seed.json"
PLACEMENT_SCHEMA_PATH = ROOT / "data" / "schemas" / "equipment_placement_schema.json"
TASKS_PATH = ROOT / "data" / "tasks" / "maintenance_tasks_seed.json"
REPORT_PATH = ROOT / "reports" / "m4_tier1_equipment_check_summary.json"

TIER1_IDS = {
    "filter_sock",
    "protein_skimmer",
    "refugium",
    "return_pump",
    "live_rock",
    "filter_media",
    "heater",
}

REQUIRED_ZONES = {
    "mechanical_filtration_chamber",
    "skimmer_chamber",
    "refugium_chamber",
    "return_chamber",
    "display_tank",
}

REQUIRED_EQUIPMENT_FIELDS = {
    "storage_state",
    "slot_id",
    "slot_type",
    "footprint_size",
    "legal_zone_ids",
    "installed_effective",
    "pipe_connection_required",
    "implicit_plumbing",
    "installable",
    "removable",
    "sump_template_id",
}

FORBIDDEN_CONCEPTS = [
    "auto main plumbing route",
    "manual side-loop plumbing",
    "free pipe connection",
    "pipe efficiency",
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

    for path in [EQUIPMENT_TIERS_PATH, PLACEMENT_ZONES_PATH, PLACEMENT_SCHEMA_PATH, TASKS_PATH]:
        if not path.exists():
            errors.append({"type": "missing_file", "path": str(path)})

    equipment_data = load_json(EQUIPMENT_TIERS_PATH, errors) if EQUIPMENT_TIERS_PATH.exists() else []
    placement_data = load_json(PLACEMENT_ZONES_PATH, errors) if PLACEMENT_ZONES_PATH.exists() else []
    task_data = load_json(TASKS_PATH, errors) if TASKS_PATH.exists() else []

    equipment = equipment_data if isinstance(equipment_data, list) else []
    zones = placement_data if isinstance(placement_data, list) else []
    tasks = task_data if isinstance(task_data, list) else []

    tier1 = [item for item in equipment if isinstance(item, dict) and item.get("tier") == 1]
    tier2 = [item for item in equipment if isinstance(item, dict) and item.get("tier") == 2]
    tier3 = [item for item in equipment if isinstance(item, dict) and item.get("tier") == 3]

    tier1_ids = {str(item.get("id")) for item in tier1}
    if tier1_ids != TIER1_IDS:
        errors.append(
            {
                "type": "tier1_id_mismatch",
                "expected": sorted(TIER1_IDS),
                "actual": sorted(tier1_ids),
            }
        )

    if len(tier1) != 7:
        errors.append({"type": "tier1_count_mismatch", "expected": 7, "actual": len(tier1)})

    for item in tier1:
        missing_fields = sorted(REQUIRED_EQUIPMENT_FIELDS - set(item.keys()))
        if missing_fields:
            errors.append({"type": "missing_equipment_fields", "id": item.get("id"), "fields": missing_fields})
        if item.get("first_version_enabled") is not True:
            errors.append({"type": "tier1_not_first_version_enabled", "id": item.get("id")})
        for field in ["default_unlocked", "default_owned", "default_enabled"]:
            if item.get(field) is not True:
                errors.append({"type": "tier1_default_state_invalid", "id": item.get("id"), "field": field})
        if item.get("storage_state") != "installed":
            errors.append({"type": "tier1_not_installed", "id": item.get("id"), "storage_state": item.get("storage_state")})
        if item.get("installed_effective") is not True:
            errors.append({"type": "tier1_not_installed_effective", "id": item.get("id")})
        if item.get("pipe_connection_required") is not False:
            errors.append({"type": "pipe_connection_required_not_false", "id": item.get("id")})
        if item.get("implicit_plumbing") is not True:
            errors.append({"type": "implicit_plumbing_not_true", "id": item.get("id")})
        if not item.get("slot_id"):
            errors.append({"type": "tier1_missing_slot_id", "id": item.get("id")})
        if not item.get("footprint_size"):
            errors.append({"type": "tier1_missing_footprint_size", "id": item.get("id")})

    for item in tier2 + tier3:
        missing_fields = sorted(REQUIRED_EQUIPMENT_FIELDS - set(item.keys()))
        if missing_fields:
            errors.append({"type": "missing_equipment_fields", "id": item.get("id"), "fields": missing_fields})
        if item.get("first_version_enabled") is not False:
            errors.append({"type": "reserved_tier_enabled", "id": item.get("id"), "tier": item.get("tier")})
        for field in ["default_unlocked", "default_owned", "default_enabled"]:
            if item.get(field) is not False:
                errors.append({"type": "reserved_tier_default_state_invalid", "id": item.get("id"), "field": field})
        if item.get("storage_state") != "locked":
            errors.append({"type": "reserved_tier_not_locked", "id": item.get("id"), "storage_state": item.get("storage_state")})
        if item.get("installed_effective") is not False:
            errors.append({"type": "reserved_tier_installed_effective", "id": item.get("id")})
        if item.get("pipe_connection_required") is not False:
            errors.append({"type": "reserved_pipe_connection_required_not_false", "id": item.get("id")})
        if item.get("implicit_plumbing") is not True:
            errors.append({"type": "reserved_implicit_plumbing_not_true", "id": item.get("id")})

    zone_ids = {str(item.get("id")) for item in zones if isinstance(item, dict)}
    missing_zones = sorted(REQUIRED_ZONES - zone_ids)
    if missing_zones:
        errors.append({"type": "missing_required_zones", "zones": missing_zones})

    invalid_placements: list[dict[str, Any]] = []
    zone_by_id = {str(item.get("id")): item for item in zones if isinstance(item, dict)}
    for item in tier1:
        equipment_id = str(item.get("id"))
        for zone_id in item.get("legal_zone_ids", []):
            zone = zone_by_id.get(str(zone_id), {})
            allowed = zone.get("allowed_equipment", []) if isinstance(zone, dict) else []
            if equipment_id not in allowed:
                invalid_placements.append({"equipment_id": equipment_id, "zone_id": zone_id})
    if invalid_placements:
        errors.append({"type": "invalid_tier1_placements", "placements": invalid_placements})

    reward_residue = [
        {"record_index": index, "record_id": task.get("id")}
        for index, task in enumerate(tasks)
        if isinstance(task, dict) and "reward" in task
    ]
    if reward_residue:
        errors.append({"type": "forbidden_reward_field", "records": reward_residue})

    zone_schema_errors: list[dict[str, Any]] = []
    for zone in zones:
        if not isinstance(zone, dict):
            continue
        for field in ["sump_template_id", "slot_type", "slot_ids", "implicit_plumbing", "pipe_connection_required"]:
            if field not in zone:
                zone_schema_errors.append({"zone_id": zone.get("id"), "missing_field": field})
        if zone.get("implicit_plumbing") is not True:
            zone_schema_errors.append({"zone_id": zone.get("id"), "field": "implicit_plumbing", "expected": True})
        if zone.get("pipe_connection_required") is not False:
            zone_schema_errors.append({"zone_id": zone.get("id"), "field": "pipe_connection_required", "expected": False})
    if zone_schema_errors:
        errors.append({"type": "zone_schema_errors", "records": zone_schema_errors})

    text_corpus = json.dumps({"equipment": equipment, "zones": zones}, ensure_ascii=False).lower()
    found_forbidden = [concept for concept in FORBIDDEN_CONCEPTS if concept in text_corpus]
    if found_forbidden:
        errors.append({"type": "forbidden_plumbing_gameplay_concepts", "concepts": found_forbidden})

    installed_effective_tier1 = [
        item
        for item in tier1
        if item.get("storage_state") == "installed" and item.get("installed_effective") is True
    ]
    stability_score = 50.0 + sum(float(item.get("effects", {}).get("stability_score", 0)) for item in installed_effective_tier1)
    carrying_capacity_score = 10.0 + sum(float(item.get("effects", {}).get("carrying_capacity_score", 0)) for item in installed_effective_tier1)
    maintenance_load = sum(float(item.get("effects", {}).get("maintenance_load", 0)) for item in installed_effective_tier1)

    summary = {
        "root": str(ROOT),
        "passed": len(errors) == 0,
        "files": {
            "equipment_tiers": str(EQUIPMENT_TIERS_PATH),
            "placement_zones": str(PLACEMENT_ZONES_PATH),
            "equipment_placement_schema": str(PLACEMENT_SCHEMA_PATH),
            "tasks": str(TASKS_PATH),
        },
        "tier1_equipment": sorted(tier1_ids),
        "tier1_count": len(tier1),
        "tier1_first_version_enabled_count": sum(1 for item in tier1 if item.get("first_version_enabled") is True),
        "tier1_installed_effective_count": len(installed_effective_tier1),
        "tier2_reserved_count": len(tier2),
        "tier3_reserved_count": len(tier3),
        "placement_zones": sorted(zone_ids),
        "required_zones": sorted(REQUIRED_ZONES),
        "debug_scores": {
            "stability_score": stability_score,
            "carrying_capacity_score": carrying_capacity_score,
            "maintenance_load": maintenance_load,
        },
        "plumbing_model": {
            "implicit_plumbing": True,
            "pipe_connection_required": False,
            "plumbing_gameplay": False,
        },
        "reward_residue_count": len(reward_residue),
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Tier 1 equipment check failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Tier 1 equipment check passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
