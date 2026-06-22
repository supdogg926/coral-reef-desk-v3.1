from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
REPORT_PATH = ROOT / "reports" / "validation_summary.json"


def load_json(path: Path, errors: list[dict[str, Any]]) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except Exception as exc:  # noqa: BLE001 - report validation failures without hiding file path.
        errors.append(
            {
                "path": str(path),
                "type": "json_parse_error",
                "message": str(exc),
            }
        )
        return None


def iter_records(data: Any) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return [item for item in data if isinstance(item, dict)]
    if isinstance(data, dict):
        records: list[dict[str, Any]] = []
        for value in data.values():
            if isinstance(value, list):
                records.extend(item for item in value if isinstance(item, dict))
        return records
    return []


def require_fields(
    path: Path,
    records: list[dict[str, Any]],
    required: list[str],
    errors: list[dict[str, Any]],
) -> None:
    for index, record in enumerate(records):
        missing = [field for field in required if field not in record]
        if missing:
            errors.append(
                {
                    "path": str(path),
                    "type": "missing_required_fields",
                    "record_index": index,
                    "record_id": record.get("id"),
                    "missing": missing,
                }
            )


def validate_tasks(path: Path, records: list[dict[str, Any]], errors: list[dict[str, Any]]) -> list[dict[str, Any]]:
    reward_residue: list[dict[str, Any]] = []
    require_fields(path, records, ["id", "name", "cooldown_hours"], errors)
    for index, record in enumerate(records):
        if "reward" in record:
            residue = {
                "path": str(path),
                "record_index": index,
                "record_id": record.get("id"),
            }
            reward_residue.append(residue)
            errors.append({"type": "forbidden_reward_field", **residue})
    return reward_residue


def main() -> int:
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []
    reward_residue: list[dict[str, Any]] = []
    checked_files: list[str] = []
    category_counts = {
        "species_records": 0,
        "equipment_records": 0,
        "task_records": 0,
    }

    for path in sorted(DATA_DIR.rglob("*.json")):
        checked_files.append(str(path))
        data = load_json(path, errors)
        if data is None:
            continue

        relative_parts = path.relative_to(DATA_DIR).parts
        records = iter_records(data)

        if relative_parts[0] == "species":
            category_counts["species_records"] += len(records)
            require_fields(path, records, ["id", "name"], errors)
        elif relative_parts[0] == "equipment":
            category_counts["equipment_records"] += len(records)
            require_fields(path, records, ["id", "name"], errors)
        elif relative_parts[0] == "tasks":
            category_counts["task_records"] += len(records)
            reward_residue.extend(validate_tasks(path, records, errors))

    schema_files = sorted((DATA_DIR / "schemas").glob("*.json"))
    summary = {
        "root": str(ROOT),
        "data_dir": str(DATA_DIR),
        "checked_files": checked_files,
        "checked_file_count": len(checked_files),
        "schema_files": [str(path) for path in schema_files],
        "schema_file_count": len(schema_files),
        "category_counts": category_counts,
        "reward_field_residue": reward_residue,
        "reward_field_residue_count": len(reward_residue),
        "schema_validation_passed": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
    }

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if errors:
        print(f"Validation failed. Summary: {REPORT_PATH}")
        return 1

    print(f"Validation passed. Summary: {REPORT_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
