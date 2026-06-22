# Equipment Placement Architecture

M4 implements placement as data, not as free drag/drop or plumbing simulation.

## Architecture Direction

- EquipmentSystem owns equipment records and storage state.
- EquipmentPlacementSystem owns fixed slots, legal zones, and install/remove operations.
- GameState computes debug scores from installed effective equipment.
- Pipe visuals remain part of UI only and do not affect rules.

## Data Fields

Equipment records include:

- `storage_state`: installed, warehouse, or locked.
- `slot_id`: current slot if installed, otherwise empty.
- `slot_type`: expected slot family.
- `footprint_size`: fixed footprint label such as small, medium, large, or rock_stack.
- `legal_zone_ids`: allowed placement zones.
- `installed_effective`: true only when installed and connected through implicit plumbing.
- `pipe_connection_required`: false for M4.
- `implicit_plumbing`: true for M4.
- `installable`: true for equipment that can be moved into a slot.
- `removable`: true for equipment that can be returned to warehouse.
- `sump_template_id`: template used by the fixed slot layout.

Placement zone records include:

- `sump_template_id`.
- `zone_id` or `id`.
- `slot_type`.
- `slot_ids`.
- `allowed_equipment`.
- `reserved`.
- `implicit_plumbing`.

## Install Flow

1. Check equipment exists.
2. Check equipment is installable and not locked.
3. Check target slot exists in the active sump template.
4. Check the slot zone is legal for the equipment.
5. Set `storage_state` to installed, assign `slot_id`, and set `installed_effective` to true.

## Remove Flow

1. Check equipment exists.
2. Check equipment is removable.
3. Clear `slot_id`.
4. Set `storage_state` to warehouse.
5. Set `installed_effective` to false.

## Explicit Non-Goals

- No pipe node graph.
- No route solver.
- No manual pipe connection minigame.
- No pipe efficiency score.
- No arbitrary sump resizing.
