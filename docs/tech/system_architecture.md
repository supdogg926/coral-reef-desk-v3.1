# System Architecture

ReefIdle V3 uses small systems with clear responsibilities. Data remains in JSON files under `data/`, and runtime systems should consume DataRegistry rather than hardcoding gameplay tables.

## System List

### GameState

Owns current run state, current milestone, player resources, unlocked tiers, and references to system-level state. It should remain serializable for SaveSystem.

### TimeSystem

Owns active and offline time advancement. It should expose deterministic tick steps so economy, livestock, equipment, and water chemistry can be tested.

### EconomySystem

Owns reef points, costs, idle gain, and spending validation. It should not own livestock or equipment behavior directly.

### EquipmentSystem

Owns equipment inventory, installed equipment, tier metadata, and equipment effects. It reads equipment data through DataRegistry.

### EquipmentPlacementSystem

Owns placement slots and validates whether equipment can be placed in display tank, sump, cabinet, or utility areas. It should support future drag/drop UI without depending on UI nodes.

### WaterChemistrySystem

Owns water chemistry state such as temperature, salinity, nutrients, alkalinity, calcium, pH, and overall stability. M3 only defines the scaffold; full simulation belongs to later tasks.

### LivestockSystem

Owns livestock inventory, active livestock, carrying capacity usage, observation value, and biological load. It should depend on system stability but not mutate equipment directly.

### UnlockSystem

Owns tier unlocks, equipment unlocks, livestock unlocks, and progression gates. It uses reef points and milestones as inputs.

### SaveSystem

Owns serialization and restore boundaries. It should save GameState-compatible data only and avoid saving scene node references.

### UISystem

Owns presentation state and bridges runtime systems to Godot UI. It must follow the North Star UI reference and should not contain core simulation rules.

## Dependency Direction

- DataRegistry -> read-only data source.
- GameState -> central runtime state container.
- Systems -> operate on GameState and DataRegistry data.
- UI -> reads system state and sends player intent.
- SaveSystem -> serializes GameState-compatible data.

## M3 Scope

This milestone creates architecture documentation and minimal script scaffolds only. It does not implement full water chemistry, equipment placement gameplay, saving, or economy balancing.
