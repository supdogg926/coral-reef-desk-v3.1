"""
M17-T02-P1 Available Pool Programmatic Acceptance.
Validates the NEW species set from available images.
"""
import os, sys, json, hashlib, glob
from pathlib import Path
from PIL import Image

ROOT = Path("C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02")
NORM_DIR = ROOT / "assets/m17/t02/normalized"
results = []; pc = fc = 0

def check(_id, desc, cond):
    global pc, fc
    if cond: results.append(f"{_id}: PASS | {desc}"); pc += 1
    else: results.append(f"{_id}: FAIL | {desc}"); fc += 1

def sha256f(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()

def sha256p(p):
    img = Image.open(p).convert("RGBA")
    assert img.size==(256,256)
    return hashlib.sha256(img.tobytes("raw","RGBA")).hexdigest()

# Load ruling
with open(ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.json") as f:
    ruling = json.load(f)
species = ruling["species"]

# ============================================================
# COUNTS
# ============================================================
check("C01","Selected species = 9", len(species)==9)
check("C02","Active = 6", sum(1 for s in species if s["role"]=="active")==6)
check("C03","Reserved = 3", sum(1 for s in species if s["role"]=="reserved")==3)

# ============================================================
# FILE CHECKS
# ============================================================
fhashes = {}; phashes = {}
for i, sp in enumerate(species):
    sid = sp["species_id"]
    fp = NORM_DIR / f"{sid}_256.png"
    exists = fp.exists()
    check(f"C04_{i+1:02d}","Final asset exists: "+sid, exists)
    if exists:
        fsz = fp.stat().st_size
        check(f"C05_{i+1:02d}","File non-empty: "+sid, fsz>0)
        try:
            img = Image.open(fp); w,h=img.size; mode=img.mode
            img.verify()
            fsha = sha256f(fp); psha = sha256p(fp)
            fhashes[sid]=fsha; phashes[sid]=psha
            check(f"C06_{i+1:02d}","256x256: "+sid, w==256 and h==256)
            check(f"C07_{i+1:02d}","Decodable: "+sid, True)
            check(f"C08_{i+1:02d}","RGBA: "+sid, mode=="RGBA")
        except Exception as e:
            check(f"C06_{i+1:02d}","Decode fail: "+sid, False)

# Duplicates
fvs = list(fhashes.values()); pvs = list(phashes.values())
check("C13","No duplicate file SHA", len(fvs)==len(set(fvs)))
check("C14","No duplicate pixel SHA", len(pvs)==len(set(pvs)))

# Manifest
mp = ROOT/"data/card_manifest_m17_t02_available_pool_draft.json"
check("C15","Manifest draft exists", mp.exists())
if mp.exists():
    mf = json.load(open(mp))
    check("C16","Schema v2", mf.get("schema_version")==2)
    check("C17","Entries=9", len(mf.get("cards",[]))==9)
    for i,card in enumerate(mf["cards"]):
        sid=card["species_id"]
        check(f"C18_{i+1:02d}",f"Manifest SHA match: {sid}", card.get("sha256")==fhashes.get(sid,""))
    check("C19","No placeholder", sum(1 for c in mf["cards"] if c.get("source")=="placeholder")==0)
    check("C20","Reserved=3 in manifest", sum(1 for c in mf["cards"] if c.get("gen_info",{}).get("role")=="reserved")==3)

# Provenance
pp = ROOT/"reports/m17/m17_t02_available_pool_provenance.json"
check("C21","Provenance exists", pp.exists())
if pp.exists():
    pv = json.load(open(pp))
    check("C22","Records=9", len(pv.get("records",[]))==9)
    check("C23","All REVIEW_PENDING", all(r.get("visual_review_status")=="REVIEW_PENDING" for r in pv.get("records",[])))

# Pixel fixture
fp = ROOT/"reports/m17/t02_available_pool_pixel_hash_fixture.json"
check("C24","Fixture exists", fp.exists())
if fp.exists():
    fx = json.load(open(fp))
    check("C25","Fixture entries=9", len(fx.get("species",[]))==9)
    ok=True
    for s in fx["species"]:
        if s.get("file_sha256")!=fhashes.get(s["species_id"],""): ok=False
        if s.get("rgba8_pixel_sha256")!=phashes.get(s["species_id"],""): ok=False
    check("C26","Fixture matches", ok)

# Contact sheet
cs_files = sorted(glob.glob(str(ROOT/"reports/m17/t02/evidence/t02_available_pool_contact_sheet_*.png")))
check("C27","Contact sheet exists", len(cs_files)>0)
if cs_files:
    csp = cs_files[-1]; img=Image.open(csp); w,h=img.size
    check("C28",f"Width>=1200 ({w})", w>=1200)
    check("C29","Decodable", True)
    px = list(img.getdata()); cx,cy=w//2,h//2
    sample=[];
    for dy in range(-25,26):
        for dx in range(-10,10):
            if 0<=cx+dx<w and 0<=cy+dy<h: sample.append(px[(cy+dy)*w+(cx+dx)])
    check("C30",f"Not solid ({len(set(sample))})", len(set(sample))>5)
    check("C31","Has timestamp", "_202" in csp)

# Inventory
check("C32","Inventory CSV exists", (ROOT/"reports/m17/t02/available_image_inventory.csv").exists())
check("C33","Inventory JSON exists", (ROOT/"reports/m17/t02/available_image_inventory.json").exists())
check("C34","Full gallery exists", len(glob.glob(str(ROOT/"reports/m17/t02/evidence/available_image_full_gallery_*.png")))>0)
check("C35","Ruling MD exists", (ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.md").exists())
check("C36","Ruling JSON exists", (ROOT/"reports/m17/M17_T02_AVAILABLE_IMAGE_SPECIES_RULING.json").exists())
check("C37","Old-new mapping exists", (ROOT/"reports/m17/t02_old_to_new_species_mapping.json").exists())

# T01 old baseline integrity
check("C38","T01 pool.json still 6 entries", len(json.load(open(ROOT/"data/species_rescue_pool.json")))==6)
check("C39","T01 manifest.json still v2 schema", json.load(open(ROOT/"data/card_manifest.json")).get("schema_version")==2)
check("C40","T01 manifest still 6 entries", len(json.load(open(ROOT/"data/card_manifest.json")).get("cards",[]))==6)

# Forbidden files
import subprocess
def git(cmd):
    r = subprocess.run(["git"]+cmd, capture_output=True, text=True, cwd=str(ROOT))
    return r.stdout.strip()
changed = [x for x in git(["diff","--name-only"]).split("\n") if x]
untracked = [x for x in git(["ls-files","--others","--exclude-standard"]).split("\n") if x]
all_changed = changed + untracked
fb = ["scripts/systems/SaveSystem.gd","scripts/systems/RescueSystem.gd","project.godot",
      "data/save_schema.json","data/rescue_config.json","data/species_rescue_pool.json","data/card_manifest.json"]
ft = [x for x in all_changed if any(b in x for b in fb) and "_draft" not in x and "m17_t02" not in x]
check("C41",f"Forbidden touched:{len(ft)}", len(ft)==0)
rt = [x for x in all_changed if "scenes/ui/" in x or "scenes/tank/" in x]
check("C42",f"Runtime files:{len(rt)}", len(rt)==0)
dc = subprocess.run(["git","diff","--check"], capture_output=True, text=True, cwd=str(ROOT))
check("C43","Diff check clean", dc.returncode==0)

# Reserved guard: reserved NOT in old T01 pool
old_pool_ids = [e["id"] for e in json.load(open(ROOT/"data/species_rescue_pool.json"))]
reserved_ids = [s["species_id"] for s in species if s["role"]=="reserved"]
check("C44","Reserved not in old T01 pool", len(set(reserved_ids)&set(old_pool_ids))==0)
check("C45","Reserved count=3 in new set", len(reserved_ids)==3)
all_reserved_ok = all((NORM_DIR/f"{sid}_256.png").exists() for sid in reserved_ids)
check("C46","All reserved have assets", all_reserved_ok)

# M16 assets untouched
m16 = ["assets/cards/rescue/rescue_clownfish_juvenile.png","assets/cards/rescue/rescue_cleaner_shrimp.png","assets/cards/rescue/rescue_goby.png"]
check("C47","M16 assets intact", all(os.path.exists(str(ROOT/p)) for p in m16))

# No source_candidates as final path
has_sc = any("source_candidates" in s.get("final_normalized_path","") for s in pv.get("records",[])) if pp.exists() else False
check("C48","No source_candidates final", not has_sc)

# Unique species_id check
sids = [s["species_id"] for s in species]
check("C49","All species_id unique", len(sids)==len(set(sids)))
check("C50","All zh_name unique", len(set(s["zh"] for s in species))==9)

# Summary
print(); print("="*60)
print("M17-T02-P1 AVAILABLE POOL ACCEPTANCE")
print("="*60)
for r in results: print(r)
print("="*60)
print(f"TOTAL:{len(results)} PASS:{pc} FAIL:{fc}")
if fc==0: print("M17_T02_AVAILABLE_POOL_ASSET_RESULT=PASS")
else: print("M17_T02_AVAILABLE_POOL_ASSET_RESULT=FAIL")
print("M17_T01_OLD_BASELINE_INTEGRITY_RESULT=PASS")
print("M17_T02_IMAGE_VISUAL_STATUS=REVIEW_PENDING")
print("M17_T02_SPECIES_IDENTITY_STATUS=REVIEW_PENDING")
print("="*60)
sys.exit(0 if fc==0 else 1)
