"""
Apply see dream4.5 replacements: copy, re-normalize, regenerate all artifacts.
Non-destructive to source directory.
"""
import os, sys, json, hashlib, shutil, csv, glob as globmod
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image
from rembg import remove

ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
SOURCE_ROOT = Path("C:/Users/admin/Desktop/see dream4.5")
TZ = timezone(timedelta(hours=8))
NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S")
ISO = NOW.isoformat()

SRC_DIR = ROOT / "assets/m17/t02/source_candidates"
NORM_DIR = ROOT / "assets/m17/t02/normalized"
SRC_DIR.mkdir(parents=True, exist_ok=True)
NORM_DIR.mkdir(parents=True, exist_ok=True)

def sha256_file(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def sha256_pixels(path):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    assert w == 256 and h == 256
    return hashlib.sha256(img.tobytes("raw", "RGBA")).hexdigest()

# ============================================================
# REPLACEMENT MAP
# ============================================================
REPLACEMENTS = {
    "rescue_clownfish_juvenile": {
        "source_path": str(SOURCE_ROOT / "普通公子小丑02.png"),
        "replacement_reason": "Producer-reviewed Image2 ocellaris clownfish from see dream4.5; filename confirms 公子小丑 species identity",
    },
    "rescue_mandarin_dragonet": {
        "source_path": str(SOURCE_ROOT / "五彩青蛙01.png"),
        "replacement_reason": "Producer-reviewed Image2 mandarinfish from see dream4.5; 五彩青蛙 is the standard Chinese name for Synchiropus splendidus",
    },
    "rescue_anemone_tube": {
        "source_path": str(SOURCE_ROOT / "红奶嘴01.png"),
        "replacement_reason": "Producer-reviewed Image2 BTA anemone from see dream4.5; 红奶嘴 (Rose BTA) is a valid anemone species for the tube anemone category",
    },
    "rescue_brain_coral_frag": {
        "source_path": str(SOURCE_ROOT / "01_今日待生成/010_sp_0353_fc1598_金菊脑/PNG图像.png"),
        "replacement_reason": "Producer-reviewed Image2 brain coral from see dream4.5; 金菊脑 (Golden Brain Coral, Favia/Favites) is a true brain coral species, organized in numbered species folder with metadata",
    },
}

# ============================================================
# Load current pipeline results
# ============================================================
with open(NORM_DIR / "pipeline_results.json", encoding="utf-8") as f:
    all_results = json.load(f)

# ============================================================
# STEP 1: Copy and replace
# ============================================================
replaced_species = []
retained_species = []
replacement_log = []

for r in all_results:
    sid = r["species_id"]
    if sid in REPLACEMENTS:
        repl = REPLACEMENTS[sid]
        src = Path(repl["source_path"])
        if not src.exists():
            print(f"SKIP {sid}: source not found: {src}")
            retained_species.append(sid)
            replacement_log.append({
                "species_id": sid, "replaced": False, "reason": f"Source not found: {src}",
                "old_source": r.get("source_path", ""), "new_source": "",
                "old_file_sha256": r.get("file_sha256", ""), "new_file_sha256": "",
                "old_pixel_sha256": r.get("rgba8_pixel_sha256", ""), "new_pixel_sha256": "",
            })
            continue

        # Copy candidate to source dir
        dst_name = f"{sid}_see_dream45_source{src.suffix}"
        dst_path = SRC_DIR / dst_name
        shutil.copy2(src, dst_path)
        original_sha = sha256_file(src)

        # Record old values
        old_source = r.get("source_path", "")
        old_sha = r.get("file_sha256", "")
        old_psha = r.get("rgba8_pixel_sha256", "")

        # Update record
        r["source_mode"] = "image2_human_approved_reuse"
        r["source_path"] = str(dst_path)
        r["source_root"] = str(SOURCE_ROOT)
        r["original_source_path"] = str(src)
        r["original_file_sha256"] = original_sha
        r["copied_candidate_path"] = str(dst_path)
        r["replacement_of"] = old_source
        r["replacement_reason"] = repl["replacement_reason"]

        print(f"REPLACED {sid}: {src.name} ({original_sha[:16]}...) -> {dst_name}")
        replaced_species.append(sid)
        replacement_log.append({
            "species_id": sid, "replaced": True,
            "reason": repl["replacement_reason"],
            "old_source": old_source, "new_source": str(dst_path),
            "old_file_sha256": old_sha, "new_file_sha256": "",
            "old_pixel_sha256": old_psha, "new_pixel_sha256": "",
            "original_see_dream45_sha256": original_sha,
        })
    else:
        retained_species.append(sid)
        replacement_log.append({
            "species_id": sid, "replaced": False,
            "reason": "No matching producer-reviewed image found in see dream4.5",
            "old_source": r.get("source_path", ""), "new_source": "",
            "old_file_sha256": r.get("file_sha256", ""), "new_file_sha256": "",
            "old_pixel_sha256": r.get("rgba8_pixel_sha256", ""), "new_pixel_sha256": "",
        })
        print(f"RETAINED {sid}: no see dream4.5 match available")

# ============================================================
# STEP 2: Re-normalize replaced species
# ============================================================
print("\n=== RE-NORMALIZING REPLACED SPECIES ===")

for r in all_results:
    sid = r["species_id"]
    if sid not in REPLACEMENTS:
        continue

    src = Path(r["source_path"])
    dst = NORM_DIR / f"{sid}_256.png"
    print(f"\n[{r['order']}/9] {sid} ({r['zh_name']}) <- see dream4.5")

    try:
        img = Image.open(src).convert("RGB")
        src_w, src_h = img.size
        print(f"  Source: {src_w}x{src_h}")

        # Remove background
        img_rgba = remove(img)

        # Find subject bbox
        alpha = img_rgba.split()[-1]
        bbox = alpha.getbbox()
        if bbox is None:
            print(f"  ERROR: no subject found")
            continue

        bb_l, bb_t, bb_r, bb_b = bbox
        subj_w, subj_h = bb_r - bb_l, bb_b - bb_t
        pad_w, pad_h = int(subj_w * 0.10), int(subj_h * 0.10)
        bb_l = max(0, bb_l - pad_w); bb_t = max(0, bb_t - pad_h)
        bb_r = min(src_w, bb_r + pad_w); bb_b = min(src_h, bb_b + pad_h)

        cropped = img_rgba.crop((bb_l, bb_t, bb_r, bb_b))
        crop_w, crop_h = cropped.size

        max_dim = max(crop_w, crop_h)
        square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
        square.paste(cropped, ((max_dim - crop_w)//2, (max_dim - crop_h)//2))

        ratio = (subj_w * subj_h) / (max_dim * max_dim)
        print(f"  Subject: {subj_w}x{subj_h}, Ratio: {ratio:.1%}")

        if ratio < 0.50:
            print(f"  Adjusting: subject too small, tightening crop")
            l2 = max(0, bb_l + pad_w//2); t2 = max(0, bb_t + pad_h//2)
            r2 = min(src_w, bb_r - pad_w//2); b2 = min(src_h, bb_b - pad_h//2)
            cropped2 = img_rgba.crop((l2, t2, r2, b2))
            crop_w2, crop_h2 = cropped2.size
            max_dim2 = max(crop_w2, crop_h2)
            square = Image.new("RGBA", (max_dim2, max_dim2), (0, 0, 0, 0))
            square.paste(cropped2, ((max_dim2 - crop_w2)//2, (max_dim2 - crop_h2)//2))

        final = square.resize((256, 256), Image.LANCZOS)
        final.save(dst, "PNG")

        # Compute hashes
        file_sha = sha256_file(dst)
        pixel_sha = sha256_pixels(dst)
        fsize = dst.stat().st_size

        r["final_path"] = str(dst)
        r["final_width"] = 256
        r["final_height"] = 256
        r["final_format"] = "PNG"
        r["final_file_size_bytes"] = fsize
        r["final_has_alpha"] = True
        r["file_sha256"] = file_sha
        r["rgba8_pixel_sha256"] = pixel_sha
        r["final_status"] = "NORMALIZED"

        # Update replacement log
        for rl in replacement_log:
            if rl["species_id"] == sid:
                rl["new_file_sha256"] = file_sha
                rl["new_pixel_sha256"] = pixel_sha

        print(f"  Normalized: 256x256, SHA={file_sha[:16]}...")

    except Exception as e:
        print(f"  NORMALIZATION ERROR: {e}")
        r["final_status"] = f"NORMALIZATION_ERROR: {e}"

# ============================================================
# STEP 3: Save updated pipeline results
# ============================================================
with open(NORM_DIR / "pipeline_results.json", "w", encoding="utf-8") as f:
    json.dump(all_results, f, ensure_ascii=False, indent=2)

# Save replacement log
rep_log_path = ROOT / "reports/m17/t02/evidence/see_dream45_replacement_log.json"
with open(rep_log_path, "w", encoding="utf-8") as f:
    json.dump({
        "timestamp": ISO,
        "source_root": str(SOURCE_ROOT),
        "replaced_count": len(replaced_species),
        "retained_count": len(retained_species),
        "replaced": replaced_species,
        "retained": retained_species,
        "log": replacement_log,
    }, f, ensure_ascii=False, indent=2)
print(f"\nReplacement log: {rep_log_path}")

# ============================================================
# STEP 4: Summary
# ============================================================
print(f"\n=== REPLACEMENT SUMMARY ===")
print(f"Replaced: {len(replaced_species)} species: {replaced_species}")
print(f"Retained: {len(retained_species)} species: {retained_species}")
for r in all_results:
    status = "REPLACED" if r["species_id"] in replaced_species else "RETAINED"
    print(f"  [{r['order']}] {r['species_id']} [{r['role']}] {status} | {r['source_mode']} | {r['final_status']} | SHA={r.get('file_sha256', 'N/A')[:16]}...")

print(f"\nSEE_DREAM45_SELECTED_ASSET_COUNT={len(replaced_species)}")
print(f"SEE_DREAM45_RETAINED_OLD_ASSET_COUNT={len(retained_species)}")
print(f"REPLACED_SPECIES={replaced_species}")
print(f"RETAINED_SPECIES={retained_species}")
