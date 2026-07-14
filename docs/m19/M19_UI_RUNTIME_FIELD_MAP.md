# M19 UI Runtime Field Map

## 01 — Main Page (M19MainInterfaceHybrid)

### System Info (Sidebar)
| Field | Old Display | New Node Path | Data Source | Type | Refresh | Format | Empty State |
|-------|-----------|---------------|-------------|------|---------|--------|-------------|
| project_title | ReefIdle V3 | M19MainUI/_sidebar_labels[project_title] | static | String | never | — | — |
| project_subtitle | M19 Blue Guardian | M19MainUI/_sidebar_labels[project_subtitle] | static | String | never | — | — |
| wave_balance | 浪花 76638 | M19MainUI/_sidebar_labels[wave_balance] | economy_system.get_waves_balance() | float | 1s | "浪花 %.0f" | "浪花 0" |
| temperature | 26.2 C | M19MainUI/_sidebar_labels[temperature] | water_chemistry_debug.temperature | float | 1s | "%.1f °C" | "--.- °C" |
| salinity | — | M19MainUI/_sidebar_labels[salinity_label] | water_chemistry_debug.salinity | float | 1s | "%.1f ppt" | "--.- ppt" |
| time_display | 13:49 | M19MainUI/_sidebar_labels[time_display] | Time.get_datetime_dict_from_system() | dict | 1s | "%02d:%02d" | "--:--" |
| date_display | 2026-07-14 | M19MainUI/_sidebar_labels[date_display] | Time.get_datetime_dict_from_system() | dict | 1s | "%d-%02d-%02d" | "----/--/--" |

### Water Parameters (Gauges)
| Field | Old Display | New Node Path | Data Source | Type | Unit | Decimals |
|-------|-----------|---------------|-------------|------|------|----------|
| 温度 | 25.0°C | _gauge_value_labels[0] | water.temperature | float | °C | 1 |
| 盐度 | 35.0ppt | _gauge_value_labels[1] | water.salinity | float | ppt | 1 |
| NO3 | 2.00 | _gauge_value_labels[2] | water.nitrate | float | — | 2 |
| PO4 | 0.030 | _gauge_value_labels[3] | water.phosphate | float | — | 3 |
| pH | 8.20 | _gauge_value_labels[4] | water.ph | float | — | 2 |
| KH | 8.3 | _gauge_value_labels[5] | water.alkalinity | float | — | 1 |
| Ca | 430 | _gauge_value_labels[6] | water.calcium | float | — | 0 |

### Knobs
| Field | Old Display | New Node Path | Device ID | Type | Value Display |
|-------|-----------|---------------|-----------|------|---------------|
| 水泵 | ON/OFF | _knob_value_labels[0] | return_pump | toggle | "ON"/"OFF" |
| 造浪泵 | ON/OFF | _knob_value_labels[1] | wave_pump | toggle | "ON"/"OFF" |
| 亮度 | 50% | _knob_value_labels[2] | main_light | intensity | "%d%%" |
| 色温 | 6500K | _knob_value_labels[3] | reserve | colortemp | "%dK" |

### Maintenance Buttons
| Button | Action ID | Signal | Disabled When |
|--------|-----------|--------|---------------|
| 换水 | water_change | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |
| 清滤 | filter_clean | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |
| KH | kh_buffer | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |
| 补水 | top_off | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |
| 清藻 | algae_clean | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |
| 更换滤材 | media_replace | _on_maintenance_pressed | cooldown > 0 or insufficient_funds |

### Feeding Buttons
| Button | Feed ID | Signal | Disabled When |
|--------|---------|--------|---------------|
| 喂鱼粮 | fish_food | _on_feeding_pressed | cooldown > 0 |
| 喂珊瑚粮 | coral_food | _on_feeding_pressed | cooldown > 0 |

### Device Buttons
| Button | Device ID | Signal | State Display |
|--------|-----------|--------|---------------|
| 蛋分 | skimmer | _on_device_pressed | ON/OFF color |
| 杀菌灯 | uv_sterilizer | _on_device_pressed | ON/OFF color |
| 加热棒 | heater | _on_device_pressed | ON/OFF color |
| 冷水机 | chiller | _on_device_pressed | ON/OFF color |
| 煮豆机 | biopellet | _on_device_pressed | ON/OFF color |
| 钙反 | ca_reactor | _on_device_pressed | ON/OFF color |
| 卷纸机 | roller_mat | _on_device_pressed | ON/OFF color |
| KHA | kha | _on_device_pressed | ON/OFF color |

### Navigation Buttons
| Button | Node | Signal Target | Function |
|--------|------|---------------|----------|
| 保存 | _nav_buttons[save_button] | Main._manual_save_test | Manual save |
| 观赏 | _nav_buttons[observe_button] | Main._on_observe_pressed | Hide panels |
| 图鉴 | _nav_buttons[codex_button] | Main._open_catalog_view | Open codex |
| 放归 | _nav_buttons[release_button] | Main._open_release_management | Open release |
| 设置 | _nav_buttons[settings_button] | — | TBD |

## 02 — Blue Guardian Ready (M19BlueGuardianPanel)

| Field | Data Source | State |
|-------|-------------|-------|
| dock_display_name | service.get_dock_display_name() | READY |
| wave_balance | service.economy.get_waves_balance() | numeric |
| voyage_cost | BlueGuardianConfig.WAVE_COST | numeric |
| eta | BlueGuardianConfig.VOYAGE_DURATION_SECONDS | seconds |
| launch_btn | service.launch_voyage() | disabled if can't launch |
| launch_deny_reason | service.get_launch_deny_reason() | text |

## 03 — Voyaging (M19BlueGuardianPanel, voyaging state)

| Field | Data Source | State |
|-------|-------------|-------|
| countdown | service.get_remaining_seconds() | MM:SS |
| progress | progress_bar.value/max | 0-total |
| voyage_sequence | service.get_voyage_sequence() | ordinal |
| region_name | service.get_dock_display_name() | text |

## 04 — Result (M19ResultPanelHybrid)

| Field | Data Source | State |
|-------|-------------|-------|
| species_name | data.get("display_name", sid) | text |
| species_image | M19SharedTheme.load_species_texture(sid) | texture |
| badge | "首次发现"/"再次相遇" | text |
| discovery_type | badge_label.text | text |
| source_region | BlueGuardianConfig.get_species_region(sid) | text |
| ecology_category | BlueGuardianConfig.get_species_rarity_tier(sid) | text |
| rescue_record | data.get("description") | text |
| retention_effect | "留在海缸可获得持续收益" | static |
| release_reward | BlueGuardianConfig.get_release_pulse(sid) | float |
| keep_btn | service.keep_pending_result() | disabled if full |
| release_btn | service.release_pending_result() | enabled |

## 05 — Codex (M19CodexPanel)

| Field | Data Source | State |
|-------|-------------|-------|
| species_list | BlueGuardianConfig.get_active_species_pool() | list |
| discovered | service.get_collection_ids() | array |
| main_image | M19SharedTheme.load_species_texture(sid) | texture |
| species_name | display name or "？？？" | text |
| category | BlueGuardianConfig.get_species_rarity_tier(sid) | text |
| region | BlueGuardianConfig.get_species_region(sid) | text |
| description | registry description | text |
| release_count | rescue debug state | int |
| progress | discovered/total | "已发现 N/M" |

## 06 — Release (M19ReleasePanel)

| Field | Data Source | State |
|-------|-------------|-------|
| livestock_list | livestock_sys.get_debug_state().owned_livestock | list |
| species_name | entry.species_name | text |
| health | entry.health_percent | % |
| comfort | livestock debug comfort_score | float |
| income | entry.base_income_per_hour | float |
| reward | BlueGuardianConfig.get_release_pulse(species_id) | float |
| release_btn | livestock_sys.release_livestock(id) | disabled if not healthy |
| release_status | can_release / in_observation | text |
