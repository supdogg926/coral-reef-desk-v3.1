M11 Acceptance Screenshots (headless)
=====================================
Generated: 2026-06-26 02:08:08
Git HEAD: 5f66129d7c3e9e8b0cd51afa09d085358b42ea13
Result: PASS

Note: In headless mode, actual screenshots require a GPU/renderer.
The UI layout verification script (m11_ui_layout_verify.gd) validates:
- All key Control nodes are within viewport bounds
- No unicode escape residue in labels
- No empty button texts
- ShopPanel/LivestockPanel hidden by default
- Timeline entries have correct format

For visual screenshots, run the project in the Godot editor
and capture the following views manually:
1. main_default.png  - Default view with bottom dock visible
2. shop_open.png     - Shop panel open
3. after_purchase.png - After a purchase, showing timeline entry
4. after_release.png  - After a release, showing timeline entry
5. after_reset.png    - After reset, showing default state
