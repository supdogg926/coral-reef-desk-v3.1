# M19-D003

02 M19ReadyPanel.gd used M19SharedTheme.make_shell_style() (programmatic StyleBox) instead of loading shell_02_ready_empty.png as TextureRect plate. 03 VoyagingPanel same issue.

## Ruling
Each page must load its corresponding freeze shell PNG as a TextureRect plate.
