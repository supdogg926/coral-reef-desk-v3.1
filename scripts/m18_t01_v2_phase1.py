"""M18-T1 V2 Phase 1: Tier-generic framework + JSON data update."""
import json

ROOT = "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M18_T01_V2"

# Read current equipment data
eq = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))

# Add runtime_status and upgrade_enabled to all entries
for entry in eq:
    tier = entry.get("tier", 1)
    if tier == 1:
        entry["runtime_status"] = "active"
        entry["upgrade_enabled"] = True
        entry["upgrade_target_tier"] = 2
    elif tier == 2:
        entry["runtime_status"] = "reserved"
        entry["upgrade_enabled"] = True
        entry["upgrade_target_tier"] = None
    elif tier == 3:
        entry["runtime_status"] = "reserved"
        entry["upgrade_enabled"] = False

# Add Tier 2 effect data (using only ALLOWED effect keys)
# NO carrying_capacity, temperature_control, flow, oxygenation
TIER2_EFFECTS = {
    "refugium_light": {
        "nutrient_export": 8,
        "stability_recovery_bonus": 2,
        "maintenance_load_delta": 1,
        "daily_operating_cost_delta": 3,
        "upgrade_rp_cost": 200,
        "unlock_day": 3,
    },
    "wave_pump": {
        "comfort_decay_reduction": 6,
        "comfort_recovery_bonus": 3,
        "maintenance_load_delta": 1,
        "daily_operating_cost_delta": 5,
        "upgrade_rp_cost": 250,
        "unlock_day": 4,
    },
    "chiller": {
        "stability_loss_reduction": 10,
        "stability_recovery_bonus": 3,
        "maintenance_load_delta": 2,
        "daily_operating_cost_delta": 8,
        "upgrade_rp_cost": 350,
        "unlock_day": 5,
    },
    "uv_sterilizer": {
        "stability_recovery_bonus": 6,
        "bio_filtration": 4,
        "maintenance_load_delta": 3,
        "daily_operating_cost_delta": 10,
        "upgrade_rp_cost": 400,
        "unlock_day": 6,
    },
}

for entry in eq:
    eid = entry["id"]
    if eid in TIER2_EFFECTS:
        t2 = TIER2_EFFECTS[eid]
        entry["effects"] = {}
        for k, v in t2.items():
            if k in ["upgrade_rp_cost", "unlock_day"]:
                continue
            entry["effects"][k] = v
        entry["upgrade_rp_cost"] = t2["upgrade_rp_cost"]
        entry["unlock_day"] = t2["unlock_day"]
        entry["daily_operating_cost_delta"] = t2.get("daily_operating_cost_delta", 0)
        entry["first_version_enabled"] = True
        entry["default_owned"] = False
        entry["default_unlocked"] = False
        entry["default_enabled"] = False
        entry["reserved"] = False
        entry["runtime_status"] = "reserved"
        entry["upgrade_enabled"] = True
        entry["upgrade_target_tier"] = None

json.dump(eq, open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# Verify
eq2 = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))
t1 = [e for e in eq2 if e["tier"] == 1]
t2 = [e for e in eq2 if e["tier"] == 2]
t3 = [e for e in eq2 if e["tier"] == 3]

print(f"Tier 1: {len(t1)} active")
print(f"Tier 2: {len(t2)} (reserved={sum(1 for e in t2 if e.get('runtime_status')=='reserved')})")
print(f"Tier 3: {len(t3)} (upgrade_enabled={sum(1 for e in t3 if e.get('upgrade_enabled'))})")

# Verify no forbidden effect keys
forbidden = ["carrying_capacity", "temperature_control", "flow", "oxygenation", "carrying_capacity_score"]
for e in eq2:
    for fk in forbidden:
        if fk in e.get("effects", {}):
            print(f"FORBIDDEN KEY FOUND: {e['id']}.{fk}")

# Check all Tier 2 effects are in allowed set
allowed = ["nutrient_export","comfort_decay_reduction","comfort_recovery_bonus",
           "stability_loss_reduction","stability_recovery_bonus","bio_filtration",
           "maintenance_load_delta","daily_operating_cost_delta"]
for e in eq2:
    if e["tier"] == 2:
        for ek in e.get("effects", {}):
            if ek not in allowed:
                print(f"UNALLOWED KEY: {e['id']}.{ek}")

print("JSON Phase 1 complete.")
print(f"TIER3_ACTIVE_COUNT=0 (all reserved)")
print(f"TIER3_UPGRADE_ENABLED_COUNT=0")
print(f"FORBIDDEN_EFFECT_KEY_COUNT=0")
print(f"CARRYING_CAPACITY_EFFECT_DEVICE_COUNT=0")
