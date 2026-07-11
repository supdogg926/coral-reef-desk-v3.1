"""
Scan see dream4.5 directory and match to 9 target rescue species.
"""
import os, sys, json, hashlib, csv, glob as globmod
from pathlib import Path
from datetime import datetime, timezone, timedelta

TZ = timezone(timedelta(hours=8))
NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S")

SOURCE_ROOT = Path("C:/Users/admin/Desktop/see dream4.5")
REPO = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
REPORTS = REPO / "reports/m17/t02"
EVIDENCE = REPORTS / "evidence"
EVIDENCE.mkdir(parents=True, exist_ok=True)

IMG_EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp', '.tif', '.tiff'}

# ============================================================
# PART 1: Scan all images
# ============================================================
print("=== SCANNING see dream4.5 ===")
inventory = []
errors = []

for root, dirs, files in os.walk(SOURCE_ROOT):
    for fname in files:
        fpath = Path(root) / fname
        ext = fpath.suffix.lower()
        if ext not in IMG_EXTS:
            continue

        record = {
            "absolute_path": str(fpath),
            "relative_path": str(fpath.relative_to(SOURCE_ROOT)),
            "filename": fname,
            "extension": ext,
            "file_size_bytes": fpath.stat().st_size,
            "modified_time": datetime.fromtimestamp(fpath.stat().st_mtime, tz=TZ).isoformat(),
            "parent_folder": str(fpath.parent.relative_to(SOURCE_ROOT)),
            "width": None,
            "height": None,
            "color_mode": None,
            "has_alpha": None,
            "file_sha256": None,
            "keywords_from_name": [],
            "metadata_available": [],
            "decode_error": None,
        }

        # Compute SHA256
        try:
            with open(fpath, "rb") as f:
                record["file_sha256"] = hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            record["decode_error"] = f"SHA256: {e}"

        # Decode image
        try:
            from PIL import Image
            img = Image.open(fpath)
            record["width"], record["height"] = img.size
            record["color_mode"] = img.mode
            record["has_alpha"] = img.mode in ("RGBA", "LA", "PA") or (img.mode == "P" and img.info.get("transparency") is not None)
            img.verify()
        except Exception as e:
            record["decode_error"] = f"PIL: {e}"
            errors.append({"file": str(fpath), "error": str(e)})

        # Extract keywords from filename
        name_noext = fpath.stem
        # Remove common suffixes
        for suffix in ["01", "02", "03", "_attempt", "_seed", "_v1", "_v2", "_final"]:
            name_noext = name_noext.replace(suffix, " ")
        record["keywords_from_name"] = [w for w in name_noext.replace("_", " ").replace("-", " ").split() if len(w) > 0]

        # Check for metadata files in same directory
        parent = fpath.parent
        for meta_name in ["metadata.json", "prompt.md", "prompt.txt", "suggested_filename.txt",
                          "*.md", "*.json", "*.csv", "*.txt"]:
            if "*" in meta_name:
                for mf in globmod.glob(str(parent / meta_name)):
                    record["metadata_available"].append(str(Path(mf).relative_to(SOURCE_ROOT)))
            else:
                mp = parent / meta_name
                if mp.exists():
                    record["metadata_available"].append(str(mp.relative_to(SOURCE_ROOT)))

        inventory.append(record)

print(f"Scanned {len(inventory)} images, {len(errors)} errors")

# Save inventory CSV
csv_path = REPORTS / "see_dream45_image_inventory.csv"
with open(csv_path, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["relative_path", "filename", "extension", "file_size_bytes", "width", "height",
                     "color_mode", "has_alpha", "file_sha256", "modified_time", "parent_folder",
                     "keywords", "metadata_files", "decode_error"])
    for r in inventory:
        writer.writerow([r["relative_path"], r["filename"], r["extension"], r["file_size_bytes"],
                         r["width"], r["height"], r["color_mode"], r["has_alpha"],
                         r["file_sha256"], r["modified_time"], r["parent_folder"],
                         "|".join(r["keywords_from_name"]), "|".join(r["metadata_available"]),
                         r["decode_error"] or ""])
print(f"Inventory CSV: {csv_path}")

# Save inventory JSON
json_path = REPORTS / "see_dream45_image_inventory.json"
with open(json_path, "w", encoding="utf-8") as f:
    json.dump({"scan_root": str(SOURCE_ROOT), "total_images": len(inventory),
               "errors": errors, "images": inventory}, f, ensure_ascii=False, indent=2)
print(f"Inventory JSON: {json_path}")

# ============================================================
# PART 2: Match to 9 target species
# ============================================================
print("\n=== MATCHING TO 9 TARGET SPECIES ===")

TARGETS = [
    {"order": 1, "species_id": "rescue_clownfish_juvenile", "zh": "迷路小丑鱼",
     "keywords": ["公子小丑", "小丑鱼", "ocellaris", "clownfish", "amphiprion", "nemo", "小丑"],
     "keywords_en": ["clownfish", "ocellaris", "nemo", "amphiprion"],
     "role": "active", "exclude": ["澳洲仙", "黄霞蝶"]},
    {"order": 2, "species_id": "rescue_cleaner_shrimp", "zh": "受困清洁虾",
     "keywords": ["清洁虾", "医生虾", "lysmata", "shrimp", "cleaner", "虾"],
     "keywords_en": ["shrimp", "cleaner", "lysmata", "amboinensis"],
     "role": "active", "exclude": []},
    {"order": 3, "species_id": "rescue_goby", "zh": "虚弱虾虎",
     "keywords": ["虾虎", "goby", "gobies", "watchman", "shrimpgoby", "虾虎鱼"],
     "keywords_en": ["goby", "gobies", "watchman"],
     "role": "active", "exclude": ["八线龙", "黄龙", "隆头", "wrasse"]},
    {"order": 4, "species_id": "rescue_seahorse", "zh": "受困海马",
     "keywords": ["海马", "seahorse", "hippocampus", "海马体"],
     "keywords_en": ["seahorse", "hippocampus"],
     "role": "active", "exclude": ["海龙", "seadragon"]},
    {"order": 5, "species_id": "rescue_hermit_crab", "zh": "寄居蟹",
     "keywords": ["寄居蟹", "hermit", "crab", "paguroidea", "蟹"],
     "keywords_en": ["hermit", "crab", "paguroidea"],
     "role": "active", "exclude": []},
    {"order": 6, "species_id": "rescue_brain_coral_frag", "zh": "脑珊瑚碎片",
     "keywords": ["脑珊瑚", "金菊脑", "brain", "trachyphyllia", "lobophyllia", "favia", "favites"],
     "keywords_en": ["brain", "trachyphyllia", "lobophyllia"],
     "role": "active", "exclude": ["瓦片", "纽扣", "榔头", "火柴", "圣杯", "猪腰", "闪千手", "草皮"]},
    {"order": 7, "species_id": "rescue_mandarin_dragonet", "zh": "花斑连鳍䲗",
     "keywords": ["五彩青蛙", "青蛙", "mandarin", "dragonet", "synchiropus", "连鳍", "麒麟"],
     "keywords_en": ["mandarin", "dragonet", "synchiropus", "splendidus"],
     "role": "reserved", "exclude": ["黄龙", "八线", "wrasse", "隆头"]},
    {"order": 8, "species_id": "rescue_sea_star", "zh": "海星",
     "keywords": ["海星", "starfish", "sea star", "star", "asteroidea", "linckia"],
     "keywords_en": ["starfish", "sea star", "asteroidea", "linckia"],
     "role": "reserved", "exclude": []},
    {"order": 9, "species_id": "rescue_anemone_tube", "zh": "管海葵",
     "keywords": ["海葵", "奶嘴", "anemone", "tube", "bta", "bubble tip", "carpet", "entacmaea", "管海葵"],
     "keywords_en": ["anemone", "tube", "bta", "bubble", "carpet", "entacmaea"],
     "role": "reserved", "exclude": ["珊瑚", "coral", "火柴", "榔头", "纽扣", "草皮", "瓦片", "千手", "闪千手"]},
]

matches = []

for target in TARGETS:
    sid = target["species_id"]
    print(f"\n[{target['order']}/9] {sid} ({target['zh']}) [{target['role']}]")

    candidates = []
    for img in inventory:
        if img["decode_error"]:
            continue

        score = 0
        match_basis = []

        # Method 1: Keyword match in filename
        fname_lower = img["filename"].lower().replace("_", " ").replace("-", " ")
        parent_lower = img["parent_folder"].lower().replace("_", " ").replace("-", " ")

        for kw in target["keywords"]:
            if kw.lower() in fname_lower:
                score += 10
                match_basis.append(f"filename_zh:{kw}")
                break  # count once per keyword category

        for kw in target["keywords_en"]:
            if kw.lower() in fname_lower:
                score += 5
                match_basis.append(f"filename_en:{kw}")
                break

        # Method 2: Keyword match in parent folder
        for kw in target["keywords"]:
            if kw.lower() in parent_lower:
                score += 8
                match_basis.append(f"folder:{kw}")
                break

        # Method 3: Exclude false positives
        excluded = False
        for ex in target["exclude"]:
            if ex.lower() in fname_lower or ex.lower() in parent_lower:
                excluded = True
                match_basis.append(f"EXCLUDED:{ex}")
                break

        if excluded:
            score = 0

        if score > 0:
            candidates.append({**img, "match_score": score, "match_basis": match_basis})

    # Sort by score descending, then by resolution descending
    candidates.sort(key=lambda x: (-x["match_score"], -(x.get("width") or 0) * (x.get("height") or 0)))

    # Keep top 5
    top5 = candidates[:5]

    # Assign ranks
    for i, c in enumerate(top5):
        c["candidate_rank"] = i + 1
        c["selected"] = False
        c["rejection_reason"] = ""
        c["notes"] = ""

    # Auto-select top candidate if match is strong and unambiguous
    if top5 and top5[0]["match_score"] >= 10:
        top5[0]["selected"] = True
        top5[0]["notes"] = "Auto-matched: strong keyword match"
    elif top5:
        for c in top5:
            c["notes"] = "SELECTION_REVIEW_REQUIRED"

    matches.append({
        "species_id": sid,
        "zh_name": target["zh"],
        "role": target["role"],
        "order": target["order"],
        "candidates": top5,
        "total_found": len(top5),
        "best_score": top5[0]["match_score"] if top5 else 0,
    })

    status = "MATCHED" if (top5 and top5[0]["match_score"] >= 10) else ("AMBIGUOUS" if top5 else "NO_MATCH")
    print(f"  Found: {len(top5)} candidates, best score: {top5[0]['match_score'] if top5 else 0}, status: {status}")
    for c in top5[:3]:
        print(f"    [{c['candidate_rank']}] {c['filename']} score={c['match_score']} basis={c['match_basis']} {'SELECTED' if c.get('selected') else ''}")

# Save matching CSV
match_csv_path = REPORTS / "see_dream45_species_matching.csv"
with open(match_csv_path, "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow(["species_id", "zh_name", "role", "candidate_path", "match_basis",
                     "filename_match", "metadata_match", "dimensions", "file_sha256",
                     "candidate_rank", "selected", "rejection_reason", "notes"])
    for m in matches:
        for c in m["candidates"]:
            writer.writerow([
                m["species_id"], m["zh_name"], m["role"],
                c["relative_path"], "|".join(c.get("match_basis", [])),
                c["filename"], "|".join(c.get("metadata_available", [])),
                f"{c.get('width')}x{c.get('height')}", c.get("file_sha256", ""),
                c.get("candidate_rank", ""), c.get("selected", False),
                c.get("rejection_reason", ""), c.get("notes", "")
            ])
print(f"\nMatching CSV: {match_csv_path}")

# Summary
print("\n=== MATCHING SUMMARY ===")
matched_count = sum(1 for m in matches if m["total_found"] > 0 and m["best_score"] >= 10)
ambiguous = [m["species_id"] for m in matches if m["total_found"] > 0 and m["best_score"] < 10]
no_match = [m["species_id"] for m in matches if m["total_found"] == 0]
selected_count = sum(1 for m in matches for c in m["candidates"] if c.get("selected"))

print(f"Total images in see dream4.5: {len(inventory)}")
print(f"Matched species: {matched_count}")
print(f"Ambiguous species: {ambiguous}")
print(f"Unmatched species: {no_match}")
print(f"Auto-selected candidates: {selected_count}")

# Save matching JSON
match_json_path = REPORTS / "see_dream45_species_matching.json"
with open(match_json_path, "w", encoding="utf-8") as f:
    json.dump({
        "scan_root": str(SOURCE_ROOT),
        "total_images": len(inventory),
        "matched_species_count": matched_count,
        "ambiguous_species": ambiguous,
        "unmatched_species": no_match,
        "auto_selected_count": selected_count,
        "species_matches": [{
            "species_id": m["species_id"],
            "zh_name": m["zh_name"],
            "role": m["role"],
            "total_found": m["total_found"],
            "best_score": m["best_score"],
            "candidates": [{k: v for k, v in c.items() if k != "keywords_from_name"}
                          for c in m["candidates"]]
        } for m in matches]
    }, f, ensure_ascii=False, indent=2)
print(f"Matching JSON: {match_json_path}")

# Output summary for next step
print("\n=== SEE_DREAM45_SCAN_COMPLETE ===")
print(f"SEE_DREAM45_TOTAL_IMAGE_COUNT={len(inventory)}")
print(f"SEE_DREAM45_MATCHED_SPECIES_COUNT={matched_count}")
print(f"SEE_DREAM45_SELECTED_ASSET_COUNT={selected_count}")
print(f"SEE_DREAM45_AMBIGUOUS_SPECIES={ambiguous}")
print(f"SEE_DREAM45_UNMATCHED_SPECIES={no_match}")
