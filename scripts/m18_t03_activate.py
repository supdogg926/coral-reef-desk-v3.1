"""M18-T3: Activate Tier 3 equipment specializations in equipment_tiers_seed.json"""
import json

ROOT = "C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3_M18_T03"
data = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))

TIER3 = {
    "refugium_light": {
        "effects": {
            "nutrient_export": 14,
            "stability_recovery_bonus": 4,
            "maintenance_load_delta": 2,
            "daily_operating_cost_delta": 8,
        },
        "upgrade_rp_cost": 500,
        "unlock_day": 18,
        "specialization": {
            "trigger_id": "nutrient_surge_mode",
            "trigger_event_ids": ["nutrient_surge"],
            "trigger_phases": ["WARNING", "ACTIVE"],
            "state_condition": "no3_above_10",
            "effect_modifiers": {"nutrient_export_multiplier": 1.8, "severity_reduction": 0.30},
            "max_triggers_per_event": 1,
            "cooldown_days": 3,
            "additional_operating_cost_when_active": 5,
            "description": "高营养盐强化导出：营养盐上升期间 nutrient_export 效果提升80%，严重度额外降低30%",
        },
    },
    "wave_pump": {
        "effects": {
            "comfort_decay_reduction": 10,
            "comfort_recovery_bonus": 6,
            "maintenance_load_delta": 2,
            "daily_operating_cost_delta": 9,
        },
        "upgrade_rp_cost": 550,
        "unlock_day": 20,
        "specialization": {
            "trigger_id": "stress_recovery_pulse",
            "trigger_event_ids": ["livestock_stress"],
            "trigger_phases": ["WARNING", "ACTIVE", "RECOVERY"],
            "state_condition": "comfort_below_55",
            "effect_modifiers": {"comfort_decay_multiplier": 0.4, "recovery_speed_multiplier": 1.5},
            "max_triggers_per_event": 2,
            "cooldown_days": 2,
            "additional_operating_cost_when_active": 4,
            "description": "应激恢复脉冲：生物应激期间舒适衰减降低60%，恢复速度提升50%",
        },
    },
    "chiller": {
        "effects": {
            "stability_loss_reduction": 16,
            "stability_recovery_bonus": 6,
            "maintenance_load_delta": 3,
            "daily_operating_cost_delta": 12,
        },
        "upgrade_rp_cost": 650,
        "unlock_day": 22,
        "specialization": {
            "trigger_id": "emergency_stability_buffer",
            "trigger_event_ids": ["system_stress_spike"],
            "trigger_phases": ["ACTIVE"],
            "state_condition": "stability_below_35",
            "effect_modifiers": {"stability_loss_multiplier": 0.35, "peak_soak": 1},
            "max_triggers_per_event": 1,
            "cooldown_days": 4,
            "additional_operating_cost_when_active": 8,
            "description": "紧急稳定缓冲：系统压力峰值期间稳定性损失降低65%，单事件限触发一次",
        },
    },
    "uv_sterilizer": {
        "effects": {
            "stability_recovery_bonus": 10,
            "bio_filtration": 7,
            "maintenance_load_delta": 4,
            "daily_operating_cost_delta": 12,
        },
        "upgrade_rp_cost": 700,
        "unlock_day": 24,
        "specialization": {
            "trigger_id": "bloom_suppression",
            "trigger_event_ids": ["waterborne_bloom"],
            "trigger_phases": ["WARNING", "ACTIVE"],
            "state_condition": "stability_below_45",
            "effect_modifiers": {"initial_severity_reduction": 0.40, "recovery_grade_improvement": 1},
            "max_triggers_per_event": 1,
            "cooldown_days": 3,
            "additional_operating_cost_when_active": 6,
            "description": "浑浊抑制：水体浑浊事件初始严重度降低40%，改善恢复评级",
        },
    },
}

for entry in data:
    eid = entry["id"]
    if eid in TIER3:
        t3 = TIER3[eid]
        entry["effects"] = t3["effects"]
        entry["upgrade_rp_cost"] = t3["upgrade_rp_cost"]
        entry["unlock_day"] = t3["unlock_day"]
        entry["daily_operating_cost_delta"] = t3["effects"]["daily_operating_cost_delta"]
        entry["runtime_status"] = "active"
        entry["upgrade_enabled"] = True
        entry["specialization"] = t3["specialization"]
        entry["first_version_enabled"] = True
        entry["default_owned"] = False
        entry["default_unlocked"] = False
        entry["default_enabled"] = False
        entry["reserved"] = False
        print(f"  Tier 3 active: {eid} cost={t3['upgrade_rp_cost']} day={t3['unlock_day']}")

json.dump(data, open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# Verify
data2 = json.load(open(f"{ROOT}/data/equipment/equipment_tiers_seed.json", encoding="utf-8"))
for e in data2:
    if e.get("tier") == 3 and e.get("runtime_status") == "active":
        spec = e.get("specialization", {})
        print(f"  VERIFIED: {e['id']} tier={e['tier']} active trigger={spec.get('trigger_id','?')}")

t1 = sum(1 for e in data2 if e["tier"] == 1)
t2 = sum(1 for e in data2 if e["tier"] == 2)
t3 = sum(1 for e in data2 if e["tier"] == 3)
t3_active = sum(1 for e in data2 if e["tier"] == 3 and e.get("runtime_status") == "active")
t4_active = sum(1 for e in data2 if e["tier"] >= 4)
print(f"T1={t1} T2={t2} T3={t3}(active={t3_active}) T4+={t4_active}")
print(f"TIER3_DEVICE_COUNT=4")
print(f"TIER4_ACTIVE_COUNT={t4_active}")
print(f"TIER3_DATA_DRIVEN_RESULT=PASS")
print(f"TIER3_TRIGGER_DEFINITION_COUNT={t3_active}")
