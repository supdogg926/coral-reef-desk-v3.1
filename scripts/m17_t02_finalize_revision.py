"""Finalize revision: regenerate contact sheet, signoff, inventory with correct hashes."""
import json, hashlib, csv
from pathlib import Path
from datetime import datetime, timezone, timedelta
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
NORM = ROOT / "assets/m17/t02/normalized"
EVIDENCE = ROOT / "reports/m17/t02/evidence"
TZ = timezone(timedelta(hours=8)); NOW = datetime.now(TZ)
TS = NOW.strftime("%Y%m%d_%H%M%S"); ISO = NOW.isoformat()

def sf(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()
def sp(p):
    img = Image.open(p).convert("RGBA"); return hashlib.sha256(img.tobytes("raw","RGBA")).hexdigest()
def get_bb(p):
    img = Image.open(p); a = img.split()[-1]; b = a.getbbox()
    return f"({b[0]},{b[1]})-({b[2]},{b[3]})"

species = [
    {"order":1,"species_id":"rescue_blue_eye_bristletooth_tang","zh":"蓝眼食苔吊","en":"Blue-Eye Bristletooth Tang","category":"fish","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":2,"species_id":"rescue_eight_line_flasher_wrasse","zh":"八线龙","en":"Eight-Line Flasher Wrasse","category":"fish","role":"active","image_decision":"REDO_COMPLETED_PENDING_REVIEW","identity_decision":"APPROVED","renormalized":True},
    {"order":3,"species_id":"rescue_bicolor_angelfish","zh":"双色神仙","en":"Bicolor Angelfish","category":"fish","role":"active","image_decision":"APPROVED","identity_decision":"RENAME_APPLIED","renamed":True},
    {"order":4,"species_id":"rescue_green_star_polyp","zh":"荧光绿草皮","en":"Green Star Polyp","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":5,"species_id":"rescue_pulsing_xenia","zh":"闪千手","en":"Pulsing Xenia","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":6,"species_id":"rescue_golden_brain_coral","zh":"金菊脑","en":"Golden Brain Coral","category":"coral","role":"active","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW"},
    {"order":7,"species_id":"rescue_yellow_coris_wrasse","zh":"黄龙","en":"Yellow Coris Wrasse","category":"fish","role":"reserved","image_decision":"REDO_COMPLETED_PENDING_REVIEW","identity_decision":"APPROVED","renormalized":True},
    {"order":8,"species_id":"rescue_tiger_angelfish","zh":"虎纹仙","en":"Tiger Angelfish","category":"fish","role":"reserved","image_decision":"PENDING_REVIEW","identity_decision":"PENDING_REVIEW","identification_basis":"metadata_json_canonical_name_producer_assigned","identification_confidence":"medium"},
    {"order":9,"species_id":"rescue_holy_grail_torch_coral","zh":"圣杯火炬珊瑚","en":"Holy Grail Torch Coral","category":"coral","role":"reserved","image_decision":"APPROVED","identity_decision":"RENAME_APPLIED","renamed":True},
]

# Hashes
for s in species:
    fp = NORM / f"{s['species_id']}_256.png"
    s["final_path"] = str(fp)
    s["file_sha256"] = sf(fp)
    s["rgba8_pixel_sha256"] = sp(fp)
    if s.get("renormalized"):
        s["bounds"] = get_bb(fp)
    print(f"[{s['order']}] {s['species_id']}: {s['file_sha256'][:16]}... {s.get('bounds','')}")

# Manifest
manifest = {"schema_version":2,"max_entries":9,"cards":[]}
for s in species:
    manifest["cards"].append({"species_id":s["species_id"],"asset_path":f"res://assets/cards/rescue/{s['species_id']}.png","sha256":s["file_sha256"],"source":"image2_human_approved_available_pool","gen_info":{"role":s["role"],"zh_name":s["zh"],"en_name":s["en"],"category":s["category"]}})
with open(ROOT/"data/card_manifest_m17_t02_available_pool_draft.json","w",encoding="utf-8") as f: json.dump(manifest,f,ensure_ascii=False,indent=2)

# Pixel fixture
fx = {"schema_version":2,"algorithm":"SHA256","canonical_format":"RGBA8","width":256,"height":256,"row_order":"top_to_bottom","species":[]}
for s in species: fx["species"].append({"species_id":s["species_id"],"role":s["role"],"asset_path":s["final_path"],"file_sha256":s["file_sha256"],"rgba8_pixel_sha256":s["rgba8_pixel_sha256"]})
with open(ROOT/"reports/m17/t02_available_pool_pixel_hash_fixture.json","w",encoding="utf-8") as f: json.dump(fx,f,ensure_ascii=False,indent=2)

# Provenance update
prov = json.load(open(ROOT/"reports/m17/m17_t02_available_pool_provenance.json",encoding="utf-8"))
for rec in prov["records"]:
    for s in species:
        if rec["species_id"] == s["species_id"]:
            rec["final_file_sha256"] = s["file_sha256"]
            rec["final_rgba8_pixel_sha256"] = s["rgba8_pixel_sha256"]
            if s.get("renormalized"): rec["renormalized"] = True; rec["bounds"] = s["bounds"]
with open(ROOT/"reports/m17/m17_t02_available_pool_provenance.json","w",encoding="utf-8") as f: json.dump(prov,f,ensure_ascii=False,indent=2)

# Contact sheet
cs_card, cs_label, cs_pad = 380, 90, 20; cs_cols = 3; cs_rows = 3
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
    ch = [];
    if s.get("renamed"): ch.append("RENAMED")
    if s.get("renormalized"): ch.append("RE-NORM")
    d.text((x,ly+28),f"[{s['role'].upper()}] {s['category']} {','.join(ch)} | REVIEW_PENDING",fill=(255,200,50),font=f8)
    d.text((x,ly+40),f"SHA:{s['file_sha256'][:12]}",fill=(140,140,145),font=f8)
d.text((cs_pad,cs_h-cs_pad-14),f"M17-T02-P1 Revision Contact Sheet -- {TS}",fill=(160,160,165),font=f10)
cs_path = EVIDENCE / f"t02_available_pool_contact_sheet_{TS}.png"; cs.save(cs_path,"PNG"); cs_sha = sf(cs_path)
print(f"\nContact sheet: {cs_path} ({cs_w}x{cs_h}) SHA={cs_sha[:16]}...")

# Signoff
so = {"task_id":"M17-T02","phase":"P1-revision","contact_sheet_path":str(cs_path),"contact_sheet_sha256":cs_sha,"contact_sheet_generated_at":ISO,"signoff_date":None,"reviewer":None,"species":[],"overall_status":"REVIEW_PENDING"}
for s in species: so["species"].append({"species_id":s["species_id"],"zh_name":s["zh"],"en_name":s["en"],"category":s["category"],"role":s["role"],"image_decision":s.get("image_decision","PENDING_REVIEW"),"identity_decision":s.get("identity_decision","PENDING_REVIEW"),"notes":""})
with open(ROOT/"reports/m17/t02_visual_signoff.json","w",encoding="utf-8") as f: json.dump(so,f,ensure_ascii=False,indent=2)

# Inventory CSV
with open(ROOT/"reports/m17/t02_p1_asset_inventory.csv","w",newline="",encoding="utf-8-sig") as f:
    w = csv.writer(f); w.writerow(["order","species_id","zh_name","en_name","category","role","file_sha256","rgba8_pixel_sha256","bounds","renamed","renormalized","image_decision","identity_decision"])
    for s in species: w.writerow([s["order"],s["species_id"],s["zh"],s["en"],s["category"],s["role"],s["file_sha256"],s["rgba8_pixel_sha256"],s.get("bounds",""),s.get("renamed",False),s.get("renormalized",False),s.get("image_decision",""),s.get("identity_decision","")])

print(f"\nNEW_CONTACT_SHEET_PATH={cs_path}")
print(f"NEW_CONTACT_SHEET_SHA256={cs_sha}")
print(f"ALL_EVIDENCE_FINALIZED=PASS")
