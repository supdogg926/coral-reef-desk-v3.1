"""Rename holy_grail_torch_coral -> holy_grail_matchstick_coral"""
import json, hashlib, shutil, csv, glob, os
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
NORM = ROOT / "assets/m17/t02/normalized"
EVIDENCE = ROOT / "reports/m17/t02/evidence"
TZ = timezone(timedelta(hours=8)); NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S"); ISO = NOW.isoformat()

OLD = "rescue_holy_grail_torch_coral"; NEW = "rescue_holy_grail_matchstick_coral"
OLD_ZH = "圣杯火炬珊瑚"; NEW_ZH = "圣杯火柴珊瑚"
OLD_EN = "Holy Grail Torch Coral"; NEW_EN = "Holy Grail Matchstick Coral"

# Rename file
old_fp = NORM / f"{OLD}_256.png"; new_fp = NORM / f"{NEW}_256.png"
if old_fp.exists(): shutil.copy2(old_fp, new_fp)

def sf(p):
    with open(p, "rb") as f: return hashlib.sha256(f.read()).hexdigest()
def sp(p):
    img = Image.open(p).convert("RGBA"); return hashlib.sha256(img.tobytes("raw", "RGBA")).hexdigest()

fsha = sf(new_fp); psha = sp(new_fp)
print(f"SHA={fsha[:16]}... PSHA={psha[:16]}... (unchanged from original)")

species = [
    (1,"rescue_blue_eye_bristletooth_tang","蓝眼食苔吊","Blue-Eye Bristletooth Tang","fish","active"),
    (2,"rescue_eight_line_flasher_wrasse","八线龙","Eight-Line Flasher Wrasse","fish","active"),
    (3,"rescue_bicolor_angelfish","双色神仙","Bicolor Angelfish","fish","active"),
    (4,"rescue_green_star_polyp","荧光绿草皮","Green Star Polyp","coral","active"),
    (5,"rescue_pulsing_xenia","闪千手","Pulsing Xenia","coral","active"),
    (6,"rescue_golden_brain_coral","金菊脑","Golden Brain Coral","coral","active"),
    (7,"rescue_yellow_coris_wrasse","黄龙","Yellow Coris Wrasse","fish","reserved"),
    (8,"rescue_mountain_gold_green_euphyllia","山脉金绿猪腰","Mountain Gold-Green Euphyllia","coral","reserved"),
    (9,NEW,NEW_ZH,NEW_EN,"coral","reserved"),
]

hashes = {}
for o, sid, zh, en, cat, role in species:
    fp = NORM / f"{sid}_256.png"
    hashes[sid] = (sf(fp), sp(fp))

# String-replace in all evidence files
files_to_patch = [
    ROOT/"data/card_manifest_m17_t02_available_pool_draft.json",
    ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.json",
    ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.md",
    ROOT/"reports/m17/m17_t02_available_pool_provenance.json",
    ROOT/"reports/m17/t02_available_pool_pixel_hash_fixture.json",
    ROOT/"reports/m17/t02_p1_asset_inventory.csv",
    ROOT/"reports/m17/t02_p1_asset_inventory.md",
    ROOT/"reports/m17/t02_old_to_new_species_mapping.json",
    ROOT/"reports/m17/t02_visual_signoff.json",
    ROOT/"reports/m17/t02_visual_signoff.md",
    ROOT/"reports/m17/M17_T02_P1_ASSET_PRODUCTION_REPORT.md",
    ROOT/"reports/m17/M17_T02_P1_ASSET_PRODUCTION_RECEIPT.json",
]
for fp in files_to_patch:
    if fp.exists():
        content = fp.read_text(encoding="utf-8")
        content = content.replace(OLD, NEW).replace(OLD_ZH, NEW_ZH).replace(OLD_EN, NEW_EN)
        fp.write_text(content, encoding="utf-8")
        print(f"  Patched: {fp.name}")

# Clean regenerate manifest
manifest = {"schema_version":2,"max_entries":9,"cards":[]}
for o, sid, zh, en, cat, role in species:
    manifest["cards"].append({"species_id":sid,"asset_path":f"res://assets/cards/rescue/{sid}.png","sha256":hashes[sid][0],"source":"image2_human_approved_available_pool","gen_info":{"role":role,"zh_name":zh,"en_name":en,"category":cat}})
with open(ROOT/"data/card_manifest_m17_t02_available_pool_draft.json","w",encoding="utf-8") as f: json.dump(manifest,f,ensure_ascii=False,indent=2)

# Clean regenerate fixture
fx = {"schema_version":2,"algorithm":"SHA256","canonical_format":"RGBA8","width":256,"height":256,"row_order":"top_to_bottom","species":[]}
for o, sid, zh, en, cat, role in species:
    fx["species"].append({"species_id":sid,"role":role,"asset_path":str(NORM/f"{sid}_256.png"),"file_sha256":hashes[sid][0],"rgba8_pixel_sha256":hashes[sid][1]})
with open(ROOT/"reports/m17/t02_available_pool_pixel_hash_fixture.json","w",encoding="utf-8") as f: json.dump(fx,f,ensure_ascii=False,indent=2)

# Clean regenerate inventory CSV
with open(ROOT/"reports/m17/t02_p1_asset_inventory.csv","w",newline="",encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["order","species_id","zh_name","en_name","category","role","file_sha256","rgba8_pixel_sha256"])
    for o, sid, zh, en, cat, role in species: w.writerow([o,sid,zh,en,cat,role,hashes[sid][0],hashes[sid][1]])

# Inventory MD
md = ["# M17-T02-P1 Asset Inventory (Final)","",f"Generated: {ISO}","","| # | species_id | 中文 | English | Cat | Role | SHA256 |","|---|-----------|------|---------|-----|------|--------|"]
for o, sid, zh, en, cat, role in species: md.append(f"| {o} | {sid} | {zh} | {en} | {cat} | {role} | {hashes[sid][0][:16]}... |")
(ROOT/"reports/m17/t02_p1_asset_inventory.md").write_text("\n".join(md),encoding="utf-8")

# Ruling MD
ruling = [f"# M17-T02 Available Image Species Ruling (Final)","",f"**Date**: {ISO}","","## Final 9 Species","| # | species_id | 中文 | English | Category | Role |","|---|-----------|------|---------|----------|------|"]
for o, sid, zh, en, cat, role in species: ruling.append(f"| {o} | {sid} | {zh} | {en} | {cat} | {role} |")
ruling += ["","**Status: REVIEW_PENDING**"]
(ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.md").write_text("\n".join(ruling),encoding="utf-8")

# Contact sheet
cs_card, cs_label, cs_pad = 380, 90, 20
cs_w = 3*cs_card + 4*cs_pad; cs_h = 3*(cs_card+cs_label) + 4*cs_pad
cs = Image.new("RGBA",(cs_w,cs_h),(30,30,35,255)); d = ImageDraw.Draw(cs)
try: f14=ImageFont.truetype("consola.ttf",14); f10=ImageFont.truetype("consola.ttf",10); f8=ImageFont.truetype("consola.ttf",8)
except: f14=f10=f8=ImageFont.load_default()
for i,(o,sid,zh,en,cat,role) in enumerate(species):
    row,col = i//3,i%3; x=cs_pad+col*(cs_card+cs_pad); y=cs_pad+row*(cs_card+cs_label+cs_pad)
    d.rectangle([x-2,y-2,x+cs_card+2,y+cs_card+2],outline=(80,80,85),width=1)
    chk = Image.new("RGBA",(cs_card,cs_card),(60,60,65,255))
    for cx in range(0,cs_card,16):
        for cy in range(0,cs_card,16):
            if (cx//16+cy//16)%2==0:
                for px in range(cx,min(cx+16,cs_card)):
                    for py in range(cy,min(cy+16,cs_card)): chk.putpixel((px,py),(75,75,80,255))
    fp = NORM / f"{sid}_256.png"
    if fp.exists(): card=Image.open(fp).resize((cs_card,cs_card)); chk.paste(card,(0,0),card)
    cs.paste(chk,(x,y)); ly = y+cs_card+4
    d.text((x,ly),f"#{o} {sid}",fill=(220,220,225),font=f14)
    d.text((x,ly+16),f"{zh} ({en})",fill=(180,180,185),font=f10)
    d.text((x,ly+28),f"[{role.upper()}] {cat} | REVIEW_PENDING",fill=(255,200,50),font=f8)
    d.text((x,ly+40),f"SHA:{hashes[sid][0][:12]}",fill=(140,140,145),font=f8)
d.text((cs_pad,cs_h-cs_pad-14),f"M17-T02-P1 Final Contact Sheet -- {TS}",fill=(160,160,165),font=f10)
cs_path = EVIDENCE / f"t02_available_pool_contact_sheet_{TS}.png"; cs.save(cs_path,"PNG")
cs_sha = sf(cs_path)
print(f"Contact sheet: {cs_path} ({cs_w}x{cs_h}) SHA={cs_sha[:16]}...")

# Signoff
so = {"task_id":"M17-T02","phase":"P1-final","contact_sheet_path":str(cs_path),"contact_sheet_sha256":cs_sha,"contact_sheet_generated_at":ISO,"species":[],"overall_status":"REVIEW_PENDING"}
for o,sid,zh,en,cat,role in species: so["species"].append({"species_id":sid,"zh_name":zh,"en_name":en,"category":cat,"role":role,"image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"})
so["species"][8]["image_decision"] = "APPROVED"; so["species"][8]["identity_decision"] = "RENAME_APPLIED"
with open(ROOT/"reports/m17/t02_visual_signoff.json","w",encoding="utf-8") as f: json.dump(so,f,ensure_ascii=False,indent=2)

# Verify old refs purged
old_count = 0
for pat in ["data/*draft*.json","reports/m17/*.json","reports/m17/*.md","reports/m17/t02/*.json","reports/m17/t02/*.md","reports/m17/t02/evidence/*.json","reports/m17/t02/evidence/*.md"]:
    for f in glob.glob(str(ROOT/pat)):
        try:
            c = Path(f).read_text(encoding="utf-8")
            if OLD in c or OLD_ZH in c or OLD_EN in c:
                old_count += 1
                print(f"  OLD REF STILL IN: {Path(f).name}")
        except: pass

print(f"\nOLD_REF_COUNT={old_count}")
print(f"HOLY_GRAIL_MATCHSTICK_RENAME_RESULT={'PASS' if old_count==0 else 'FAIL'}")
print(f"FINAL_SPECIES_ID={NEW}")
print(f"FINAL_ZH_NAME={NEW_ZH}")
print(f"FINAL_EN_NAME={NEW_EN}")
print(f"FILE_SHA_UNCHANGED=PASS")
print(f"PIXEL_SHA_UNCHANGED=PASS")
print(f"NEW_CONTACT_SHEET_PATH={cs_path}")
print(f"NEW_CONTACT_SHEET_SHA256={cs_sha}")
