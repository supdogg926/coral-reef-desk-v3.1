# M11 Prototype Acceptance Checklist

Date: 2026-06-23
Branch: `prototype/m11-biomanage-vertical-slice`
Scope: Fast prototype only. Not a formal M11 implementation.

## Manual Runtime Checklist

| # | Check | Expected Result | Result |
| --- | --- | --- | --- |
| 1 | Open the project on the prototype branch | Main scene loads without red Output / Debugger errors | TODO |
| 2 | Click `我的生物` | Owned livestock panel opens and the list renders | TODO |
| 3 | Click `选择` on one owned livestock row | Detail area shows name, rarity, capacity cost, income, and current status | TODO |
| 4 | Click `放归/移除` | A second confirmation panel appears | TODO |
| 5 | Click `取消` | No livestock count, capacity, income, or save state changes | TODO |
| 6 | Select a livestock again and click `放归/移除` | Confirmation panel appears again | TODO |
| 7 | Click `确认放归` | Selected livestock is removed from the owned list | TODO |
| 8 | Check livestock count | Count decreases by 1 | TODO |
| 9 | Check capacity display | Used capacity decreases by the released livestock capacity cost | TODO |
| 10 | Check income display | Base and effective income decrease according to the released livestock income | TODO |
| 11 | Check UI feedback | Success text appears, for example `已放归 XXX` | TODO |
| 12 | Check visual feedback | Detail / confirmation / success feedback has useful light fade or scale response | TODO |
| 13 | Trigger manual save with debug UI | Manual save returns and the page does not freeze | TODO |
| 14 | Wait for autosave after release | Delayed autosave returns and the page does not freeze | TODO |
| 15 | Restart the game | Released livestock remains absent after restore | TODO |
| 16 | Reopen `我的生物` after restart | List, count, capacity, and income match the released state | TODO |
| 17 | Confirm Output / Debugger | No red errors during the full flow | TODO |
| 18 | Recheck M10 shop open path | Shop still opens and lists M10 products | TODO |
| 19 | Recheck M10 purchase path if desired | Buying still works and does not freeze | TODO |

## Notes

- No release reward is expected.
- No Reef Points refund is expected.
- No ocean, expedition, achievement, breeding, death, or equipment feature is expected.
- Persistence uses the existing `owned_livestock` save payload; this prototype adds no new save field.
