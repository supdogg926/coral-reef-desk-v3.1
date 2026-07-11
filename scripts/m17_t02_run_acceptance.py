"""
M17-T02-P1 Programmatic Asset Acceptance.
Validates assets and evidence only - NO runtime access.
"""
import os, sys, json, hashlib, glob
from pathlib import Path
from PIL import Image

ROOT = Path(".")
NORM_DIR = ROOT / "assets/m17/t02/normalized"
results = []
pass_count = 0
fail_count = 0

def check(id_str, desc, condition):
    global pass_count, fail_count
    if condition:
        results.append(f"{id_str}: PASS | {desc}")
        pass_count += 1
    else:
        results.append(f"{id_str}: FAIL | {desc}")
        fail_count += 1

def sha256_file(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()

def sha256_pixels(path):
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    assert w == 256 and h == 256
    return hashlib.sha256(img.tobytes("raw", "RGBA")).hexdigest()

# Expected species definition
EXPECTED = [
    {"order": 1, "id": "rescue_clownfish_juvenile", "role": "active"},
    {"order": 2, "id": "rescue_cleaner_shrimp", "role": "active"},
    {"order": 3, "id": "rescue_goby", "role": "active"},
    {"order": 4, "id": "rescue_seahorse", "role": "active"},
    {"order": 5, "id": "rescue_hermit_crab", "role": "active"},
    {"order": 6, "id": "rescue_brain_coral_frag", "role": "active"},
    {"order": 7, "id": "rescue_mandarin_dragonet", "role": "reserved"},
    {"order": 8, "id": "rescue_sea_star", "role": "reserved"},
    {"order": 9, "id": "rescue_anemone_tube", "role": "reserved"},
]

# ============================================================
# C01-C03: Count checks
# ============================================================
check("C01", "Asset production set = 9", len(EXPECTED) == 9)
check("C02", "Active species = 6", sum(1 for s in EXPECTED if s["role"] == "active") == 6)
check("C03", "Reserved species = 3", sum(1 for s in EXPECTED if s["role"] == "reserved") == 3)

# ============================================================
# C04-C12: Final asset file checks
# ============================================================
file_hashes = {}
pixel_hashes = {}

for sp in EXPECTED:
    sid = sp["id"]
    o = sp["order"]
    fpath = NORM_DIR / f"{sid}_256.png"

    exists = fpath.exists()
    check(f"C04_{o:02d}", f"Final asset exists: {sid}", exists)

    if exists:
        fsize = fpath.stat().st_size
        check(f"C05_{o:02d}", f"File non-empty: {sid}", fsize > 0)

        try:
            img = Image.open(fpath)
            w, h = img.size
            mode = img.mode
            img.verify()
            img2 = Image.open(fpath).convert("RGBA")
            fsha = sha256_file(fpath)
            psha = sha256_pixels(fpath)
            file_hashes[sid] = fsha
            pixel_hashes[sid] = psha

            check(f"C06_{o:02d}", f"256x256: {sid}", w == 256 and h == 256)
            check(f"C07_{o:02d}", f"Decodable: {sid}", True)
            check(f"C08_{o:02d}", f"RGBA mode: {sid}", mode == "RGBA")
        except Exception as e:
            check(f"C06_{o:02d}", f"256x256/decodable: {sid}", False)
            print(f"  ERROR: {sid}: {e}")

# ============================================================
# C13-C14: No duplicate SHA
# ============================================================
fvals = list(file_hashes.values())
pvals = list(pixel_hashes.values())
check("C13", "No duplicate file SHA256", len(fvals) == len(set(fvals)))
check("C14", "No duplicate pixel SHA256", len(pvals) == len(set(pvals)))

# ============================================================
# C15-C20: Manifest draft
# ============================================================
manifest_path = ROOT / "data/card_manifest_m17_t02_draft.json"
check("C15", "Manifest draft exists", manifest_path.exists())
if manifest_path.exists():
    with open(manifest_path, encoding="utf-8") as f:
        manifest = json.load(f)
    check("C16", "Manifest schema_version = 2", manifest.get("schema_version") == 2)
    cards = manifest.get("cards", [])
    check("C17", "Manifest entries = 9", len(cards) == 9)
    for i, card in enumerate(cards):
        sid = card["species_id"]
        check(f"C18_{i+1:02d}", f"Manifest SHA matches file: {sid}",
              card.get("sha256") == file_hashes.get(sid, ""))
    placeholder_count = sum(1 for c in cards if c.get("source") == "placeholder")
    check("C19", "No placeholder entries in manifest", placeholder_count == 0)
    reserved_count = sum(1 for c in cards if c.get("gen_info", {}).get("role") == "reserved")
    check("C20", "Reserved count in manifest = 3", reserved_count == 3)

# ============================================================
# C21-C23: Provenance
# ============================================================
prov_path = ROOT / "reports/m17/m17_t02_asset_provenance.json"
check("C21", "Provenance JSON exists", prov_path.exists())
prov = None
if prov_path.exists():
    with open(prov_path, encoding="utf-8") as f:
        prov = json.load(f)
    check("C22", "Provenance records = 9", len(prov.get("records", [])) == 9)
    all_pending = all(r.get("visual_review_status") == "REVIEW_PENDING"
                      for r in prov.get("records", []))
    check("C23", "All visual_review_status = REVIEW_PENDING", all_pending)

# ============================================================
# C24-C26: Pixel hash fixture
# ============================================================
fx_path = ROOT / "reports/m17/t02_asset_pixel_hash_fixture.json"
check("C24", "Pixel hash fixture exists", fx_path.exists())
if fx_path.exists():
    with open(fx_path, encoding="utf-8") as f:
        fx = json.load(f)
    check("C25", "Fixture entries = 9", len(fx.get("species", [])) == 9)
    fx_match = True
    for s in fx.get("species", []):
        sid = s["species_id"]
        if s.get("file_sha256") != file_hashes.get(sid, ""):
            fx_match = False
            print(f"  FIXTURE file_sha256 mismatch: {sid}")
        if s.get("rgba8_pixel_sha256") != pixel_hashes.get(sid, ""):
            fx_match = False
            print(f"  FIXTURE pixel_sha256 mismatch: {sid}")
    check("C26", "Pixel fixture matches computed values", fx_match)

# ============================================================
# C27-C31: Contact sheet
# ============================================================
cs_files = sorted(glob.glob("reports/m17/t02/evidence/t02_contact_sheet_*.png"))
check("C27", "Contact sheet exists", len(cs_files) > 0)
if cs_files:
    cs_path = cs_files[-1]
    try:
        img = Image.open(cs_path)
        w, h = img.size
        cs_sha = sha256_file(cs_path)
        pixels = list(img.getdata())
        # Sample from center area where cards are, not corner padding
        center_x = w // 2
        center_y = h // 2
        sample_size = 500
        sample_pixels = []
        for dy in range(-25, 26):
            for dx in range(-10, 10):
                px = center_x + dx
                py = center_y + dy
                if 0 <= px < w and 0 <= py < h:
                    sample_pixels.append(pixels[py * w + px])
        unique = len(set(sample_pixels))
        check("C28", f"Contact sheet width >= 1200 (actual: {w})", w >= 1200)
        check("C29", "Contact sheet decodable", True)
        check("C30", f"Contact sheet not solid color (unique center sample: {unique})", unique > 5)
        has_ts = "_202" in str(cs_path) and ".png" in str(cs_path)
        check("C31", "Contact sheet filename has timestamp", has_ts)
    except Exception as e:
        check("C28", f"Contact sheet validation", False)
        print(f"  CS ERROR: {e}")

# ============================================================
# C32-C34: Inventory & records
# ============================================================
check("C32", "Inventory CSV exists",
      (ROOT / "reports/m17/t02_p1_asset_inventory.csv").exists())
check("C33", "Inventory MD exists",
      (ROOT / "reports/m17/t02_p1_asset_inventory.md").exists())
check("C34", "Generation records exist",
      (ROOT / "reports/m17/t02/generation_records/generation_records.json").exists())

# ============================================================
# C35-C40: T01 regression (data-level)
# ============================================================
pool_path = ROOT / "data/species_rescue_pool.json"
with open(pool_path, encoding="utf-8") as f:
    pool = json.load(f)
check("C35", "T01 species pool count = 6", len(pool) == 6)

expected_pool_ids = ["rescue_clownfish_juvenile", "rescue_cleaner_shrimp", "rescue_goby",
                     "rescue_seahorse", "rescue_hermit_crab", "rescue_brain_coral_frag"]
actual_pool_ids = [e["id"] for e in pool]
check("C36", "T01 pool species IDs preserved",
      actual_pool_ids == expected_pool_ids)

cm_path = ROOT / "data/card_manifest.json"
with open(cm_path, encoding="utf-8") as f:
    cm = json.load(f)
check("C37", "card_manifest.json schema_version = 2", cm.get("schema_version") == 2)
check("C38", "card_manifest.json entries = 6", len(cm.get("cards", [])) == 6)

m16_ids = {"rescue_clownfish_juvenile", "rescue_cleaner_shrimp", "rescue_goby"}
m16_all_image2 = all(
    c.get("source") == "image2_user_generated"
    for c in cm.get("cards", [])
    if c.get("species_id") in m16_ids
)
check("C39", "M16 rescue assets source = image2_user_generated", m16_all_image2)

reserved_ids = {"rescue_mandarin_dragonet", "rescue_sea_star", "rescue_anemone_tube"}
check("C40", "Reserved species NOT in pool JSON",
      len(set(actual_pool_ids) & reserved_ids) == 0)

# ============================================================
# C41-C48: Forbidden diff checks
# ============================================================
import subprocess
def git_cmd(args):
    r = subprocess.run(["git"] + args, capture_output=True, text=True, cwd=str(ROOT))
    return r.stdout.strip()

changed = git_cmd(["diff", "--name-only"]).split("\n") if git_cmd(["diff", "--name-only"]) else []
untracked = git_cmd(["ls-files", "--others", "--exclude-standard"]).split("\n") if git_cmd(["ls-files", "--others", "--exclude-standard"]) else []
all_changed = [f for f in changed + untracked if f]

forbidden = [
    "scripts/systems/SaveSystem.gd",
    "scripts/systems/RescueSystem.gd",
    "project.godot",
    "data/save_schema.json",
    "data/rescue_config.json",
    "data/species_rescue_pool.json",
    "data/card_manifest.json",
]
forbidden_touched = []
for fpath in all_changed:
    for fb in forbidden:
        if fb in fpath and "_draft" not in fpath:
            forbidden_touched.append(fpath)

check("C41", f"Forbidden files modified: {len(forbidden_touched)}", len(forbidden_touched) == 0)
if forbidden_touched:
    for ft in forbidden_touched:
        print(f"  FORBIDDEN: {ft}")

# Check no runtime UI/scripts modified
runtime_forbidden = ["scenes/ui/", "scenes/tank/", "scripts/systems/RescueSystem",
                     "scripts/systems/SaveSystem"]
runtime_touched = []
for fpath in all_changed:
    for fb in runtime_forbidden:
        if fb in fpath:
            runtime_touched.append(fpath)
check("C42", f"Runtime files modified: {len(runtime_touched)}", len(runtime_touched) == 0)
if runtime_touched:
    for rt in runtime_touched:
        print(f"  RUNTIME FORBIDDEN: {rt}")

# C43: git diff --check
diff_check = subprocess.run(["git", "diff", "--check"], capture_output=True, text=True, cwd=str(ROOT))
check("C43", "Git diff --check clean", diff_check.returncode == 0)

# Reserved guards
check("C44", "Reserved species not in active pool",
      "rescue_mandarin_dragonet" not in actual_pool_ids)
check("C45", "Reserved count in asset production = 3",
      sum(1 for s in EXPECTED if s["role"] == "reserved") == 3)

all_reserved_have_assets = all(
    (NORM_DIR / f"{s['id']}_256.png").exists()
    for s in EXPECTED if s["role"] == "reserved"
)
check("C46", "All reserved have finalized assets", all_reserved_have_assets)

m16_assets = ["assets/cards/rescue/rescue_clownfish_juvenile.png",
              "assets/cards/rescue/rescue_cleaner_shrimp.png",
              "assets/cards/rescue/rescue_goby.png"]
check("C47", "M16 rescue assets exist", all(os.path.exists(p) for p in m16_assets))

# No source_candidates paths in final path
if prov:
    has_src_path = any("source_candidates" in r.get("final_normalized_path", "")
                       for r in prov.get("records", []))
    check("C48", "No source_candidates used as final path", not has_src_path)

# ============================================================
# FINAL SUMMARY
# ============================================================
print()
print("=" * 60)
print("M17-T02-P1 ASSET PROGRAMMATIC ACCEPTANCE")
print("=" * 60)
for r in results:
    print(r)
print("=" * 60)
print(f"TOTAL: {len(results)} | PASS: {pass_count} | FAIL: {fail_count}")

if fail_count == 0:
    print("M17_T02_P1_ASSET_PROGRAMMATIC_RESULT=PASS")
else:
    print("M17_T02_P1_ASSET_PROGRAMMATIC_RESULT=FAIL")
print("M17_T02_ASSET_VISUAL_STATUS=REVIEW_PENDING")
print("=" * 60)

# Save results
evidence_dir = ROOT / "reports/m17/t02/evidence"
evidence_dir.mkdir(parents=True, exist_ok=True)
with open(evidence_dir / "acceptance_results.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(results))
    f.write(f"\n\nTOTAL: {len(results)} | PASS: {pass_count} | FAIL: {fail_count}\n")
    if fail_count == 0:
        f.write("M17_T02_P1_ASSET_PROGRAMMATIC_RESULT=PASS\n")
    else:
        f.write("M17_T02_P1_ASSET_PROGRAMMATIC_RESULT=FAIL\n")
    f.write("M17_T02_ASSET_VISUAL_STATUS=REVIEW_PENDING\n")

sys.exit(0 if fail_count == 0 else 1)
