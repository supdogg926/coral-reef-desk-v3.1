# Godot Crash Triage Report

Generated: 06/23/2026 17:47:31
Note: this complete report captures pipeline output that the original ad-hoc script printed to console.

## Git State
```
C:/Users/admin/Desktop/桌面海缸v3.0/CoralReefIdleV3
prototype/m11-biomanage-vertical-slice
 M scenes/ui/LivestockPanel.gd
 M scripts/systems/GameState.gd
 M scripts/systems/LivestockSystem.gd
?? reports/godot_crash_triage_20260623_174619.md
?? reports/godot_crash_triage_complete_20260623_174731.md
?? reports/m11_prototype_acceptance_checklist.md
?? reports/m11_prototype_implementation_report.md
767c39b docs: add M11 planning baseline
c71bb8f docs: archive M10 release documentation
1a4c334 chore: finalize M10 livestock core regression baseline
22d94a6 fix: M10.12 replace typed array assignment with manual String cast in SaveSystem
5826fd3 fix: M10.11 autosave interval 60s, re-entry guard, per-step logging, manual save button
v3.1-m10-livestock-core
```

## Recent Windows Application Errors Related to Godot
```
No matching Application events found in the last 6 hours.
```

## Recent System Errors
```
No System Error/Critical events found in the last 6 hours.
```

## Godot User Data / Crash Folder Candidates
```
FOUND: C:\Users\admin\AppData\Roaming\Godot

FullName                                                                                                                                                                                                             LastWriteTime       Length
--------                                                                                                                                                                                                             -------------       ------
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\reef_idle_v3_save.json                                                                                                                             2026/6/23 17:47:18    3633
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot.log                                                                                                                                     2026/6/23 17:43:07      71
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs                                                                                                                                               2026/6/23 17:43:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.43.07.log                                                                                                                  2026/6/23 17:43:07   82307
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.42.51.log                                                                                                                  2026/6/23 17:42:51   81955
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.08.17.log                                                                                                                  2026/6/23 17:08:17  642511
C:\Users\admin\AppData\Roaming\Godot\editor_settings-4.7.tres                                                                                                                                                        2026/6/23 17:08:13   17762
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T15.44.50.log                                                                                                                  2026/6/23 15:44:50  435572
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3                                                                                                                                                    2026/6/23 15:44:49
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\save.json                                                                                                                                            2026/6/23 0:19:10   289555
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot.log                                                                                                                                       2026/6/23 0:18:55     1258
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs                                                                                                                                                 2026/6/23 0:18:09
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot2026-06-23T00.18.09.log                                                                                                                    2026/6/23 0:18:09  1274666
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle                                                                                                                                                      2026/6/23 0:18:08
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot.log                                                                                                                                     2026/6/23 0:17:56     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs                                                                                                                                               2026/6/23 0:17:55
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot2026-06-23T00.17.55.log                                                                                                                  2026/6/23 0:17:55     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank                                                                                                                                                    2026/6/23 0:17:54
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan                                                                                                                                             2026/6/22 22:13:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.editor.cache                                                                              2026/6/22 22:13:07 5598341
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca\8305c75c1294a9f00656f0f14344bb8bedcfe4e7.vulkan.cache     2026/6/22 21:04:14   30500
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca                                                           2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3\c2f7efc3419efdd79fabd056897820a83f2ac2c9.vulkan.cache 2026/6/22 21:04:14   41284
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3                                                       2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.cache                                                                                     2026/6/22 18:01:48 3153675
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD\60730ff5d181828d793048b679aedf660ec932db990c939f300e8875dc43b3cf                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD                                                                                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache                                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD\cfd5775dd543f5734172100a77ad23587b240dead09ab7049fc1180f7b408828                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD                                                                                                                    2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD\9cc3728a0cf1dd7347aee49fe0cbe3009047f904f8dfbbe122c3ae35395cd1a6                                                   2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD\0ab6c7454d17aead7529b239657e8420143918f7e497a25a206e1bd0dd65ee07                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD                                                                                                                           2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD\eb9c653c5c11c28b3c78b4b6d2fb70ca4f70e114fea55281aaa38a313893ac6c                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD\28d6881ae8e064e7bb573261202e530fa9cd61edce48d444d046e61ab449ac36                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD                                                                                                                  2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD\e920add2247a504ee41de41046b3e7179eb4952232110cb2db89172c537039b8                                        2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD                                                                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD                                                                                                             2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD\87693d8136d46b4b64459dbec139c5405b1cabacb2c3894415b131e8782efb2a                                            2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD\9f184666cb5c22b85364514685d89dda5bb3f1b85537ad6d60d04e41af01af01                                              2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD                                                                                                               2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD\50b078842febfa35329120080e7954028fe9c0f19ee8582e6d69667cc29f6f8c                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD\ac0cd9c7a7b5adc08e5e0770aac36764b5ca298a1a412b5d5256e978ac014583                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD\2ac072fb5419de33ce27c9014825f16cc6d4060426f4ba73059bc68094b6bfa8                                                2026/6/22 18:00:21



FOUND: C:\Users\admin\AppData\Roaming\Godot\app_userdata

FullName                                                                                                                                                                                                             LastWriteTime       Length
--------                                                                                                                                                                                                             -------------       ------
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\reef_idle_v3_save.json                                                                                                                             2026/6/23 17:47:18    3633
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot.log                                                                                                                                     2026/6/23 17:43:07      71
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs                                                                                                                                               2026/6/23 17:43:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.43.07.log                                                                                                                  2026/6/23 17:43:07   82307
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.42.51.log                                                                                                                  2026/6/23 17:42:51   81955
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.08.17.log                                                                                                                  2026/6/23 17:08:17  642511
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T15.44.50.log                                                                                                                  2026/6/23 15:44:50  435572
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3                                                                                                                                                    2026/6/23 15:44:49
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\save.json                                                                                                                                            2026/6/23 0:19:10   289555
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot.log                                                                                                                                       2026/6/23 0:18:55     1258
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot2026-06-23T00.18.09.log                                                                                                                    2026/6/23 0:18:09  1274666
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs                                                                                                                                                 2026/6/23 0:18:09
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle                                                                                                                                                      2026/6/23 0:18:08
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot.log                                                                                                                                     2026/6/23 0:17:56     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs                                                                                                                                               2026/6/23 0:17:55
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot2026-06-23T00.17.55.log                                                                                                                  2026/6/23 0:17:55     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank                                                                                                                                                    2026/6/23 0:17:54
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan                                                                                                                                             2026/6/22 22:13:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.editor.cache                                                                              2026/6/22 22:13:07 5598341
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca\8305c75c1294a9f00656f0f14344bb8bedcfe4e7.vulkan.cache     2026/6/22 21:04:14   30500
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca                                                           2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3\c2f7efc3419efdd79fabd056897820a83f2ac2c9.vulkan.cache 2026/6/22 21:04:14   41284
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3                                                       2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.cache                                                                                     2026/6/22 18:01:48 3153675
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD\60730ff5d181828d793048b679aedf660ec932db990c939f300e8875dc43b3cf                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache                                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD                                                                                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD\cfd5775dd543f5734172100a77ad23587b240dead09ab7049fc1180f7b408828                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD\9cc3728a0cf1dd7347aee49fe0cbe3009047f904f8dfbbe122c3ae35395cd1a6                                                   2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD                                                                                                                    2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD\0ab6c7454d17aead7529b239657e8420143918f7e497a25a206e1bd0dd65ee07                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD                                                                                                                           2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD\eb9c653c5c11c28b3c78b4b6d2fb70ca4f70e114fea55281aaa38a313893ac6c                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD\28d6881ae8e064e7bb573261202e530fa9cd61edce48d444d046e61ab449ac36                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD                                                                                                                  2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD                                                                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD\e920add2247a504ee41de41046b3e7179eb4952232110cb2db89172c537039b8                                        2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD                                                                                                             2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD\87693d8136d46b4b64459dbec139c5405b1cabacb2c3894415b131e8782efb2a                                            2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD\9f184666cb5c22b85364514685d89dda5bb3f1b85537ad6d60d04e41af01af01                                              2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD                                                                                                               2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD\50b078842febfa35329120080e7954028fe9c0f19ee8582e6d69667cc29f6f8c                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD\ac0cd9c7a7b5adc08e5e0770aac36764b5ca298a1a412b5d5256e978ac014583                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD\2ac072fb5419de33ce27c9014825f16cc6d4060426f4ba73059bc68094b6bfa8                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\OctmapRoughnessShaderRD                                                                                                               2026/6/22 18:00:21



FOUND: C:\Users\admin\AppData\Local\Godot

FullName                                                                               LastWriteTime      Length
--------                                                                               -------------      ------
C:\Users\admin\AppData\Local\Godot\resthumb-ebe32bb51362e2798c0383785cd0df20.txt       2026/6/23 12:40:36     54
C:\Users\admin\AppData\Local\Godot\resthumb-ebe32bb51362e2798c0383785cd0df20.png       2026/6/23 12:40:36    759
C:\Users\admin\AppData\Local\Godot\resthumb-9e31528c399f0d3c88a82eeb23c6ad68.txt       2026/6/23 12:40:36     54
C:\Users\admin\AppData\Local\Godot\resthumb-9e31528c399f0d3c88a82eeb23c6ad68.png       2026/6/23 12:40:36    729
C:\Users\admin\AppData\Local\Godot\resthumb-a7f12c9471703953b0007c9f59123e20.txt       2026/6/23 12:40:36     54
C:\Users\admin\AppData\Local\Godot\resthumb-a7f12c9471703953b0007c9f59123e20.png       2026/6/23 12:40:36    742
C:\Users\admin\AppData\Local\Godot\resthumb-5042a1b87ceeff37e0b387dd8ab0ad96.txt       2026/6/23 2:19:33      54
C:\Users\admin\AppData\Local\Godot\resthumb-5042a1b87ceeff37e0b387dd8ab0ad96.png       2026/6/23 2:19:33     689
C:\Users\admin\AppData\Local\Godot\resthumb-750818456d5a5c3b55de610833d27822.txt       2026/6/23 2:07:32      54
C:\Users\admin\AppData\Local\Godot\resthumb-750818456d5a5c3b55de610833d27822.png       2026/6/23 2:07:32     812
C:\Users\admin\AppData\Local\Godot\resthumb-e9bdbe7a932d7eb4151b4b3793d7ab5e.txt       2026/6/23 1:51:51      54
C:\Users\admin\AppData\Local\Godot\resthumb-e9bdbe7a932d7eb4151b4b3793d7ab5e.png       2026/6/23 1:51:51     751
C:\Users\admin\AppData\Local\Godot\resthumb-55ff92168beb0005dd0667c398a5d8aa.txt       2026/6/23 1:24:41      54
C:\Users\admin\AppData\Local\Godot\resthumb-55ff92168beb0005dd0667c398a5d8aa.png       2026/6/23 1:24:41     779
C:\Users\admin\AppData\Local\Godot\resthumb-e8cc9af425b5b60f1b107c8bd54a245e.txt       2026/6/23 0:17:27      54
C:\Users\admin\AppData\Local\Godot\resthumb-e8cc9af425b5b60f1b107c8bd54a245e.png       2026/6/23 0:17:27     670
C:\Users\admin\AppData\Local\Godot\resthumb-bf1b2218fcdcf542ed770c2aa7a665a4.txt       2026/6/23 0:17:27      54
C:\Users\admin\AppData\Local\Godot\resthumb-bf1b2218fcdcf542ed770c2aa7a665a4.png       2026/6/23 0:17:27     743
C:\Users\admin\AppData\Local\Godot\resthumb-fa3c09bdb7d0a0e6ca79b50bd37b5e06.txt       2026/6/23 0:17:27      54
C:\Users\admin\AppData\Local\Godot\resthumb-fa3c09bdb7d0a0e6ca79b50bd37b5e06.png       2026/6/23 0:17:27     726
C:\Users\admin\AppData\Local\Godot\resthumb-f9468d542efbb6b1f95215cd67794296.txt       2026/6/23 0:17:27      54
C:\Users\admin\AppData\Local\Godot\resthumb-f9468d542efbb6b1f95215cd67794296.png       2026/6/23 0:17:27     708
C:\Users\admin\AppData\Local\Godot\resthumb-a0339ce950cd3bd3f6ebd78fd072bc13.txt       2026/6/22 22:37:03     54
C:\Users\admin\AppData\Local\Godot\resthumb-a0339ce950cd3bd3f6ebd78fd072bc13.png       2026/6/22 22:37:03    696
C:\Users\admin\AppData\Local\Godot\resthumb-c94e8d79c85181e33ee2ebca9a69c451.txt       2026/6/22 22:28:42     54
C:\Users\admin\AppData\Local\Godot\resthumb-c94e8d79c85181e33ee2ebca9a69c451.png       2026/6/22 22:28:42    831
C:\Users\admin\AppData\Local\Godot\resthumb-a6ee421617d82f65695fce1956c829b7.txt       2026/6/22 21:59:39     54
C:\Users\admin\AppData\Local\Godot\resthumb-a6ee421617d82f65695fce1956c829b7.png       2026/6/22 21:59:39    736
C:\Users\admin\AppData\Local\Godot\resthumb-bda27f1bb5c6543a82a151efc0ea7ec9.txt       2026/6/22 21:24:08     54
C:\Users\admin\AppData\Local\Godot\resthumb-bda27f1bb5c6543a82a151efc0ea7ec9.png       2026/6/22 21:24:08    692
C:\Users\admin\AppData\Local\Godot\resthumb-88de34b3191a114fe9ccc2968e12eba5.txt       2026/6/22 21:03:43     54
C:\Users\admin\AppData\Local\Godot\resthumb-88de34b3191a114fe9ccc2968e12eba5.png       2026/6/22 21:03:43    701
C:\Users\admin\AppData\Local\Godot\resthumb-9abe5e962f31124ce629305b65643f3d.txt       2026/6/22 18:07:39     54
C:\Users\admin\AppData\Local\Godot\resthumb-9abe5e962f31124ce629305b65643f3d.png       2026/6/22 18:07:39    818
C:\Users\admin\AppData\Local\Godot\resthumb-03d3df1ab2736da614f01fcdbab993a3.txt       2026/6/22 18:07:39     54
C:\Users\admin\AppData\Local\Godot\resthumb-03d3df1ab2736da614f01fcdbab993a3.png       2026/6/22 18:07:39    722
C:\Users\admin\AppData\Local\Godot\resthumb-6ec42634cf2a14d76b35a682ff8128d2.txt       2026/6/22 14:01:04     54
C:\Users\admin\AppData\Local\Godot\resthumb-6ec42634cf2a14d76b35a682ff8128d2.png       2026/6/22 14:01:04    757
C:\Users\admin\AppData\Local\Godot\resthumb-dbfcee1a110ef332c168d1c35c2a0357.txt       2026/6/22 14:01:04     90
C:\Users\admin\AppData\Local\Godot\resthumb-dbfcee1a110ef332c168d1c35c2a0357_small.png 2026/6/22 14:01:04    361
C:\Users\admin\AppData\Local\Godot\resthumb-dbfcee1a110ef332c168d1c35c2a0357.png       2026/6/22 14:01:04   1269
C:\Users\admin\AppData\Local\Godot\resthumb-94513c62af29427466452dcb47dfea29.txt       2026/6/22 13:45:17     90
C:\Users\admin\AppData\Local\Godot\resthumb-94513c62af29427466452dcb47dfea29_small.png 2026/6/22 13:45:17    417
C:\Users\admin\AppData\Local\Godot\resthumb-94513c62af29427466452dcb47dfea29.png       2026/6/22 13:45:17   1553
C:\Users\admin\AppData\Local\Godot\resthumb-77635414fd47549d9b78ea8ef3b8578a.txt       2026/6/22 13:36:57     90
C:\Users\admin\AppData\Local\Godot\resthumb-77635414fd47549d9b78ea8ef3b8578a.png       2026/6/22 13:36:57   2680
C:\Users\admin\AppData\Local\Godot\resthumb-77635414fd47549d9b78ea8ef3b8578a_small.png 2026/6/22 13:36:57    479
C:\Users\admin\AppData\Local\Godot\resthumb-950ac1b82f676cf90986203c8e5644bb.txt       2026/6/22 13:36:57     90
C:\Users\admin\AppData\Local\Godot\resthumb-950ac1b82f676cf90986203c8e5644bb_small.png 2026/6/22 13:36:57    476
C:\Users\admin\AppData\Local\Godot\resthumb-950ac1b82f676cf90986203c8e5644bb.png       2026/6/22 13:36:57   2724



FOUND: C:\Users\admin\AppData\Roaming\Godot

FullName                                                                                                                                                                                                             LastWriteTime       Length
--------                                                                                                                                                                                                             -------------       ------
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\reef_idle_v3_save.json                                                                                                                             2026/6/23 17:47:18    3633
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot.log                                                                                                                                     2026/6/23 17:43:07      71
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs                                                                                                                                               2026/6/23 17:43:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.43.07.log                                                                                                                  2026/6/23 17:43:07   82307
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.42.51.log                                                                                                                  2026/6/23 17:42:51   81955
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T17.08.17.log                                                                                                                  2026/6/23 17:08:17  642511
C:\Users\admin\AppData\Roaming\Godot\editor_settings-4.7.tres                                                                                                                                                        2026/6/23 17:08:13   17762
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\logs\godot2026-06-23T15.44.50.log                                                                                                                  2026/6/23 15:44:50  435572
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3                                                                                                                                                    2026/6/23 15:44:49
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\save.json                                                                                                                                            2026/6/23 0:19:10   289555
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot.log                                                                                                                                       2026/6/23 0:18:55     1258
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs                                                                                                                                                 2026/6/23 0:18:09
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle\logs\godot2026-06-23T00.18.09.log                                                                                                                    2026/6/23 0:18:09  1274666
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdle                                                                                                                                                      2026/6/23 0:18:08
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot.log                                                                                                                                     2026/6/23 0:17:56     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs                                                                                                                                               2026/6/23 0:17:55
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank\logs\godot2026-06-23T00.17.55.log                                                                                                                  2026/6/23 0:17:55     1705
C:\Users\admin\AppData\Roaming\Godot\app_userdata\DesktopReefTank                                                                                                                                                    2026/6/23 0:17:54
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan                                                                                                                                             2026/6/22 22:13:07
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.editor.cache                                                                              2026/6/22 22:13:07 5598341
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca\8305c75c1294a9f00656f0f14344bb8bedcfe4e7.vulkan.cache     2026/6/22 21:04:14   30500
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\GiShaderRD\d0db97061545374c4aad77fca934cb9bd70afea09ec5692aab7313678fd68fca                                                           2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3\c2f7efc3419efdd79fabd056897820a83f2ac2c9.vulkan.cache 2026/6/22 21:04:14   41284
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\CanvasShaderRD\9bdc1125c86af67021aafde8760184618f2961034b221ad5dbe673034858b1f3                                                       2026/6/22 21:04:14
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\vulkan\pipelines.forward_plus.nvidia_geforce_rtx_5060_ti.cache                                                                                     2026/6/22 18:01:48 3153675
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD\60730ff5d181828d793048b679aedf660ec932db990c939f300e8875dc43b3cf                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\BlitShaderRD                                                                                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache                                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ResolveShaderRD\cfd5775dd543f5734172100a77ad23587b240dead09ab7049fc1180f7b408828                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD                                                                                                                    2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\FsrUpscaleShaderRD\9cc3728a0cf1dd7347aee49fe0cbe3009047f904f8dfbbe122c3ae35395cd1a6                                                   2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD\0ab6c7454d17aead7529b239657e8420143918f7e497a25a206e1bd0dd65ee07                                                          2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\VrsShaderRD                                                                                                                           2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD\eb9c653c5c11c28b3c78b4b6d2fb70ca4f70e114fea55281aaa38a313893ac6c                                                      2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\TonemapShaderRD                                                                                                                       2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD\28d6881ae8e064e7bb573261202e530fa9cd61edce48d444d046e61ab449ac36                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaBlendingShaderRD                                                                                                                  2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD\e920add2247a504ee41de41046b3e7179eb4952232110cb2db89172c537039b8                                        2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaWeightCalculationShaderRD                                                                                                         2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD                                                                                                             2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SmaaEdgeDetectionShaderRD\87693d8136d46b4b64459dbec139c5405b1cabacb2c3894415b131e8782efb2a                                            2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD\9f184666cb5c22b85364514685d89dda5bb3f1b85537ad6d60d04e41af01af01                                              2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\LuminanceReduceShaderRD                                                                                                               2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\MotionVectorsShaderRD\50b078842febfa35329120080e7954028fe9c0f19ee8582e6d69667cc29f6f8c                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\ShadowFrustumShaderRD\ac0cd9c7a7b5adc08e5e0770aac36764b5ca298a1a412b5d5256e978ac014583                                                2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD                                                                                                                 2026/6/22 18:00:21
C:\Users\admin\AppData\Roaming\Godot\app_userdata\CoralReefIdleV3\shader_cache\SpecularMergeShaderRD\2ac072fb5419de33ce27c9014825f16cc6d4060426f4ba73059bc68094b6bfa8                                                2026/6/22 18:00:21



```

## Initial Assessment
- Godot application-level crash was reported by Windows during restricted execution.
- Elevated Godot headless runs completed afterward, so sandbox/log-path permissions remain a likely factor.
- Treat as BLOCKED for new prototype development until crash source is identified.
- Do not commit, push, tag, or continue M11 development based only on this run.
- M10 release tag remains safe and unaffected.
