# M19-D001

Main.gd _build_m19_main_ui() never executed in production. Scene tree audit showed 0 Hybrid instances, all legacy nodes at 100% visibility.

## Ruling
Only project.godot run/main_scene is production entry. Hybrid must be instantiated in production Main scene.
