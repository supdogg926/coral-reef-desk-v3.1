"""
M17-T02-P1 Seedream 4.5 generation script.
Reads API key from SEEDREAM_API_KEY env var only. No hardcoded keys.
"""
import os, sys, json, time, hashlib
from pathlib import Path
from datetime import datetime, timezone, timedelta

API_KEY = os.environ.get("SEEDREAM_API_KEY")
if not API_KEY:
    print("FATAL: SEEDREAM_API_KEY not set")
    sys.exit(1)

ENDPOINT = "ep-20260625021114-w7ll4"
URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
OUT_DIR = Path("assets/m17/t02/source_candidates")
RECORDS_DIR = Path("reports/m17/t02/generation_records")
OUT_DIR.mkdir(parents=True, exist_ok=True)
RECORDS_DIR.mkdir(parents=True, exist_ok=True)

HEADERS = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
TZ = timezone(timedelta(hours=8))

SPECIES = [
    {
        "species_id": "rescue_seahorse",
        "zh_name": "受困海马",
        "category": "fish",
        "background": "纯白色背景",
        "prompt": "单只海马，直立体型，卷曲尾巴，管状吻部，橙色或黄色体色，体表有骨环纹路，完整全身入镜，正面或侧面视角，纯白色背景，摄影棚均匀打光，轻度写实风格，适合游戏救助卡图，生物特征准确",
    },
    {
        "species_id": "rescue_hermit_crab",
        "zh_name": "寄居蟹",
        "category": "crustacean",
        "background": "纯白色背景",
        "prompt": "单只寄居蟹，背着螺壳，露出头部和两只螯足，红褐色或灰褐色体色，螺壳纹理清晰，完整全身入镜，正面或侧面视角，纯白色背景，摄影棚均匀打光，轻度写实风格，适合游戏救助卡图，生物特征准确",
    },
    {
        "species_id": "rescue_sea_star",
        "zh_name": "海星",
        "category": "invertebrate",
        "background": "纯黑色背景",
        "prompt": "单只海星，五腕辐射对称体型，橙色或红色体色，体表粗糙有小突起，完整全身入镜，俯视视角，纯黑色背景，摄影棚均匀打光，轻度写实风格，适合游戏救助卡图，生物特征准确",
    },
]

results = []
for sp in SPECIES:
    sp_records = {
        "species_id": sp["species_id"],
        "zh_name": sp["zh_name"],
        "attempts": [],
    }
    for attempt_num in range(1, 5):  # max 4 attempts
        requested_at = datetime.now(TZ).isoformat()
        print(f"\n[{sp['species_id']}] Attempt {attempt_num}/4 @ {requested_at}")
        payload = {
            "model": ENDPOINT,
            "prompt": sp["prompt"],
            "size": "2432x1536",
            "n": 1,
            "response_format": "url",
            "watermark": False,
        }
        try:
            r = __import__("requests").post(URL, headers=HEADERS, json=payload, timeout=120)
            print(f"  HTTP {r.status_code}")
            if r.status_code != 200:
                err_text = r.text[:400]
                print(f"  ERROR: {err_text}")
                sp_records["attempts"].append({
                    "attempt_number": attempt_num,
                    "requested_at": requested_at,
                    "completed_at": datetime.now(TZ).isoformat(),
                    "status": "api_error",
                    "error": err_text,
                })
                continue

            data = r.json()
            img_url = data["data"][0]["url"]
            img_data = __import__("requests").get(img_url, timeout=60).content
            fname = f"{sp['species_id']}_attempt{attempt_num:02d}.png"
            fpath = OUT_DIR / fname
            fpath.write_bytes(img_data)
            sha = hashlib.sha256(img_data).hexdigest()
            completed_at = datetime.now(TZ).isoformat()
            size_kb = len(img_data) // 1024
            print(f"  OK -> {fname} ({size_kb}KB, SHA256={sha[:12]}...)")

            attempt_record = {
                "attempt_number": attempt_num,
                "requested_at": requested_at,
                "completed_at": completed_at,
                "output_path": str(fpath),
                "output_sha256": sha,
                "file_size_bytes": len(img_data),
                "status": "generated",
            }
            sp_records["attempts"].append(attempt_record)

            # Check basic quality with PIL
            try:
                from PIL import Image
                img = Image.open(fpath)
                attempt_record["width"] = img.size[0]
                attempt_record["height"] = img.size[1]
                attempt_record["format"] = img.format
                attempt_record["mode"] = img.mode
                print(f"  Resolution: {img.size}, Mode: {img.mode}")
            except Exception as e:
                print(f"  PIL check warning: {e}")

            # If we got this far, the generation succeeded. Don't retry.
            # Visual quality review is for the producer, not automated here.
            break

        except Exception as e:
            print(f"  EXCEPTION: {e}")
            sp_records["attempts"].append({
                "attempt_number": attempt_num,
                "requested_at": requested_at,
                "completed_at": datetime.now(TZ).isoformat(),
                "status": "exception",
                "error": str(e),
            })
        time.sleep(3)

    results.append(sp_records)

# Save generation records
record_path = RECORDS_DIR / "generation_records.json"
record_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
print(f"\nGeneration records saved to {record_path}")

# Summary
for r in results:
    attempts = len(r["attempts"])
    last = r["attempts"][-1] if r["attempts"] else None
    status = last.get("status", "no_attempts") if last else "no_attempts"
    print(f"  {r['species_id']}: {attempts} attempt(s), final status={status}")

ok = sum(1 for r in results if r["attempts"] and r["attempts"][-1].get("status") == "generated")
print(f"\nGenerated: {ok}/{len(SPECIES)}")
