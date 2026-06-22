# Equipment Tiers And Placement

M4 uses an equipment warehouse plus fixed sump slot model. Plumbing is static visual infrastructure only and is not gameplay in the first playable version.

## Core Rule

System effects come from installed equipment in valid fixed slots. Pipe routing, pipe connection, pipe efficiency, and manual side-loop plumbing are out of scope.

## Replace These Concepts

- Auto main plumbing route.
- Future manual side-loop plumbing.
- Free pipe connection.
- Pipe efficiency calculation.

## Use These Concepts

- Implicit fixed plumbing.
- Equipment warehouse.
- Slot-based placement.
- Sump template upgrade.
- Install and remove equipment.
- Legal placement zone.
- Fixed equipment footprint.

## Gameplay Model

1. Equipment starts in a storage state: `installed`, `warehouse`, or `locked`.
2. Tier 1 equipment starts installed in the starter sump/display template.
3. Tier 2 and Tier 3 equipment remains locked or reserved and may appear later as warehouse preview items.
4. Installing equipment into a valid slot automatically connects it to the system through implicit plumbing.
5. Removing equipment returns it to the warehouse and removes its system effects.
6. Future sump/cabinet templates may unlock more slots, but M4 does not implement arbitrary resizing.

## M4 Equipment States

- Tier 1: installed, installable, removable, installed_effective.
- Tier 2: locked preview, not effective.
- Tier 3: locked preview, not effective.

## Starter Template

The starter template is `starter_berlin_sump_v1`. It exposes fixed slots for mechanical filtration, skimmer, refugium, return, display rock, and shared utility equipment.
