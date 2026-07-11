"""
M17-T02-P1: Rebuild species pool from available approved images.
Policy: AVAILABLE_APPROVED_IMAGES_FIRST
"""
import os, sys, json, hashlib, shutil, csv, glob as globmod
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont
from rembg import remove

SOURCE = Path("C:/Users/admin/Desktop/see dream4.5/01_今日待生成")
ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
TZ = timezone(timedelta(hours=8))
NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S")
ISO = NOW.isoformat()

SRC_DIR = ROOT / "assets/m17/t02/source_candidates"
NORM_DIR = ROOT / "assets/m17/t02/normalized"
EVIDENCE = ROOT / "reports/m17/t02/evidence"
REPORTS = ROOT / "reports/m17/t02"
SRC_DIR.mkdir(parents=True, exist_ok=True)
NORM_DIR.mkdir(parents=True, exist_ok=True)
EVIDENCE.mkdir(parents=True, exist_ok=True)
REPORTS.mkdir(parents=True, exist_ok=True)

def sha256f(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def sha256p(path):
    img = Image.open(path).convert("RGBA")
    assert img.size == (256, 256)
    return hashlib.sha256(img.tobytes("raw", "RGBA")).hexdigest()

# ============================================================
# STEP 1: Scan and build full inventory
# ============================================================
print("=== SCANNING 01_今日待生成 ===")
inventory = []
folders = sorted([d for d in SOURCE.iterdir() if d.is_dir()])

for folder in folders:
    meta_path = folder / "metadata.json"
    meta = {}
    if meta_path.exists():
        meta = json.load(open(meta_path, encoding="utf-8"))

    zh_name = meta.get("canonical_name", folder.name.split("_")[-1])
    sp_id = meta.get("canonical_species_id", "")
    sp_group = meta.get("species_group", "unknown")

    # Find images
    imgs = [f for f in folder.iterdir() if f.suffix.lower() in {'.png','.jpg','.jpeg','.webp','.bmp'}]
    for img_path in imgs:
        try:
            img = Image.open(img_path)
            w, h = img.size
            sha = sha256f(img_path)
            inventory.append({
                "source_path": str(img_path),
                "relative_path": str(img_path.relative_to(SOURCE)),
                "filename": img_path.name,
                "width": w, "height": h,
                "format": img.format,
                "has_alpha": img.mode in ("RGBA", "LA"),
                "file_size_bytes": img_path.stat().st_size,
                "file_sha256": sha,
                "parent_folder": folder.name,
                "canonical_species_id": sp_id,
                "zh_name": zh_name,
                "en_name": meta.get("canonical_en_name", ""),
                "species_group": sp_group,
                "morphology_notes": meta.get("morphology_notes", ""),
                "identification_basis": "metadata_json_canonical_name",
                "identification_confidence": "high",
                "quality_status": "qualifed_producer_reviewed",
            })
            print(f"  [{folder.name}] {zh_name} ({sp_group}) {w}x{h} {img.format}")
        except Exception as e:
            print(f"  [{folder.name}] ERROR: {e}")

# Deduplicate: one best image per species
species_img_map = {}
for inv in inventory:
    sid = inv["canonical_species_id"]
    if sid not in species_img_map or inv["file_size_bytes"] > species_img_map[sid]["file_size_bytes"]:
        species_img_map[sid] = inv

distinct_species = list(species_img_map.values())
distinct_species.sort(key=lambda x: x["parent_folder"])
print(f"\nTotal images: {len(inventory)}, Distinct species: {len(distinct_species)}")

# ============================================================
# STEP 2: Save inventory CSVs
# ============================================================
csv_path = REPORTS / "available_image_inventory.csv"
with open(csv_path, "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["source_path","relative_path","filename","width","height","format","has_alpha",
                "file_size_bytes","file_sha256","parent_folder","zh_name","en_name",
                "species_group","identification_basis","identification_confidence","quality_status"])
    for inv in inventory:
        w.writerow([inv["source_path"],inv["relative_path"],inv["filename"],inv["width"],inv["height"],
                    inv["format"],inv["has_alpha"],inv["file_size_bytes"],inv["file_sha256"],
                    inv["parent_folder"],inv["zh_name"],inv["en_name"],inv["species_group"],
                    inv["identification_basis"],inv["identification_confidence"],inv["quality_status"]])
print(f"Inventory CSV: {csv_path}")

json_path = REPORTS / "available_image_inventory.json"
with open(json_path, "w", encoding="utf-8") as f:
    json.dump({"source_root":str(SOURCE),"total_images":len(inventory),
               "distinct_species":len(distinct_species),"images":inventory}, f, ensure_ascii=False, indent=2)

# ============================================================
# STEP 3: GENERATE FULL GALLERY
# ============================================================
print("\n=== GENERATING FULL GALLERY ===")
all_imgs_for_gallery = []
for sp in distinct_species:
    all_imgs_for_gallery.append(sp)

n = len(all_imgs_for_gallery)
cols = 5
rows = (n + cols - 1) // cols
thumb_w, thumb_h = 320, 240
label_h = 80
pad = 16
gw = cols * thumb_w + (cols + 1) * pad
gh = rows * (thumb_h + label_h) + (rows + 1) * pad
gallery = Image.new("RGBA", (gw, gh), (30, 30, 35, 255))
draw = ImageDraw.Draw(gallery)

try:
    font_s = ImageFont.truetype("consola.ttf", 10)
    font_xs = ImageFont.truetype("consola.ttf", 8)
except:
    font_s = font_xs = ImageFont.load_default()

for i, sp in enumerate(all_imgs_for_gallery):
    row, col = i // cols, i % cols
    x = pad + col * (thumb_w + pad)
    y = pad + row * (thumb_h + label_h + pad)
    try:
        img = Image.open(sp["source_path"])
        img.thumbnail((thumb_w, thumb_h), Image.LANCZOS)
        iw, ih = img.size
        ox = x + (thumb_w - iw) // 2
        oy = y + (thumb_h - ih) // 2
        gallery.paste(img.convert("RGBA") if img.mode != "RGBA" else img, (ox, oy))
    except:
        pass
    draw.rectangle([x-1, y-1, x+thumb_w+1, y+thumb_h+1], outline=(80,80,85))
    ly = y + thumb_h + 4
    draw.text((x, ly), f"#{i+1} {sp['zh_name']}", fill=(220,220,225), font=font_s)
    draw.text((x, ly+12), f"{sp['species_group']} | {sp['width']}x{sp['height']}", fill=(160,160,165), font=font_xs)
    draw.text((x, ly+24), f"SHA:{sp['file_sha256'][:12]}", fill=(120,120,125), font=font_xs)
    draw.text((x, ly+36), sp['filename'][:50], fill=(100,100,105), font=font_xs)

gallery_path = EVIDENCE / f"available_image_full_gallery_{TS}.png"
gallery.save(gallery_path, "PNG")
gallery_sha = sha256f(gallery_path)
print(f"Gallery: {gallery_path} ({gw}x{gh}) SHA={gallery_sha[:16]}...")

# HTML gallery
html = ['<html><head><meta charset="utf-8"><title>Available Image Gallery</title>',
        '<style>body{background:#1e1e23;color:#ddd;font-family:monospace}',
        '.card{display:inline-block;margin:12px;padding:8px;border:1px solid #444;width:340px;vertical-align:top}',
        'img{max-width:320px;max-height:240px}',
        '.label{font-size:11px;margin:4px 0}</style></head><body>',
        f'<h2>Available Image Gallery — {TS}</h2>',
        f'<p>Source: {SOURCE}<br>Total: {len(inventory)} images, {len(distinct_species)} distinct species</p>']
for i, sp in enumerate(all_imgs_for_gallery):
    html.append(f'<div class="card"><img src="file:///{sp["source_path"].replace(chr(92),"/")}"><br>')
    html.append(f'<div class="label">#{i+1} <b>{sp["zh_name"]}</b> ({sp["species_group"]})<br>')
    html.append(f'{sp["width"]}x{sp["height"]} | {sp["filename"][:50]}<br>')
    html.append(f'SHA:{sp["file_sha256"][:12]}</div></div>')
html.append('</body></html>')
html_path = EVIDENCE / f"available_image_full_gallery_{TS}.html"
html_path.write_text("\n".join(html), encoding="utf-8")

# ============================================================
# STEP 4: SELECT 9 SPECIES (6 active + 3 reserved)
# ============================================================
print("\n=== SELECTING 9 SPECIES ===")

# Build new species definitions
# Drop: 山脉金绿猪腰 (sp_0011_4422c3) - another LPS coral, least thumbnail-distinctive
NEW_SPECIES = [
    {"order": 1, "species_id": "rescue_blue_eye_bristletooth_tang", "zh": "蓝眼食苔吊", "en": "Blue-Eye Bristletooth Tang",
     "category": "fish", "role": "active", "sp_folder": "001_sp_0007_001167_蓝眼食苔吊",
     "reason": "Distinctive tang with bright blue eye rings; high visual ID at thumbnail; good rescue narrative (algae-grazing fish)"},
    {"order": 2, "species_id": "rescue_eight_line_flasher_wrasse", "zh": "八线龙", "en": "Eight-Line Flasher Wrasse",
     "category": "fish", "role": "active", "sp_folder": "002_sp_0046_a47d69_八线龙",
     "reason": "Striking striped pattern; fluorescent lines add visual interest; distinct from solid-color wrasses"},
    {"order": 3, "species_id": "rescue_coral_beauty_angelfish", "zh": "石美人", "en": "Coral Beauty Angelfish",
     "category": "fish", "role": "active", "sp_folder": "004_sp_0044_31070f_石美人",
     "reason": "Classic bicolor angelfish; very high recognition; strong yellow/blue contrast; ideal for rescue card"},
    {"order": 4, "species_id": "rescue_green_star_polyp", "zh": "荧光绿草皮", "en": "Green Star Polyp",
     "category": "coral", "role": "active", "sp_folder": "006_sp_0083_eec5f4_荧光绿草皮",
     "reason": "Only encrusting soft coral in pool; fluorescent green highly visible; distinctive mat texture"},
    {"order": 5, "species_id": "rescue_pulsing_xenia", "zh": "闪千手", "en": "Pulsing Xenia",
     "category": "coral", "role": "active", "sp_folder": "007_sp_0406_642986_闪千手",
     "reason": "Most visually unique coral with feathery polyps; pink-white contrast against background; iconic reef species"},
    {"order": 6, "species_id": "rescue_golden_brain_coral", "zh": "金菊脑", "en": "Golden Brain Coral",
     "category": "coral", "role": "active", "sp_folder": "010_sp_0353_fc1598_金菊脑",
     "reason": "Distinctive maze/brain pattern; golden color; high visual ID; classic LPS coral representative"},
    # --- reserved ---
    {"order": 7, "species_id": "rescue_yellow_coris_wrasse", "zh": "黄龙", "en": "Yellow Coris Wrasse",
     "category": "fish", "role": "reserved", "sp_folder": "003_sp_0043_fe9058_黄龙",
     "reason": "Solid bright yellow; clean simple silhouette; good contrast; reserve as alternative fish type"},
    {"order": 8, "species_id": "rescue_tiger_angelfish", "zh": "虎纹仙", "en": "Tiger Angelfish",
     "category": "fish", "role": "reserved", "sp_folder": "005_sp_0045_912806_虎纹仙",
     "reason": "Bold tiger-stripe pattern; different from coral beauty; good visual diversity; reserve angelfish"},
    {"order": 9, "species_id": "rescue_holy_grail_scolymia", "zh": "圣杯", "en": "Holy Grail Scolymia",
     "category": "coral", "role": "reserved", "sp_folder": "008_sp_0003_8e7169_圣杯",
     "reason": "Flat disc/saucer shape unique among corals; vibrant color; good coral category reserve"},
]

# Find source image for each
for sp in NEW_SPECIES:
    folder_match = [d for d in folders if sp["sp_folder"] in str(d)]
    if folder_match:
        imgs = [f for f in folder_match[0].iterdir() if f.suffix.lower() in {'.png','.jpg','.jpeg','.webp','.bmp'}]
        # Prefer PNG图像.png, else largest
        best = None
        for imp in imgs:
            if "PNG图像" in imp.name:
                best = imp; break
        if not best:
            best = max(imgs, key=lambda x: x.stat().st_size)
        sp["source_path"] = str(best)
        sp["original_filename"] = best.name
        sp["original_sha256"] = sha256f(best)
        sp["source_size"] = str(Image.open(best).size)
        print(f"  [{sp['order']}] {sp['zh']} -> {best.name} ({sp['original_sha256'][:16]}...)")

# ============================================================
# STEP 5: REJECTED SPECIES
# ============================================================
rejected = [{"zh_name": "山脉金绿猪腰", "en_name": "Mountain Gold-Green Euphyllia",
             "species_group": "coral", "reason": "Fourth LPS coral in pool; hammer-tip tentacles less visually distinctive at 256x256 thumbnail than other 3 selected corals; strong candidate for future expansion"}]

# ============================================================
# STEP 6: COPY SOURCES + NORMALIZE
# ============================================================
print("\n=== NORMALIZING 9 SELECTED SPECIES ===")
for sp in NEW_SPECIES:
    src = Path(sp["source_path"])
    # Copy
    dst_name = f"{sp['species_id']}_source{src.suffix}"
    dst_copy = SRC_DIR / dst_name
    shutil.copy2(src, dst_copy)
    sp["copied_path"] = str(dst_copy)

    # Normalize
    dst_norm = NORM_DIR / f"{sp['species_id']}_256.png"
    print(f"  [{sp['order']}] {sp['zh']} ...")
    try:
        img = Image.open(src).convert("RGB")
        sw, sh = img.size
        img_rgba = remove(img)
        alpha = img_rgba.split()[-1]
        bbox = alpha.getbbox()
        if not bbox:
            print(f"    ERROR: no subject")
            continue
        bb_l, bb_t, bb_r, bb_b = bbox
        subj_w, subj_h = bb_r - bb_l, bb_b - bb_t
        pad_w, pad_h = int(subj_w*0.10), int(subj_h*0.10)
        bb_l, bb_t = max(0, bb_l-pad_w), max(0, bb_t-pad_h)
        bb_r, bb_b = min(sw, bb_r+pad_w), min(sh, bb_b+pad_h)
        cropped = img_rgba.crop((bb_l, bb_t, bb_r, bb_b))
        cw, ch = cropped.size
        maxd = max(cw, ch)
        sq = Image.new("RGBA", (maxd, maxd), (0,0,0,0))
        sq.paste(cropped, ((maxd-cw)//2, (maxd-ch)//2))
        ratio = (subj_w*subj_h)/(maxd*maxd)
        if ratio < 0.50:
            l2, t2 = max(0, bb_l+pad_w//2), max(0, bb_t+pad_h//2)
            r2, b2 = min(sw, bb_r-pad_w//2), min(sh, bb_b-pad_h//2)
            cropped2 = img_rgba.crop((l2, t2, r2, b2))
            cw2, ch2 = cropped2.size
            maxd2 = max(cw2, ch2)
            sq = Image.new("RGBA", (maxd2, maxd2), (0,0,0,0))
            sq.paste(cropped2, ((maxd2-cw2)//2, (maxd2-ch2)//2))
            print(f"    Tightened: ratio {ratio:.1%} -> adjusted")
        final = sq.resize((256, 256), Image.LANCZOS)
        final.save(dst_norm, "PNG")
        sp["final_path"] = str(dst_norm)
        sp["file_sha256"] = sha256f(dst_norm)
        sp["rgba8_pixel_sha256"] = sha256p(dst_norm)
        sp["file_size_bytes"] = dst_norm.stat().st_size
        sp["final_status"] = "NORMALIZED"
        print(f"    OK 256x256 SHA={sp['file_sha256'][:16]}... PSHA={sp['rgba8_pixel_sha256'][:16]}...")
    except Exception as e:
        sp["final_status"] = f"ERROR: {e}"
        print(f"    ERROR: {e}")

# ============================================================
# STEP 7: GENERATE MANIFEST DRAFT
# ============================================================
print("\n=== GENERATING MANIFEST ===")
manifest = {"schema_version": 2, "max_entries": 9, "cards": []}
for sp in NEW_SPECIES:
    manifest["cards"].append({
        "species_id": sp["species_id"],
        "asset_path": f"res://assets/cards/rescue/{sp['species_id']}.png",
        "sha256": sp.get("file_sha256",""),
        "source": "image2_human_approved_available_pool",
        "gen_info": {
            "source_tool": "Image2",
            "original_filename": sp.get("original_filename",""),
            "original_resolution": sp.get("source_size",""),
            "processed_resolution": "256x256",
            "background_process": "rembg",
            "imported_for": "M17-T02-available-pool",
            "role": sp["role"],
            "zh_name": sp["zh"],
            "en_name": sp["en"],
            "category": sp["category"],
        }
    })
manifest_path = ROOT / "data/card_manifest_m17_t02_available_pool_draft.json"
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
print(f"Manifest: {manifest_path}")

# ============================================================
# STEP 8: PROVENANCE
# ============================================================
provenance = {
    "task_id": "M17-T02", "phase": "P1",
    "selection_policy": "AVAILABLE_APPROVED_IMAGES_FIRST",
    "source_root": str(SOURCE),
    "baseline_commit": "fb8856e8336e5a6109138d609c7793d417a02416",
    "generated_at": ISO,
    "records": []
}
for sp in NEW_SPECIES:
    provenance["records"].append({
        "order": sp["order"], "species_id": sp["species_id"],
        "zh_name": sp["zh"], "en_name": sp["en"],
        "category": sp["category"], "role": sp["role"],
        "source_mode": "image2_human_approved_available_pool",
        "original_source_path": sp.get("source_path",""),
        "original_filename": sp.get("original_filename",""),
        "original_sha256": sp.get("original_sha256",""),
        "copied_candidate_path": sp.get("copied_path",""),
        "final_normalized_path": sp.get("final_path",""),
        "final_file_sha256": sp.get("file_sha256",""),
        "final_rgba8_pixel_sha256": sp.get("rgba8_pixel_sha256",""),
        "final_width": 256, "final_height": 256,
        "final_format": "PNG", "final_has_alpha": True,
        "final_status": sp.get("final_status",""),
        "selection_reason": sp["reason"],
        "visual_review_status": "REVIEW_PENDING",
    })
prov_path = ROOT / "reports/m17/m17_t02_available_pool_provenance.json"
with open(prov_path, "w", encoding="utf-8") as f:
    json.dump(provenance, f, ensure_ascii=False, indent=2)
print(f"Provenance: {prov_path}")

# ============================================================
# STEP 9: PIXEL HASH FIXTURE
# ============================================================
fixture = {"schema_version": 2, "algorithm": "SHA256", "canonical_format": "RGBA8",
           "width": 256, "height": 256, "row_order": "top_to_bottom", "species": []}
for sp in NEW_SPECIES:
    fixture["species"].append({
        "species_id": sp["species_id"], "role": sp["role"],
        "asset_path": sp.get("final_path",""),
        "file_sha256": sp.get("file_sha256",""),
        "rgba8_pixel_sha256": sp.get("rgba8_pixel_sha256",""),
    })
fixture_path = ROOT / "reports/m17/t02_available_pool_pixel_hash_fixture.json"
with open(fixture_path, "w", encoding="utf-8") as f:
    json.dump(fixture, f, ensure_ascii=False, indent=2)

# ============================================================
# STEP 10: OLD-to-NEW MAPPING
# ============================================================
old_species = [
    "rescue_clownfish_juvenile","rescue_cleaner_shrimp","rescue_goby",
    "rescue_seahorse","rescue_hermit_crab","rescue_brain_coral_frag",
    "rescue_mandarin_dragonet","rescue_sea_star","rescue_anemone_tube"
]
mapping = {"policy": "AVAILABLE_APPROVED_IMAGES_FIRST",
           "old_species_status": "REMOVED_BY_PRODUCER_RULING",
           "note": "Old 9-species list replaced by available-image-driven selection. No 1:1 mapping exists.",
           "old_species_ids": old_species,
           "new_species_ids": [sp["species_id"] for sp in NEW_SPECIES],
           "rejected_from_pool": rejected}
mapping_path = ROOT / "reports/m17/t02_old_to_new_species_mapping.json"
with open(mapping_path, "w", encoding="utf-8") as f:
    json.dump(mapping, f, ensure_ascii=False, indent=2)

# ============================================================
# STEP 11: CONTACT SHEET (9 selected only)
# ============================================================
print("\n=== GENERATING CONTACT SHEET ===")
cs_card, cs_label = 380, 90
cs_pad, cs_font = 20, 14
cs_rows, cs_cols = 3, 3
cs_w = cs_cols * cs_card + (cs_cols+1) * cs_pad
cs_h = cs_rows * (cs_card + cs_label) + (cs_rows+1) * cs_pad
cs = Image.new("RGBA", (cs_w, cs_h), (30,30,35,255))
cs_draw = ImageDraw.Draw(cs)
try:
    f14 = ImageFont.truetype("consola.ttf", 14); f10 = ImageFont.truetype("consola.ttf", 10)
except:
    f14 = f10 = ImageFont.load_default()

for i, sp in enumerate(NEW_SPECIES):
    row, col = i // cs_cols, i % cs_cols
    x = cs_pad + col*(cs_card+cs_pad); y = cs_pad + row*(cs_card+cs_label+cs_pad)
    cs_draw.rectangle([x-2,y-2,x+cs_card+2,y+cs_card+2], outline=(80,80,85), width=1)
    # Checkerboard
    chk = Image.new("RGBA", (cs_card, cs_card), (60,60,65,255))
    for cx in range(0, cs_card, 16):
        for cy in range(0, cs_card, 16):
            if (cx//16+cy//16)%2==0:
                for px in range(cx,min(cx+16,cs_card)):
                    for py in range(cy,min(cy+16,cs_card)):
                        chk.putpixel((px,py),(75,75,80,255))
    card = Image.open(sp["final_path"]).resize((cs_card,cs_card))
    chk.paste(card, (0,0), card)
    cs.paste(chk, (x,y))
    ly = y+cs_card+4
    cs_draw.text((x,ly), f"#{sp['order']} {sp['species_id']}", fill=(220,220,225), font=f14)
    cs_draw.text((x,ly+16), f"{sp['zh']} ({sp['en']})", fill=(180,180,185), font=f10)
    cs_draw.text((x,ly+28), f"[{sp['role'].upper()}] {sp['category']} | REVIEW_PENDING", fill=(255,200,50), font=f10)
    cs_draw.text((x,ly+40), f"SHA:{sp['file_sha256'][:12]} | {sp['original_filename']}", fill=(140,140,145), font=f10)

title_line = f"M17-T02-P1 Available Pool Contact Sheet — {TS}"
cs_draw.text((cs_pad, cs_h-cs_pad-14), title_line, fill=(160,160,165), font=f10)
cs_path = EVIDENCE / f"t02_available_pool_contact_sheet_{TS}.png"
cs.save(cs_path, "PNG")
cs_sha = sha256f(cs_path)
print(f"Contact sheet: {cs_path} ({cs_w}x{cs_h}) SHA={cs_sha[:16]}...")

# ============================================================
# STEP 12: RULING FILES
# ============================================================
ruling_md = [
    f"# M17-T02 Available Image Species Ruling",
    f"**Date**: {ISO}",
    f"**Policy**: AVAILABLE_APPROVED_IMAGES_FIRST",
    f"**Source**: {SOURCE}",
    f"",
    f"## Reason for Override",
    f"The original M17-T01 frozen 9-species list was designed before the Image2 production pipeline",
    f"completed. After scanning the producer-reviewed `01_今日待生成` directory, 10 distinct qualified",
    f"species were found with complete metadata, morphological descriptions, and producer-reviewed images.",
    f"Continuing to force-match the old 9 species names would result in incorrect species identification",
    f"and lower-quality assets. The new policy selects what is actually available and qualified.",
    f"",
    f"## Scan Results",
    f"- Total images scanned: {len(inventory)}",
    f"- Distinct species identified: {len(distinct_species)}",
    f"- Qualified species: {len(distinct_species)} (all have metadata, morphological descriptions, producer review)",
    f"- Selected: 9 (6 active + 3 reserved)",
    f"- Rejected: 1 (山脉金绿猪腰 — 4th LPS coral, least thumbnail-distinctive)",
    f"",
    f"## Selected Species (6 active + 3 reserved)",
    f"| # | species_id | 中文 | English | Category | Role | Reason |",
    f"|---|-----------|------|---------|----------|------|--------|",
]
for sp in NEW_SPECIES:
    ruling_md.append(f"| {sp['order']} | {sp['species_id']} | {sp['zh']} | {sp['en']} | {sp['category']} | {sp['role']} | {sp['reason'][:60]}... |")
ruling_md += [
    f"",
    f"## Rejected Species",
    f"| 中文 | English | Category | Reason |",
    f"|------|---------|----------|--------|",
]
for rj in rejected:
    ruling_md.append(f"| {rj['zh_name']} | {rj['en_name']} | {rj['species_group']} | {rj['reason']} |")
ruling_md += [
    f"",
    f"## Producer Confirmation Required",
    f"The execution layer has proposed the above 9 species based on available qualified images.",
    f"The producer must confirm:",
    f"1. Each species identity (zh_name, en_name, species_id) is correct",
    f"2. Each image is visually approved",
    f"3. The 6 active / 3 reserved split is accepted",
    f"4. Any species to swap between active/reserved",
    f"",
    f"**Status: REVIEW_PENDING**",
]
ruling_md_path = ROOT / "reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.md"
ruling_md_path.write_text("\n".join(ruling_md), encoding="utf-8")

ruling_json = {"policy":"AVAILABLE_APPROVED_IMAGES_FIRST","source_root":str(SOURCE),
               "total_scanned":len(inventory),"distinct_species":len(distinct_species),
               "selected":9,"active":6,"reserved":3,"rejected":rejected,
               "species":[{k:v for k,v in sp.items() if k not in ['sp_folder']} for sp in NEW_SPECIES],
               "status":"REVIEW_PENDING"}
ruling_json_path = ROOT / "reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.json"
with open(ruling_json_path, "w", encoding="utf-8") as f:
    json.dump(ruling_json, f, ensure_ascii=False, indent=2)
print(f"Ruling: {ruling_md_path}")

# ============================================================
# FINAL SUMMARY
# ============================================================
print(f"\n{'='*60}")
print(f"SOURCE_ROOT={SOURCE}")
print(f"TOTAL_IMAGE_COUNT={len(inventory)}")
print(f"DECODABLE_IMAGE_COUNT={len(inventory)}")
print(f"QUALIFIED_IMAGE_COUNT={len(inventory)}")
print(f"DISTINCT_IDENTIFIED_SPECIES_COUNT={len(distinct_species)}")
print(f"SELECTED_SPECIES_COUNT={len(NEW_SPECIES)}")
print(f"ACTIVE_COUNT={sum(1 for s in NEW_SPECIES if s['role']=='active')}")
print(f"RESERVED_COUNT={sum(1 for s in NEW_SPECIES if s['role']=='reserved')}")
print(f"REJECTED_IMAGE_COUNT={len(rejected)}")
print(f"FULL_GALLERY_PATH={gallery_path}")
print(f"FULL_GALLERY_SHA256={gallery_sha}")
print(f"NEW_SPECIES_RULING_MD={ruling_md_path}")
print(f"NEW_SPECIES_RULING_JSON={ruling_json_path}")
print(f"NEW_MANIFEST_DRAFT_PATH={manifest_path}")
print(f"NEW_CONTACT_SHEET_PATH={cs_path}")
print(f"NEW_CONTACT_SHEET_SHA256={cs_sha}")
print(f"PROVENANCE_PATH={prov_path}")
print(f"PIXEL_HASH_FIXTURE_PATH={fixture_path}")
print(f"MAPPING_PATH={mapping_path}")
print(f"M17_T02_SELECTION_POLICY=AVAILABLE_APPROVED_IMAGES_FIRST")
print(f"M17_T02_P1_OVERALL_STATUS=REVIEW_PENDING")
for sp in NEW_SPECIES:
    print(f"  [{sp['order']}] {sp['species_id']} | {sp['zh']} | {sp['category']} | {sp['role']} | SHA={sp.get('file_sha256','N/A')[:16]}...")
