"""
M17-T02-P1 Artifact Generator
Generates: manifest draft, provenance JSON, pixel hash fixture,
asset inventory CSV/MD, contact sheet PNG, contact sheet index MD.
"""
import os, sys, json, hashlib, csv, io
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(".")
NORM_DIR = ROOT / "assets/m17/t02/normalized"
SRC_DIR = ROOT / "assets/m17/t02/source_candidates"
GEN_RECORDS_DIR = ROOT / "reports/m17/t02/generation_records"
REPORTS_DIR = ROOT / "reports/m17"
EVIDENCE_DIR = ROOT / "reports/m17/t02/evidence"
EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
TZ = timezone(timedelta(hours=8))
NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S")
ISO = NOW.isoformat()
BASELINE = "fb8856e8336e5a6109138d609c7793d417a02416"
BRANCH = "prototype/m17-t02-real-assets"
WORKTREE = r"C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M17_T02"

def sha256_file(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def sha256_pixels(path):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    assert w == 256 and h == 256, f"Expected 256x256, got {w}x{h}"
    return hashlib.sha256(img.tobytes("raw", "RGBA")).hexdigest()

# Load pipeline results
with open(NORM_DIR / "pipeline_results.json", encoding="utf-8") as f:
    all_results = json.load(f)

# Load generation records if exists
gen_records = {}
gen_path = GEN_RECORDS_DIR / "generation_records.json"
if gen_path.exists():
    with open(gen_path, encoding="utf-8") as f:
        gen_records_raw = json.load(f)
    for gr in gen_records_raw:
        gen_records[gr["species_id"]] = gr

# Verify all 9 files exist and compute hashes
for r in all_results:
    fp = Path(r["final_path"])
    if not fp.exists():
        print(f"FATAL: Missing {fp}")
        sys.exit(1)
    r["file_sha256"] = sha256_file(fp)
    r["rgba8_pixel_sha256"] = sha256_pixels(fp)
    r["final_file_size_bytes"] = fp.stat().st_size
    print(f"[{r['order']}] {r['species_id']}: FILE={r['file_sha256'][:16]}... PIXEL={r['rgba8_pixel_sha256'][:16]}...")

# ============================================================
# 1. MANIFEST DRAFT (schema v2)
# ============================================================
manifest = {
    "schema_version": 2,
    "max_entries": 9,
    "cards": []
}
for r in all_results:
    sid = r["species_id"]
    manifest["cards"].append({
        "species_id": sid,
        "asset_path": f"res://assets/cards/rescue/{sid}.png",
        "sha256": r["file_sha256"],
        "source": "image2_user_generated",
        "gen_info": {
            "source_tool": r["source_mode"],
            "original_filename": f"{sid}_256.png",
            "original_resolution": "256x256",
            "processed_resolution": "256x256",
            "background_process": "rembg",
            "imported_for": "M17-T02",
            "role": r["role"],
        }
    })

manifest_path = ROOT / "data/card_manifest_m17_t02_draft.json"
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print(f"\nManifest draft: {manifest_path}")

# ============================================================
# 2. PROVENANCE JSON
# ============================================================
provenance = {
    "task_id": "M17-T02",
    "phase": "P1",
    "baseline_commit": BASELINE,
    "branch": BRANCH,
    "worktree": WORKTREE,
    "generator_platform": "火山引擎 ARK",
    "generator_model": "Doubao Seedream 4.5",
    "generator_endpoint": "ep-20260625021114-w7ll4",
    "generated_at": ISO,
    "asset_production_set": 9,
    "active_count": 6,
    "reserved_count": 3,
    "records": []
}

for r in all_results:
    sid = r["species_id"]
    gr = gen_records.get(sid, {})
    attempts_list = gr.get("attempts", [])
    gen_attempt_count = len(attempts_list)

    record = {
        "order": r["order"],
        "species_id": sid,
        "zh_name": r["zh_name"],
        "en_name": r["en_name"],
        "role": r["role"],
        "active_or_reserved": r["role"],
        "source_mode": r["source_mode"],
        "reused_source_path": r.get("source_path") if r["source_mode"] != "seedream_generated" else None,
        "prompt": None,
        "attempt_count": gen_attempt_count,
        "attempts": [],
        "selected_source_path": r["final_path"],
        "selected_source_sha256": r["file_sha256"],
        "final_normalized_path": r["final_path"],
        "final_file_sha256": r["file_sha256"],
        "final_rgba8_pixel_sha256": r["rgba8_pixel_sha256"],
        "final_width": 256,
        "final_height": 256,
        "final_format": "PNG",
        "final_has_alpha": True,
        "final_status": "NORMALIZED",
        "visual_review_status": "REVIEW_PENDING",
    }

    if gen_attempt_count > 0:
        record["prompt"] = gr.get("prompt") or (attempts_list[0].get("prompt") if attempts_list else None)
        for att in attempts_list:
            record["attempts"].append({
                "attempt_number": att["attempt_number"],
                "requested_at": att.get("requested_at"),
                "completed_at": att.get("completed_at"),
                "output_path": att.get("output_path"),
                "output_sha256": att.get("output_sha256"),
                "width": att.get("width"),
                "height": att.get("height"),
                "format": att.get("format"),
                "selected": att.get("status") == "generated",
                "rejection_reason": None if att.get("status") == "generated" else att.get("error", "unknown"),
                "normalization_status": "NORMALIZED" if att.get("status") == "generated" else None,
                "notes": "",
            })
    else:
        record["attempts"] = []

    provenance["records"].append(record)

prov_path = REPORTS_DIR / "m17_t02_asset_provenance.json"
with open(prov_path, "w", encoding="utf-8") as f:
    json.dump(provenance, f, ensure_ascii=False, indent=2)
print(f"Provenance: {prov_path}")

# ============================================================
# 3. PIXEL HASH FIXTURE
# ============================================================
fixture = {
    "schema_version": 2,
    "algorithm": "SHA256",
    "canonical_format": "RGBA8",
    "width": 256,
    "height": 256,
    "row_order": "top_to_bottom",
    "species": []
}
for r in all_results:
    fixture["species"].append({
        "species_id": r["species_id"],
        "role": r["role"],
        "asset_path": r["final_path"],
        "file_sha256": r["file_sha256"],
        "rgba8_pixel_sha256": r["rgba8_pixel_sha256"],
    })

fixture_path = REPORTS_DIR / "t02_asset_pixel_hash_fixture.json"
with open(fixture_path, "w", encoding="utf-8") as f:
    json.dump(fixture, f, ensure_ascii=False, indent=2)
print(f"Pixel hash fixture: {fixture_path}")

# ============================================================
# 4. ASSET INVENTORY CSV + MD
# ============================================================
csv_path = REPORTS_DIR / "t02_p1_asset_inventory.csv"
md_path = REPORTS_DIR / "t02_p1_asset_inventory.md"

with open(csv_path, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["order", "species_id", "zh_name", "en_name", "active_or_reserved",
                     "frozen_runtime_status", "placeholder_path", "expected_final_asset_path",
                     "candidate_source_path", "candidate_source_type", "candidate_width",
                     "candidate_height", "candidate_format", "candidate_has_alpha",
                     "candidate_background", "candidate_sha256", "reuse_or_generate",
                     "generation_attempt_count", "normalization_required", "selected_source",
                     "final_status", "notes"])
    for r in all_results:
        source_path = r.get("source_path", "")
        candidate_sha = ""
        if Path(source_path).exists():
            candidate_sha = sha256_file(source_path)
        writer.writerow([
            r["order"], r["species_id"], r["zh_name"], r["en_name"], r["role"],
            "active" if r["role"] == "active" else "reserved",
            f"assets/cards/placeholder/{r['species_id']}.png",
            r["final_path"], source_path, r["source_mode"],
            "", "", "", "", "", candidate_sha[:16],
            "reuse" if r["source_mode"].startswith("reuse") else "generate",
            len(gen_records.get(r["species_id"], {}).get("attempts", [])),
            "yes" if r["source_mode"] != "reuse_existing" else "no",
            r["final_path"], r["final_status"], ""
        ])

# MD inventory
md_lines = [
    "# M17-T02-P1 Asset Inventory",
    f"Generated: {ISO}",
    "",
    "| # | species_id | 中文名 | Role | Source Mode | Final SHA256 | Pixel SHA256 | Status |",
    "|---|-----------|--------|------|-------------|-------------|-------------|--------|",
]
for r in all_results:
    md_lines.append(f"| {r['order']} | {r['species_id']} | {r['zh_name']} | {r['role']} | {r['source_mode']} | {r['file_sha256'][:16]}... | {r['rgba8_pixel_sha256'][:16]}... | {r['final_status']} |")

md_lines += [
    "",
    f"**Asset Production Set Count**: {len(all_results)}",
    f"**Active Count**: {sum(1 for r in all_results if r['role'] == 'active')}",
    f"**Reserved Count**: {sum(1 for r in all_results if r['role'] == 'reserved')}",
    f"**Normalized Count**: {sum(1 for r in all_results if r['final_status'] == 'NORMALIZED')}",
]
with open(md_path, "w", encoding="utf-8") as f:
    f.write("\n".join(md_lines))
print(f"Inventory CSV: {csv_path}")
print(f"Inventory MD: {md_path}")

# ============================================================
# 5. CONTACT SHEET
# ============================================================
ROWS, COLS = 3, 3
CARD_W, CARD_H = 380, 380
LABEL_H = 90
PAD = 20
FONT_SIZE = 14

sheet_w = COLS * CARD_W + (COLS + 1) * PAD
sheet_h = ROWS * (CARD_H + LABEL_H) + (ROWS + 1) * PAD

sheet = Image.new("RGBA", (sheet_w, sheet_h), (30, 30, 35, 255))
draw = ImageDraw.Draw(sheet)

try:
    font_title = ImageFont.truetype("consola.ttf", FONT_SIZE)
    font_small = ImageFont.truetype("consola.ttf", 10)
except Exception:
    font_title = ImageFont.load_default()
    font_small = ImageFont.load_default()

for i, r in enumerate(all_results):
    row, col = i // COLS, i % COLS
    x = PAD + col * (CARD_W + PAD)
    y = PAD + row * (CARD_H + LABEL_H + PAD)

    # Card area background
    draw.rectangle([x-2, y-2, x+CARD_W+2, y+CARD_H+2], outline=(80, 80, 85, 255), width=1)

    # Place image
    card_img = Image.open(r["final_path"])
    if card_img.size != (CARD_W, CARD_H):
        card_img = card_img.resize((CARD_W, CARD_H))
    # Composite onto checkerboard for transparency visibility
    checker = Image.new("RGBA", (CARD_W, CARD_H), (60, 60, 65, 255))
    # Light checker squares
    for cx in range(0, CARD_W, 16):
        for cy in range(0, CARD_H, 16):
            if (cx // 16 + cy // 16) % 2 == 0:
                for px in range(cx, min(cx+16, CARD_W)):
                    for py in range(cy, min(cy+16, CARD_H)):
                        if px < CARD_W and py < CARD_H:
                            checker.putpixel((px, py), (75, 75, 80, 255))
    checker.paste(card_img, (0, 0), card_img)
    sheet.paste(checker, (x, y))

    # Label area
    label_y = y + CARD_H + 4
    order_text = f"#{r['order']} {r['species_id']}"
    name_text = f"{r['zh_name']} ({r['en_name']})"
    role_text = f"[{r['role'].upper()}] REVIEW_PENDING"
    sha_text = f"SHA:{r['file_sha256'][:12]}"
    file_text = f"{r['species_id']}_256.png"

    draw.text((x, label_y), order_text, fill=(220, 220, 225, 255), font=font_title)
    draw.text((x, label_y + FONT_SIZE + 2), name_text, fill=(180, 180, 185, 255), font=font_small)
    draw.text((x, label_y + FONT_SIZE + 14), role_text, fill=(255, 200, 50, 255), font=font_small)
    draw.text((x, label_y + FONT_SIZE + 26), sha_text, fill=(140, 140, 145, 255), font=font_small)
    draw.text((x, label_y + FONT_SIZE + 38), file_text, fill=(120, 120, 125, 255), font=font_small)

# Title
title = f"M17-T02-P1 Contact Sheet - Asset Production Set (9 species) - {TS}"
draw.text((PAD, sheet_h - PAD - FONT_SIZE), title, fill=(160, 160, 165, 255), font=font_small)

cs_path = EVIDENCE_DIR / f"t02_contact_sheet_{TS}.png"
sheet.save(cs_path, "PNG")
cs_sha = sha256_file(cs_path)
print(f"Contact sheet: {cs_path}")
print(f"  SHA256: {cs_sha}")
print(f"  Size: {sheet_w}x{sheet_h}")

# ============================================================
# 6. CONTACT SHEET INDEX MD
# ============================================================
idx_lines = [
    f"# M17-T02-P1 Contact Sheet Index",
    f"Generated: {ISO}",
    "",
    f"![Contact Sheet]({cs_path.relative_to(ROOT).as_posix()})",
    "",
    f"**Contact Sheet Path**: `{cs_path}`",
    f"**Contact Sheet SHA256**: `{cs_sha}`",
    f"**Contact Sheet Size**: {sheet_w}x{sheet_h}",
    f"**Timestamp**: {TS}",
    "",
    "## Referenced Assets",
    "",
    "| # | Species ID | File SHA256 | Pixel SHA256 |",
    "|---|-----------|-------------|-------------|",
]
for r in all_results:
    idx_lines.append(f"| {r['order']} | {r['species_id']} | `{r['file_sha256'][:16]}...` | `{r['rgba8_pixel_sha256'][:16]}...` |")

idx_path = EVIDENCE_DIR / "t02_contact_sheet_index.md"
with open(idx_path, "w", encoding="utf-8") as f:
    f.write("\n".join(idx_lines))
print(f"Contact sheet index: {idx_path}")

# ============================================================
# Summary
# ============================================================
print(f"\n=== ARTIFACT GENERATION COMPLETE ===")
print(f"Manifest draft: {manifest_path}")
print(f"Provenance: {prov_path}")
print(f"Pixel fixture: {fixture_path}")
print(f"Inventory CSV: {csv_path}")
print(f"Inventory MD: {md_path}")
print(f"Contact sheet: {cs_path}")
print(f"Contact sheet SHA256: {cs_sha}")
print(f"Contact sheet size: {sheet_w}x{sheet_h}")

# Output JSON summary for later use
summary = {
    "manifest_draft_path": str(manifest_path),
    "provenance_path": str(prov_path),
    "pixel_hash_fixture_path": str(fixture_path),
    "inventory_csv_path": str(csv_path),
    "inventory_md_path": str(md_path),
    "contact_sheet_path": str(cs_path),
    "contact_sheet_sha256": cs_sha,
    "contact_sheet_width": sheet_w,
    "contact_sheet_height": sheet_h,
    "contact_sheet_index_path": str(idx_path),
    "contact_sheet_generated_at": ISO,
    "asset_production_set_count": len(all_results),
    "active_count": sum(1 for r in all_results if r["role"] == "active"),
    "reserved_count": sum(1 for r in all_results if r["role"] == "reserved"),
    "normalized_count": sum(1 for r in all_results if r["final_status"] == "NORMALIZED"),
}
summary_path = EVIDENCE_DIR / "t02_artifact_summary.json"
with open(summary_path, "w", encoding="utf-8") as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)
print(f"Artifact summary: {summary_path}")
