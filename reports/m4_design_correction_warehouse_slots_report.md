# M4 Design Correction Warehouse Slots Report

Task: M4 Design Correction
Generated at: `2026-06-22T21:01:08`
V3 root: `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3`

## Decision Applied

- M4 does not build plumbing as gameplay.
- Pipes remain static and implicit visual infrastructure.
- Equipment effects come from installed effective equipment, not pipe routing or pipe connection complexity.
- The model is now equipment warehouse plus fixed sump/display slots.
- Starter sump template: `starter_berlin_sump_v1`.

## Replaced Concepts

- Removed direction: auto main plumbing route.
- Removed direction: future manual side-loop plumbing.
- Removed direction: free pipe connection.
- Removed direction: pipe efficiency calculation.
- Active direction: implicit fixed plumbing.
- Active direction: equipment warehouse.
- Active direction: slot-based placement.
- Active direction: sump template upgrade.
- Active direction: install/remove equipment.
- Active direction: legal placement zone.
- Active direction: fixed equipment footprint.

## Updated Files

- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\docs\game_design\equipment_tiers_and_placement.md`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\docs\tech\equipment_placement_architecture.md`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\equipment\equipment_tiers_seed.json`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\equipment\placement_zones_seed.json`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\data\schemas\equipment_placement_schema.json`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scripts\systems\EquipmentSystem.gd`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\scripts\systems\EquipmentPlacementSystem.gd`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\tools\check_tier1_equipment_system.py`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m4_tier1_equipment_check_summary.json`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m4_design_correction_warehouse_slots_report.md`
- `C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3\reports\m4_tier1_equipment_system_report.md`

## Equipment State Summary

- Tier 1 count: 7
- Tier 1 installed effective count: 7
- Warehouse count: 0
- Locked preview count: 9
- Tier 2 reserved count: 4
- Tier 3 reserved count: 5

## Tier 1 Installed Slots

- `filter_sock`: storage_state=installed slot_id=slot_mech_01 footprint_size=small legal_zone_ids=['mechanical_filtration_chamber']
- `protein_skimmer`: storage_state=installed slot_id=slot_skimmer_01 footprint_size=large_tall legal_zone_ids=['skimmer_chamber']
- `refugium`: storage_state=installed slot_id=slot_refugium_01 footprint_size=large_chamber legal_zone_ids=['refugium_chamber']
- `return_pump`: storage_state=installed slot_id=slot_return_01 footprint_size=medium legal_zone_ids=['return_chamber']
- `live_rock`: storage_state=installed slot_id=slot_display_rock_01 footprint_size=rock_stack legal_zone_ids=['display_tank', 'refugium_chamber']
- `filter_media`: storage_state=installed slot_id=slot_mech_media_01 footprint_size=small_basket legal_zone_ids=['mechanical_filtration_chamber', 'refugium_chamber']
- `heater`: storage_state=installed slot_id=slot_return_heater_01 footprint_size=slim_rod legal_zone_ids=['return_chamber', 'refugium_chamber']

## Placement Zones

- `display_tank`: template=starter_berlin_sump_v1 slot_type=display_biological slots=['slot_display_rock_01'] implicit_plumbing=True pipe_connection_required=False
- `mechanical_filtration_chamber`: template=starter_berlin_sump_v1 slot_type=mechanical_filtration slots=['slot_mech_01', 'slot_mech_media_01'] implicit_plumbing=True pipe_connection_required=False
- `skimmer_chamber`: template=starter_berlin_sump_v1 slot_type=skimmer slots=['slot_skimmer_01'] implicit_plumbing=True pipe_connection_required=False
- `refugium_chamber`: template=starter_berlin_sump_v1 slot_type=refugium slots=['slot_refugium_01'] implicit_plumbing=True pipe_connection_required=False
- `return_chamber`: template=starter_berlin_sump_v1 slot_type=return_pump slots=['slot_return_01', 'slot_return_heater_01'] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier2_utility`: template=future_tier2_sump_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier2_display`: template=future_tier2_display_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier3_controller`: template=future_tier3_controller_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier3_reactor`: template=future_tier3_reactor_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier3_mechanical`: template=future_tier3_mechanical_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False
- `reserved_tier3_utility`: template=future_tier3_utility_template slot_type=future_unlock_preview slots=[] implicit_plumbing=True pipe_connection_required=False

## Debug Scores From Installed Equipment

- stability_score: 92.0
- carrying_capacity_score: 27.0
- maintenance_load: 12.0

## Checks

- validate_data.py passed: True
- check_godot_skeleton.py passed: True
- check_tier1_equipment_system.py passed: True
- plumbing_gameplay: False
- implicit_plumbing: True
- pipe_connection_required: False

## Old Project

- Old project modified: No.

## Next Step Recommendation

Next task: M4.1 Equipment Slot UI Binding, or M5 Water Chemistry Minimal Simulation after slot state is reviewed in Godot.
