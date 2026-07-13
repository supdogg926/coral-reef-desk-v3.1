# M19-D004

Main.gd never hid legacy visual nodes (Background, RootMargin, PipeNetworkView). World code used ColorRect.new() for rocks/corals/equipment.

## Ruling
Legacy visual nodes must be hidden. Missing asset instances must be hidden, never shown as ColorRect placeholders.
