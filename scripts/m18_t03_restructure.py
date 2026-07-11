"""M18-T3: Restructure equipment JSON to support per-tier definitions within each record."""
import json

ROOT = "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M18_T03"
data = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))

# Tier 3 specialization definitions
TIER3_SPECS = {
    "refugium_light": {
        "effects": {"nutrient_export": 14, "stability_recovery_bonus": 4, "maintenance_load_delta": 3},
        "upgrade_rp_cost": 500, "unlock_day": 18, "daily_operating_cost_delta": 8,
        "specialization": {"trigger_id": "nutrient_surge_mode", "trigger_event_ids": ["nutrient_surge"],
            "trigger_phases": ["WARNING","ACTIVE"], "max_triggers_per_event": 1, "cooldown_days": 3,
            "additional_operating_cost_when_active": 5,
            "description": "高营养盐强化导出：营养盐上升期间 nutrient_export 提升80%，额外降低严重度30%"},
    },
    "wave_pump": {
        "effects": {"comfort_decay_reduction": 10, "comfort_recovery_bonus": 6, "maintenance_load_delta": 2},
        "upgrade_rp_cost": 550, "unlock_day": 20, "daily_operating_cost_delta": 9,
        "specialization": {"trigger_id": "stress_recovery_pulse", "trigger_event_ids": ["livestock_stress"],
            "trigger_phases": ["WARNING","ACTIVE","RECOVERY"], "max_triggers_per_event": 2, "cooldown_days": 2,
            "additional_operating_cost_when_active": 4,
            "description": "应激恢复脉冲：生物应激期间舒适衰减降低60%，恢复速度提升50%"},
    },
    "chiller": {
        "effects": {"stability_loss_reduction": 16, "stability_recovery_bonus": 6, "maintenance_load_delta": 3},
        "upgrade_rp_cost": 650, "unlock_day": 22, "daily_operating_cost_delta": 12,
        "specialization": {"trigger_id": "emergency_stability_buffer", "trigger_event_ids": ["system_stress_spike"],
            "trigger_phases": ["ACTIVE"], "max_triggers_per_event": 1, "cooldown_days": 4,
            "additional_operating_cost_when_active": 8,
            "description": "紧急稳定缓冲：系统压力峰值期间稳定性损失降低65%，单事件限触发一次"},
    },
    "uv_sterilizer": {
        "effects": {"stability_recovery_bonus": 10, "bio_filtration": 7, "maintenance_load_delta": 4},
        "upgrade_rp_cost": 700, "unlock_day": 24, "daily_operating_cost_delta": 12,
        "specialization": {"trigger_id": "bloom_suppression", "trigger_event_ids": ["waterborne_bloom"],
            "trigger_phases": ["WARNING","ACTIVE"], "max_triggers_per_event": 1, "cooldown_days": 3,
            "additional_operating_cost_when_active": 6,
            "description": "浑浊抑制：水体浑浊事件初始严重度降低40%，改善恢复评级"},
    },
}

for entry in data:
    eid = entry["id"]
    if eid in TIER3_SPECS:
        # Move current (Tier 2) definition into tier_definitions[2]
        tier2_def = {
            "effects": entry.get("effects", {}).copy(),
            "upgrade_rp_cost": entry.get("upgrade_rp_cost", 0),
            "unlock_day": entry.get("unlock_day", 1),
            "daily_operating_cost_delta": entry.get("daily_operating_cost_delta", 0),
            "maintenance_pressure_delta": entry.get("maintenance_pressure_delta", 0),
            "runtime_status": "reserved",
            "upgrade_enabled": True,
        }
        # Tier 3 definition
        t3 = TIER3_SPECS[eid]
        tier3_def = {
            "effects": t3["effects"],
            "upgrade_rp_cost": t3["upgrade_rp_cost"],
            "unlock_day": t3["unlock_day"],
            "daily_operating_cost_delta": t3["daily_operating_cost_delta"],
            "maintenance_pressure_delta": 1,
            "runtime_status": "active",
            "upgrade_enabled": True,
            "specialization": t3["specialization"],
        }
        entry["tier_definitions"] = {2: tier2_def, 3: tier3_def}
        entry["runtime_status"] = "reserved"
        entry["upgrade_enabled"] = True
        print(f"  Restructured: {eid} with tier_definitions[2] and [3]")

# Also add Tier 1 as tier_definitions[1] for consistency
for entry in data:
    if entry.get("tier") == 1 and entry.get("runtime_status") == "active":
        entry["tier_definitions"] = {
            1: {
                "effects": entry.get("effects", {}).copy(),
                "runtime_status": "active",
                "upgrade_enabled": False,
            }
        }

json.dump(data, open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# Verify
data2 = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))
t3_active = 0
for e in data2:
    tdefs = e.get("tier_definitions", {})
    if 3 in tdefs and tdefs[3].get("runtime_status") == "active":
        t3_active += 1
        spec = tdefs[3].get("specialization", {})
        print(f"  Tier 3: {e['id']} cost={tdefs[3]['upgrade_rp_cost']} trigger={spec.get('trigger_id','?')}")
print(f"TIER3_ACTIVE_COUNT={t3_active}")
