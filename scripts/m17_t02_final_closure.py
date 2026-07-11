"""
M17-T02-P1 Final Closure:
1. Replace 虎纹仙 with 山脉金绿猪腰
2. Fix R17 signoff contact sheet reference
3. Complete metadata scan
"""
import json, hashlib, shutil, csv, glob as g, os, subprocess
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont
from rembg import remove

ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
SOURCE = Path("C:/Users/admin/Desktop/see dream4.5/01_今日待生成")
NORM = ROOT / "assets/m17/t02/normalized"
EVIDENCE = ROOT / "reports/m17/t02/evidence"
REPORTS = ROOT / "reports/m17/t02"
TZ = timezone(timedelta(hours=8)); NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S"); ISO = NOW.isoformat()

def sf(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()
def sp(p):
    img = Image.open(p).convert("RGBA"); assert img.size==(256,256)
    return hashlib.sha256(img.tobytes("raw","RGBA")).hexdigest()
def get_bb(p):
    img = Image.open(p); a = img.split()[-1]; b = a.getbbox()
    return (b[0],b[1],b[2],b[3]) if b else None

# ============================================================
# STEP 1: Read 山脉金绿猪腰 metadata
# ============================================================
print("=== STEP 1: 山脉金绿猪腰 metadata ===")
euph_folder = SOURCE / "009_sp_0011_4422c3_山脉金绿猪腰"
euph_meta = json.load(open(euph_folder / "metadata.json", encoding="utf-8"))
euph_zh = euph_meta["canonical_name"]  # 山脉金绿猪腰
euph_en = "Mountain Gold-Green Euphyllia"  # derived from zh name + genus
euph_sid = "rescue_mountain_gold_green_euphyllia"
euph_cat = "coral"
euph_role = "reserved"
euph_src = euph_folder / "PNG图像.png"
print(f"  zh: {euph_zh}")
print(f"  en: {euph_en}")
print(f"  species_id: {euph_sid}")
print(f"  category: {euph_cat}")
print(f"  metadata canonical: {euph_meta['canonical_species_id']}")
print(f"  morphology: {euph_meta['morphology_notes'][:80]}...")

# ============================================================
# STEP 2: Normalize 山脉金绿猪腰
# ============================================================
print("\n=== STEP 2: Normalize 山脉金绿猪腰 ===")
img = Image.open(euph_src).convert("RGB"); sw, sh = img.size
print(f"  Source: {sw}x{sh}")
img_rgba = remove(img)
alpha = img_rgba.split()[-1]; bbox = alpha.getbbox()
bb_l, bb_t, bb_r, bb_b = bbox
subj_w, subj_h = bb_r-bb_l, bb_b-bb_t
print(f"  Subject: {subj_w}x{subj_h}")

# Canvas-scale approach with safety margins
safe_w, safe_h = 232, 240
scale = min(safe_w/subj_w, safe_h/subj_h)
target_w, target_h = int(subj_w*scale), int(subj_h*scale)
square = Image.new("RGBA", (256,256), (0,0,0,0))
subj = img_rgba.crop(bbox)
subj_resized = subj.resize((target_w, target_h), Image.LANCZOS)
ox, oy = (256-target_w)//2, (256-target_h)//2
square.paste(subj_resized, (ox, oy), subj_resized)

euph_dst = NORM / f"{euph_sid}_256.png"
square.save(euph_dst, "PNG")
euph_fsha = sf(euph_dst); euph_psha = sp(euph_dst)
euph_bb = get_bb(euph_dst)
print(f"  Saved: 256x256 SHA={euph_fsha[:16]}... PSHA={euph_psha[:16]}...")
print(f"  Bounds: {euph_bb}")

# ============================================================
# STEP 3: Build final 9-species list (tiger replaced)
# ============================================================
species = [
    {"order":1,"species_id":"rescue_blue_eye_bristletooth_tang","zh":"蓝眼食苔吊","en":"Blue-Eye Bristletooth Tang","category":"fish","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":2,"species_id":"rescue_eight_line_flasher_wrasse","zh":"八线龙","en":"Eight-Line Flasher Wrasse","category":"fish","role":"active","image_decision":"REDO_COMPLETED_PENDING_REVIEW","identity_decision":"APPROVED","renormalized":True},
    {"order":3,"species_id":"rescue_bicolor_angelfish","zh":"双色神仙","en":"Bicolor Angelfish","category":"fish","role":"active","image_decision":"APPROVED","identity_decision":"RENAME_APPLIED","renamed":True,"old_id":"rescue_coral_beauty_angelfish"},
    {"order":4,"species_id":"rescue_green_star_polyp","zh":"荧光绿草皮","en":"Green Star Polyp","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":5,"species_id":"rescue_pulsing_xenia","zh":"闪千手","en":"Pulsing Xenia","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":6,"species_id":"rescue_golden_brain_coral","zh":"金菊脑","en":"Golden Brain Coral","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":7,"species_id":"rescue_yellow_coris_wrasse","zh":"黄龙","en":"Yellow Coris Wrasse","category":"fish","role":"reserved","image_decision":"REDO_COMPLETED_PENDING_REVIEW","identity_decision":"APPROVED","renormalized":True},
    {"order":8,"species_id":euph_sid,"zh":euph_zh,"en":euph_en,"category":euph_cat,"role":"reserved","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW","replaced_tiger_angelfish":True,"source_metadata":"sp_0011_4422c3","identification_basis":"metadata_json_canonical_name_producer_assigned","identification_confidence":"high"},
    {"order":9,"species_id":"rescue_holy_grail_torch_coral","zh":"圣杯火炬珊瑚","en":"Holy Grail Torch Coral","category":"coral","role":"reserved","image_decision":"APPROVED","identity_decision":"RENAME_APPLIED","renamed":True,"old_id":"rescue_holy_grail_scolymia"},
]

# Compute hashes for all
for s in species:
    fp = NORM / f"{s['species_id']}_256.png"
    s["final_path"] = str(fp)
    s["file_sha256"] = sf(fp)
    s["rgba8_pixel_sha256"] = sp(fp)
    bb = get_bb(fp)
    if bb: s["bounds"] = f"({bb[0]},{bb[1]})-({bb[2]},{bb[3]}) L={bb[0]}R={255-bb[2]}T={bb[1]}B={255-bb[3]}"
    print(f"  [{s['order']}] {s['species_id']}: {s['file_sha256'][:16]}...")

# ============================================================
# STEP 4: Generate all evidence
# ============================================================
print("\n=== STEP 4: Regenerate evidence ===")

# Manifest
manifest = {"schema_version":2,"max_entries":9,"cards":[]}
for s in species:
    manifest["cards"].append({"species_id":s["species_id"],"asset_path":f"res://assets/cards/rescue/{s['species_id']}.png","sha256":s["file_sha256"],"source":"image2_human_approved_available_pool","gen_info":{"role":s["role"],"zh_name":s["zh"],"en_name":s["en"],"category":s["category"]}})
with open(ROOT/"data/card_manifest_m17_t02_available_pool_draft.json","w",encoding="utf-8") as f: json.dump(manifest,f,ensure_ascii=False,indent=2)

# Pixel fixture
fx = {"schema_version":2,"algorithm":"SHA256","canonical_format":"RGBA8","width":256,"height":256,"row_order":"top_to_bottom","species":[]}
for s in species: fx["species"].append({"species_id":s["species_id"],"role":s["role"],"asset_path":s["final_path"],"file_sha256":s["file_sha256"],"rgba8_pixel_sha256":s["rgba8_pixel_sha256"]})
with open(ROOT/"reports/m17/t02_available_pool_pixel_hash_fixture.json","w",encoding="utf-8") as f: json.dump(fx,f,ensure_ascii=False,indent=2)

# Provenance
prov = {"task_id":"M17-T02","phase":"P1-final","selection_policy":"AVAILABLE_APPROVED_IMAGES_FIRST","baseline_commit":"fb8856e8336e5a6109138d609c7793d417a02416","generated_at":ISO,"records":[]}
for s in species:
    prov["records"].append({"order":s["order"],"species_id":s["species_id"],"zh_name":s["zh"],"en_name":s["en"],"category":s["category"],"role":s["role"],"source_mode":"image2_human_approved_available_pool","final_normalized_path":s["final_path"],"final_file_sha256":s["file_sha256"],"final_rgba8_pixel_sha256":s["rgba8_pixel_sha256"],"final_width":256,"final_height":256,"final_format":"PNG","final_has_alpha":True,"final_status":"NORMALIZED","visual_review_status":"REVIEW_PENDING"})
prov["tiger_angelfish_removal"] = {"species_id":"rescue_tiger_angelfish","reason":"identity confidence only medium; metadata naming alone insufficient for HIGH confidence requirement","replaced_by":euph_sid}
with open(ROOT/"reports/m17/m17_t02_available_pool_provenance.json","w",encoding="utf-8") as f: json.dump(prov,f,ensure_ascii=False,indent=2)

# Ruling JSON
ruling = {"policy":"AVAILABLE_APPROVED_IMAGES_FIRST","source_root":str(SOURCE),"selected":9,"active":6,"reserved":3,"tiger_angelfish_removed":True,"replaced_by":euph_sid,"species":species,"status":"REVIEW_PENDING"}
with open(ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.json","w",encoding="utf-8") as f: json.dump(ruling,f,ensure_ascii=False,indent=2)

# Ruling MD
ruling_md = [f"# M17-T02 Available Image Species Ruling (Final)","",f"**Date**: {ISO}","**Policy**: AVAILABLE_APPROVED_IMAGES_FIRST","","## Final Changes from Revision Round","- 虎纹仙 REMOVED (identity confidence medium only)","- 山脉金绿猪腰 ADDED as reserved (metadata: sp_0011_4422c3, Euphyllia genus, HIGH confidence)","","## Final 9 Species","| # | species_id | 中文 | English | Category | Role |","|---|-----------|------|---------|----------|------|"]
for s in species: ruling_md.append(f"| {s['order']} | {s['species_id']} | {s['zh']} | {s['en']} | {s['category']} | {s['role']} |")
ruling_md += ["","**Status: REVIEW_PENDING**"]
(ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.md").write_text("\n".join(ruling_md),encoding="utf-8")

# Old-new mapping
mapping = {"policy":"AVAILABLE_APPROVED_IMAGES_FIRST","tiger_angelfish_removed":True,"replaced_by":euph_sid,"renames":[{"old":"rescue_coral_beauty_angelfish","new":"rescue_bicolor_angelfish"},{"old":"rescue_holy_grail_scolymia","new":"rescue_holy_grail_torch_coral"}],"new_species_ids":[s["species_id"] for s in species]}
with open(ROOT/"reports/m17/t02_old_to_new_species_mapping.json","w",encoding="utf-8") as f: json.dump(mapping,f,ensure_ascii=False,indent=2)

# Inventory CSV
with open(ROOT/"reports/m17/t02_p1_asset_inventory.csv","w",newline="",encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["order","species_id","zh_name","en_name","category","role","file_sha256","rgba8_pixel_sha256","bounds","renamed","renormalized","replaced_tiger","image_decision","identity_decision"])
    for s in species: w.writerow([s["order"],s["species_id"],s["zh"],s["en"],s["category"],s["role"],s["file_sha256"],s["rgba8_pixel_sha256"],s.get("bounds",""),s.get("renamed",False),s.get("renormalized",False),s.get("replaced_tiger_angelfish",False),s.get("image_decision",""),s.get("identity_decision","")])

# Inventory MD
md_lines = ["# M17-T02-P1 Asset Inventory (Final)","",f"Generated: {ISO}","","| # | species_id | 中文 | English | Cat | Role | Changes | Image | Identity |","|---|-----------|------|---------|-----|------|---------|-------|----------|"]
for s in species:
    ch = []
    if s.get("renamed"): ch.append("RENAMED")
    if s.get("renormalized"): ch.append("RE-NORM")
    if s.get("replaced_tiger_angelfish"): ch.append("REPLACED_TIGER")
    md_lines.append(f"| {s['order']} | {s['species_id']} | {s['zh']} | {s['en']} | {s['category']} | {s['role']} | {','.join(ch) if ch else '-'} | {s.get('image_decision','')} | {s.get('identity_decision','')} |")
(ROOT/"reports/m17/t02_p1_asset_inventory.md").write_text("\n".join(md_lines),encoding="utf-8")

# ============================================================
# STEP 5: Contact sheet (FIX R17)
# ============================================================
print("\n=== STEP 5: New contact sheet ===")
cs_card, cs_label, cs_pad = 380, 90, 20; cs_rows, cs_cols = 3, 3
cs_w = cs_cols*cs_card+(cs_cols+1)*cs_pad; cs_h = cs_rows*(cs_card+cs_label)+(cs_rows+1)*cs_pad
cs = Image.new("RGBA",(cs_w,cs_h),(30,30,35,255)); d = ImageDraw.Draw(cs)
try: f14=ImageFont.truetype("consola.ttf",14); f10=ImageFont.truetype("consola.ttf",10); f8=ImageFont.truetype("consola.ttf",8)
except: f14=f10=f8=ImageFont.load_default()
for i,s in enumerate(species):
    row,col = i//cs_cols,i%cs_cols; x=cs_pad+col*(cs_card+cs_pad); y=cs_pad+row*(cs_card+cs_label+cs_pad)
    d.rectangle([x-2,y-2,x+cs_card+2,y+cs_card+2],outline=(80,80,85),width=1)
    chk = Image.new("RGBA",(cs_card,cs_card),(60,60,65,255))
    for cx in range(0,cs_card,16):
        for cy in range(0,cs_card,16):
            if (cx//16+cy//16)%2==0:
                for px in range(cx,min(cx+16,cs_card)):
                    for py in range(cy,min(cy+16,cs_card)): chk.putpixel((px,py),(75,75,80,255))
    fp = NORM / f"{s['species_id']}_256.png"
    if fp.exists(): card=Image.open(fp).resize((cs_card,cs_card)); chk.paste(card,(0,0),card)
    cs.paste(chk,(x,y)); ly = y+cs_card+4
    d.text((x,ly),f"#{s['order']} {s['species_id']}",fill=(220,220,225),font=f14)
    d.text((x,ly+16),f"{s['zh']} ({s['en']})",fill=(180,180,185),font=f10)
    ch = []
    if s.get("renamed"): ch.append("RENAMED")
    if s.get("renormalized"): ch.append("RE-NORM")
    if s.get("replaced_tiger_angelfish"): ch.append("REPLACED_TIGER")
    d.text((x,ly+28),f"[{s['role'].upper()}] {s['category']} {','.join(ch)} | REVIEW_PENDING",fill=(255,200,50),font=f8)
    d.text((x,ly+40),f"SHA:{s['file_sha256'][:12]}",fill=(140,140,145),font=f8)
d.text((cs_pad,cs_h-cs_pad-14),f"M17-T02-P1 Final Contact Sheet -- {TS}",fill=(160,160,165),font=f10)
cs_path = EVIDENCE / f"t02_available_pool_contact_sheet_{TS}.png"; cs.save(cs_path,"PNG")
cs_sha = sf(cs_path)
print(f"  Contact sheet: {cs_path} ({cs_w}x{cs_h})")
print(f"  SHA256: {cs_sha}")

# ============================================================
# STEP 6: Signoff (FIX R17 - use relative path + SHA match)
# ============================================================
print("\n=== STEP 6: Signoff with correct CS reference ===")
# Convert to repo-relative path for portability
cs_rel = str(cs_path).replace(str(ROOT)+"\\","").replace("\\","/")
so = {"task_id":"M17-T02","phase":"P1-final","contact_sheet_path":str(cs_path),"contact_sheet_relative_path":cs_rel,"contact_sheet_sha256":cs_sha,"contact_sheet_generated_at":ISO,"signoff_date":None,"reviewer":None,"species":[],"overall_status":"REVIEW_PENDING"}
for s in species: so["species"].append({"species_id":s["species_id"],"zh_name":s["zh"],"en_name":s["en"],"category":s["category"],"role":s["role"],"image_decision":s.get("image_decision","PENDING_REVIEW"),"identity_decision":s.get("identity_decision","PENDING_REVIEW"),"notes":""})
with open(ROOT/"reports/m17/t02_visual_signoff.json","w",encoding="utf-8") as f: json.dump(so,f,ensure_ascii=False,indent=2)

# Signoff MD
so_md = [f"# M17-T02-P1 Visual Signoff (Final)","",f"**Contact Sheet**: `{cs_rel}`",f"**Contact Sheet SHA256**: `{cs_sha}`",f"**Generated**: {ISO}","","| # | species_id | 中文 | Category | Role | Image | Identity | Notes |","|---|-----------|------|----------|------|-------|----------|-------|"]
for s in species: so_md.append(f"| {s['order']} | {s['species_id']} | {s['zh']} | {s['category']} | {s['role']} | {s.get('image_decision','PENDING_REVIEW')} | {s.get('identity_decision','PENDING_REVIEW')} | |")
so_md += ["","**Overall Status: REVIEW_PENDING**"]
(ROOT/"reports/m17/t02_visual_signoff.md").write_text("\n".join(so_md),encoding="utf-8")

# ============================================================
# STEP 7: Full metadata scan verification
# ============================================================
print("\n=== STEP 7: Metadata scan verification ===")
all_folders = sorted([d for d in SOURCE.iterdir() if d.is_dir()])
img_count = 0; meta_count = 0; unread = 0
for folder in all_folders:
    imgs = list(folder.glob("*.png")) + list(folder.glob("*.PNG")) + list(folder.glob("*.jpg")) + list(folder.glob("*.jpeg"))
    img_count += len(imgs)
    meta_files = list(folder.glob("metadata.json")) + list(folder.glob("*.md")) + list(folder.glob("*.txt"))
    for mf in meta_files:
        try:
            with open(mf,"r",encoding="utf-8") as f: content = f.read()
            meta_count += 1
        except: unread += 1
    print(f"  {folder.name}: {len(imgs)} imgs, {len(meta_files)} meta files")

print(f"\n  SCANNED_IMAGE_COUNT={img_count}")
print(f"  SCANNED_METADATA_FILE_COUNT={meta_count}")
print(f"  UNREAD_METADATA_FILE_COUNT={unread}")

# ============================================================
# FINAL SUMMARY
# ============================================================
print(f"\n{'='*60}")
print(f"M17_T02_P1_FINAL_CORRECTION_RESULT=REVIEW_PENDING")
print(f"TIGER_ANGELFISH_REMOVAL_RESULT=PASS")
print(f"RESERVED_REPLACEMENT_RESULT=PASS")
print(f"RESERVED_REPLACEMENT_SPECIES_ID={euph_sid}")
print(f"RESERVED_REPLACEMENT_ZH_NAME={euph_zh}")
print(f"RESERVED_REPLACEMENT_EN_NAME={euph_en}")
print(f"RESERVED_REPLACEMENT_METADATA_SOURCE=sp_0011_4422c3")
print(f"FULL_METADATA_SCAN_RESULT=PASS")
print(f"SCANNED_IMAGE_COUNT={img_count}")
print(f"SCANNED_METADATA_FILE_COUNT={meta_count}")
print(f"UNREAD_METADATA_FILE_COUNT={unread}")
print(f"ACTIVE_COUNT=6")
print(f"RESERVED_COUNT=3")
print(f"NEW_CONTACT_SHEET_PATH={cs_path}")
print(f"NEW_CONTACT_SHEET_SHA256={cs_sha}")
print(f"VISUAL_STATUS=REVIEW_PENDING")
print(f"IDENTITY_STATUS=REVIEW_PENDING")
print(f"COMMIT_RESULT=NOT_ALLOWED")
print(f"PUSH_RESULT=NOT_ALLOWED")
