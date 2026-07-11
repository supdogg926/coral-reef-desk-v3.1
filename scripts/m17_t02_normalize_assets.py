"""
M17-T02-P1 Asset Normalization Pipeline
Non-destructive: original sources preserved.
Outputs: 256x256 RGBA PNG + SHA256 records.
"""
import os, sys, json, hashlib, shutil
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image
from rembg import remove

ROOT = Path("assets/m17/t02")
SOURCE_DIR = ROOT / "source_candidates"
NORMALIZED_DIR = ROOT / "normalized"
NORMALIZED_DIR.mkdir(parents=True, exist_ok=True)
TZ = timezone(timedelta(hours=8))

# Existing M16 assets (already 256x256, reuse as-is)
EXISTING_RESCUE_DIR = Path("assets/cards/rescue")

SPECIES = [
    # --- 3 M16 existing (reuse) ---
    {
        "order": 1,
        "species_id": "rescue_clownfish_juvenile",
        "zh_name": "迷路小丑鱼",
        "en_name": "Lost Clownfish Juvenile",
        "role": "active",
        "source_mode": "reuse_existing",
        "source_path": str(EXISTING_RESCUE_DIR / "rescue_clownfish_juvenile.png"),
        "bg_type": "transparent",
    },
    {
        "order": 2,
        "species_id": "rescue_cleaner_shrimp",
        "zh_name": "受困清洁虾",
        "en_name": "Trapped Cleaner Shrimp",
        "role": "active",
        "source_mode": "reuse_existing",
        "source_path": str(EXISTING_RESCUE_DIR / "rescue_cleaner_shrimp.png"),
        "bg_type": "transparent",
    },
    {
        "order": 3,
        "species_id": "rescue_goby",
        "zh_name": "虚弱虾虎",
        "en_name": "Weak Goby",
        "role": "active",
        "source_mode": "reuse_existing",
        "source_path": str(EXISTING_RESCUE_DIR / "rescue_goby.png"),
        "bg_type": "transparent",
    },
    # --- 3 M17-T01 active (generate/reuse) ---
    {
        "order": 4,
        "species_id": "rescue_seahorse",
        "zh_name": "受困海马",
        "en_name": "Trapped Seahorse",
        "role": "active",
        "source_mode": "seedream_generated",
        "source_path": str(SOURCE_DIR / "rescue_seahorse_attempt01.png"),
        "bg_type": "white",
    },
    {
        "order": 5,
        "species_id": "rescue_hermit_crab",
        "zh_name": "寄居蟹",
        "en_name": "Hermit Crab",
        "role": "active",
        "source_mode": "seedream_generated",
        "source_path": str(SOURCE_DIR / "rescue_hermit_crab_attempt01.png"),
        "bg_type": "white",
    },
    {
        "order": 6,
        "species_id": "rescue_brain_coral_frag",
        "zh_name": "脑珊瑚碎片",
        "en_name": "Brain Coral Fragment",
        "role": "active",
        "source_mode": "reuse_ai_render",
        "source_path": str(SOURCE_DIR / "rescue_brain_coral_frag_reuse_source.png"),
        "bg_type": "black",
    },
    # --- 3 reserved (generate/reuse) ---
    {
        "order": 7,
        "species_id": "rescue_mandarin_dragonet",
        "zh_name": "花斑连鳍䲗",
        "en_name": "Mandarin Dragonet",
        "role": "reserved",
        "source_mode": "reuse_ai_render",
        "source_path": str(SOURCE_DIR / "rescue_mandarin_dragonet_reuse_source.png"),
        "bg_type": "white",
    },
    {
        "order": 8,
        "species_id": "rescue_sea_star",
        "zh_name": "海星",
        "en_name": "Sea Star",
        "role": "reserved",
        "source_mode": "seedream_generated",
        "source_path": str(SOURCE_DIR / "rescue_sea_star_attempt01.png"),
        "bg_type": "black",
    },
    {
        "order": 9,
        "species_id": "rescue_anemone_tube",
        "zh_name": "管海葵",
        "en_name": "Tube Anemone",
        "role": "reserved",
        "source_mode": "reuse_ai_render",
        "source_path": str(SOURCE_DIR / "rescue_anemone_tube_reuse_source.png"),
        "bg_type": "black",
    },
]

def compute_file_sha256(path):
    """Compute SHA256 of raw file bytes."""
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def compute_rgba8_pixel_sha256(path):
    """Compute canonical RGBA8 pixel SHA256.
    Image must be 256x256. Decodes to RGBA, flatten row-order bytes, hash.
    """
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    if w != 256 or h != 256:
        raise ValueError(f"Expected 256x256, got {w}x{h}")
    pixels = img.tobytes("raw", "RGBA")
    return hashlib.sha256(pixels).hexdigest()

def process_species(sp):
    """Process one species from source to final 256x256 RGBA PNG."""
    sid = sp["species_id"]
    src = Path(sp["source_path"])
    dst = NORMALIZED_DIR / f"{sid}_256.png"

    if not src.exists():
        return {"error": f"source not found: {src}"}

    if sp["source_mode"] == "reuse_existing":
        # Already 256x256 RGBA - verify and copy
        img = Image.open(src)
        if img.size == (256, 256):
            shutil.copy2(src, dst)
            return {"status": "reused_as_is"}
        else:
            # Unexpected size, process normally
            pass

    # Load source
    img = Image.open(src).convert("RGB")
    src_w, src_h = img.size
    print(f"  Source: {src_w}x{src_h}")

    # Remove background with rembg
    print(f"  Removing background...")
    img_rgba = remove(img)

    # Find subject bounding box from alpha channel
    alpha = img_rgba.split()[-1]
    bbox = alpha.getbbox()
    if bbox is None:
        return {"error": "no subject found (empty alpha)"}

    # Crop to subject with 10% padding
    l, t, r, b = bbox
    subj_w = r - l
    subj_h = b - t
    pad_w = int(subj_w * 0.10)
    pad_h = int(subj_h * 0.10)
    l = max(0, l - pad_w)
    t = max(0, t - pad_h)
    r = min(src_w, r + pad_w)
    b = min(src_h, b + pad_h)

    # Crop to subject
    cropped = img_rgba.crop((l, t, r, b))
    crop_w, crop_h = cropped.size
    print(f"  Subject: {subj_w}x{subj_h}, Crop: {crop_w}x{crop_h}")

    # Make square by padding the shorter dimension
    max_dim = max(crop_w, crop_h)
    square = Image.new("RGBA", (max_dim, max_dim), (0, 0, 0, 0))
    offset_x = (max_dim - crop_w) // 2
    offset_y = (max_dim - crop_h) // 2
    square.paste(cropped, (offset_x, offset_y))

    # Check subject-to-frame ratio (target 60-75%)
    subject_area = subj_w * subj_h
    frame_area = max_dim * max_dim
    ratio = subject_area / frame_area
    print(f"  Subject ratio: {ratio:.1%}")

    # Adjust if subject is too small (<50%) or too large (>85%)
    if ratio < 0.50:
        # Subject too small - crop tighter then re-pad
        # Re-crop with less padding
        l2 = max(0, l + pad_w // 2)
        t2 = max(0, t + pad_h // 2)
        r2 = min(src_w, r - pad_w // 2)
        b2 = min(src_h, b - pad_h // 2)
        cropped = img_rgba.crop((l2, t2, r2, b2))
        crop_w2, crop_h2 = cropped.size
        max_dim2 = max(crop_w2, crop_h2)
        square = Image.new("RGBA", (max_dim2, max_dim2), (0, 0, 0, 0))
        square.paste(cropped, ((max_dim2 - crop_w2) // 2, (max_dim2 - crop_h2) // 2))
    elif ratio > 0.85:
        # Subject too large - add more padding
        extra = int(max_dim * 0.15)
        new_dim = max_dim + extra
        new_square = Image.new("RGBA", (new_dim, new_dim), (0, 0, 0, 0))
        new_square.paste(square, ((new_dim - max_dim) // 2, (new_dim - max_dim) // 2))
        square = new_square

    # Resize to 256x256 with high-quality Lanczos
    final = square.resize((256, 256), Image.LANCZOS)

    # Save
    final.save(dst, "PNG")
    print(f"  Saved: {dst}")

    return {"status": "normalized"}

# Process all species
results = []
for sp in SPECIES:
    sid = sp["species_id"]
    print(f"\n[{sp['order']}/9] {sid} ({sp['zh_name']}) [{sp['role']}]")
    try:
        proc_result = process_species(sp)
    except Exception as e:
        proc_result = {"error": str(e)}
        print(f"  ERROR: {e}")

    dst = NORMALIZED_DIR / f"{sid}_256.png"
    file_sha = None
    pixel_sha = None
    width = height = fmt = fsize = has_alpha = None
    final_status = "ERROR"

    if dst.exists():
        try:
            img = Image.open(dst)
            width, height = img.size
            fmt = img.format
            fsize = dst.stat().st_size
            has_alpha = img.mode == "RGBA"
            file_sha = compute_file_sha256(dst)
            pixel_sha = compute_rgba8_pixel_sha256(dst)
            if width == 256 and height == 256:
                final_status = "NORMALIZED"
            else:
                final_status = f"SIZE_MISMATCH_{width}x{height}"
            print(f"  Final: {width}x{height} {fmt} {fsize}B SHA256={file_sha[:16]}...")
            print(f"  RGBA8_Pixel_SHA256={pixel_sha[:16]}...")
        except Exception as e:
            final_status = f"VALIDATION_ERROR: {e}"
            print(f"  VALIDATION ERROR: {e}")
    else:
        print(f"  MISSING OUTPUT")

    results.append({
        **sp,
        "final_path": str(dst),
        "final_width": width,
        "final_height": height,
        "final_format": fmt,
        "final_file_size_bytes": fsize,
        "final_has_alpha": has_alpha,
        "file_sha256": file_sha,
        "rgba8_pixel_sha256": pixel_sha,
        "final_status": final_status,
        "processing_result": proc_result,
    })

# Save pipeline results
pipeline_path = ROOT / "normalized" / "pipeline_results.json"
pipeline_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"\nPipeline results saved to {pipeline_path}")

# Summary
for r in results:
    print(f"  [{r['order']}] {r['species_id']}: {r['final_status']} | {r['role']} | {r['source_mode']}")

ok = sum(1 for r in results if r['final_status'] == 'NORMALIZED')
print(f"\nNormalized: {ok}/{len(results)}")
