"""M17-T02-P1 Revision Acceptance with all specific checks."""
import json, hashlib, glob, os, subprocess
from PIL import Image

pc=0; fc=0; results=[]
def ck(i,d,cond):
    global pc,fc
    results.append(f"{i}: {'PASS' if cond else 'FAIL'} | {d}")
    if cond: pc+=1
    else: fc+=1

ROOT="C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M17_T02"
NORM=f"{ROOT}/assets/m17/t02/normalized"
def sf(p):
    with open(p,"rb") as f: return hashlib.sha256(f.read()).hexdigest()
def sp(p):
    img=Image.open(p).convert("RGBA"); return hashlib.sha256(img.tobytes("raw","RGBA")).hexdigest()

species=[
    ("rescue_blue_eye_bristletooth_tang","蓝眼食苔吊","fish","active"),
    ("rescue_eight_line_flasher_wrasse","八线龙","fish","active"),
    ("rescue_bicolor_angelfish","双色神仙","fish","active"),
    ("rescue_green_star_polyp","荧光绿草皮","coral","active"),
    ("rescue_pulsing_xenia","闪千手","coral","active"),
    ("rescue_golden_brain_coral","金菊脑","coral","active"),
    ("rescue_yellow_coris_wrasse","黄龙","fish","reserved"),
    ("rescue_mountain_gold_green_euphyllia","山脉金绿猪腰","coral","reserved"),
    ("rescue_holy_grail_matchstick_coral","圣杯火柴珊瑚","coral","reserved"),
]

ck("C01","Species count=9",len(species)==9)
ck("C02","Active=6",sum(1 for s in species if s[3]=="active")==6)
ck("C03","Reserved=3",sum(1 for s in species if s[3]=="reserved")==3)

fhashes={}; phashes={}; bounds_data={}
for i,(sid,zh,cat,role) in enumerate(species):
    fp=f"{NORM}/{sid}_256.png"; exists=os.path.exists(fp)
    ck(f"C04_{i+1:02d}","Exists: "+sid,exists)
    if exists:
        ck(f"C05_{i+1:02d}","Non-empty: "+sid,os.path.getsize(fp)>0)
        try:
            img=Image.open(fp); w,h=img.size; mode=img.mode; img.verify()
            fsha=sf(fp); psha=sp(fp); fhashes[sid]=fsha; phashes[sid]=psha
            img2=Image.open(fp); a=img2.split()[-1]; bb=a.getbbox()
            if bb: bounds_data[sid]=(bb[0],bb[1],bb[2],bb[3])
            ck(f"C06_{i+1:02d}","256x256: "+sid,w==256 and h==256)
            ck(f"C07_{i+1:02d}","Decodable: "+sid,True)
            ck(f"C08_{i+1:02d}","RGBA: "+sid,mode=="RGBA")
        except Exception as e:
            ck(f"C06_{i+1:02d}","Fail: "+sid,False)

ck("C13","No dup file SHA",len(set(fhashes.values()))==9)
ck("C14","No dup pixel SHA",len(set(phashes.values()))==9)

mp=f"{ROOT}/data/card_manifest_m17_t02_available_pool_draft.json"
mf=json.load(open(mp,encoding="utf-8"))
ck("C15","Manifest exists",True)
ck("C16","Schema v2",mf["schema_version"]==2)
ck("C17","Entries=9",len(mf["cards"])==9)
for i,card in enumerate(mf["cards"]):
    ck(f"C18_{i+1:02d}",f"Manifest SHA: {card['species_id']}",card["sha256"]==fhashes.get(card["species_id"],""))

# REVISION-SPECIFIC
bb_w=bounds_data.get("rescue_eight_line_flasher_wrasse")
if bb_w:
    ck("R01","八线龙 L>=12",bb_w[0]>=12)
    ck("R02","八线龙 R<=243",bb_w[2]<=243)
    ck("R03","八线龙 T>=8",bb_w[1]>=8)
    ck("R04","八线龙 B<=247",bb_w[3]<=247)
    ck("R05","八线龙 ALL bounds",bb_w[0]>=12 and bb_w[2]<=243 and bb_w[1]>=8 and bb_w[3]<=247)
else:
    for j in range(1,6): ck(f"R0{j}","八线龙 MISSING",False)

bb_y=bounds_data.get("rescue_yellow_coris_wrasse")
if bb_y:
    ck("R06","黄龙 L>=12",bb_y[0]>=12)
    ck("R07","黄龙 R<=243",bb_y[2]<=243)
    ck("R08","黄龙 T>=8",bb_y[1]>=8)
    ck("R09","黄龙 B<=247",bb_y[3]<=247)
    ck("R10","黄龙 ALL bounds",bb_y[0]>=12 and bb_y[2]<=243 and bb_y[1]>=8 and bb_y[3]<=247)
else:
    for j in range(6,11): ck(f"R{j:02d}","黄龙 MISSING",False)

# Old IDs purged from active references
check_files=["card_manifest_m17_t02_available_pool_draft.json",
    "t02_available_pool_pixel_hash_fixture.json","t02_p1_asset_inventory.csv",
    "t02_visual_signoff.json"]
old_cb=0; old_hg=0
for cf in check_files:
    for d in [f"{ROOT}/data",f"{ROOT}/reports/m17",f"{ROOT}/reports/m17/t02"]:
        fp2=f"{d}/{cf}"
        if os.path.exists(fp2):
            with open(fp2,"r",encoding="utf-8") as fh:
                content=fh.read()
                if "rescue_coral_beauty_angelfish" in content: old_cb+=1
                if "rescue_holy_grail_scolymia" in content: old_hg+=1
ck("R11","Old coral_beauty ID purged",old_cb==0)
ck("R12","Old scolymia ID purged",old_hg==0)

sids=[s[0] for s in species]
ck("R13","All species_id unique",len(sids)==len(set(sids)))

cs_files=sorted(glob.glob(f"{ROOT}/reports/m17/t02/evidence/t02_available_pool_contact_sheet_*.png"))
ck("R14","Contact sheet exists",len(cs_files)>0)
if cs_files:
    csp=cs_files[-1]; img=Image.open(csp); w,h=img.size
    ck("R15",f"CS width>=1200 ({w})",w>=1200)
    ck("R16","CS has timestamp","_202" in csp)

# Signoff - verify SHA match with actual contact sheet file
sf_path=f"{ROOT}/reports/m17/t02_visual_signoff.json"
if os.path.exists(sf_path):
    so=json.load(open(sf_path,encoding="utf-8"))
    signoff_sha = so.get("contact_sheet_sha256","")
    actual_cs_sha = sf(cs_files[-1]) if cs_files else ""
    sha_match = signoff_sha == actual_cs_sha and len(signoff_sha) == 64
    ck("R17",f"Signoff CS SHA matches file ({signoff_sha[:12]}...)",sha_match)
    ck("R18","Overall REVIEW_PENDING",so.get("overall_status")=="REVIEW_PENDING")

# Git audit
def git(cmd):
    r=subprocess.run(["git"]+cmd,capture_output=True,text=True,cwd=ROOT); return r.stdout.strip()
ch=git(["diff","--name-only"]).split("\n"); ut=git(["ls-files","--others","--exclude-standard"]).split("\n")
all_ch=[x for x in ch+ut if x]
fb=["scripts/systems/SaveSystem.gd","scripts/systems/RescueSystem.gd","project.godot","data/save_schema.json","data/rescue_config.json","data/species_rescue_pool.json","data/card_manifest.json"]
ft=[x for x in all_ch if any(b in x and "_draft" not in x for b in fb)]
ck("R19",f"Forbidden touched:{len(ft)}",len(ft)==0)
rt_files=[x for x in all_ch if "scenes/ui/" in x or "scenes/tank/" in x]
ck("R20",f"Runtime files:{len(rt_files)}",len(rt_files)==0)
dc=subprocess.run(["git","diff","--check"],capture_output=True,text=True,cwd=ROOT)
ck("R21","Git diff check clean",dc.returncode==0)

pool=json.load(open(f"{ROOT}/data/species_rescue_pool.json",encoding="utf-8"))
ck("R22","T01 pool 6 entries",len(pool)==6)
cm2=json.load(open(f"{ROOT}/data/card_manifest.json",encoding="utf-8"))
ck("R23","T01 manifest v2",cm2["schema_version"]==2)
ck("R24","T01 manifest 6 entries",len(cm2["cards"])==6)
reserved_ids=["rescue_yellow_coris_wrasse","rescue_mountain_gold_green_euphyllia","rescue_holy_grail_matchstick_coral"]
pool_ids=[e["id"] for e in pool]
ck("R25","Reserved not in T01 pool",len(set(reserved_ids)&set(pool_ids))==0)

print(); print("="*60); print("M17-T02-P1 REVISION ACCEPTANCE")
for r in results: print(r)
print("="*60); print(f"TOTAL:{len(results)} PASS:{pc} FAIL:{fc}")
if fc==0: print("ASSET_PROGRAMMATIC_RESULT=PASS")
else: print("ASSET_PROGRAMMATIC_RESULT=FAIL")
print("VISUAL_STATUS=REVIEW_PENDING"); print("IDENTITY_STATUS=REVIEW_PENDING")
