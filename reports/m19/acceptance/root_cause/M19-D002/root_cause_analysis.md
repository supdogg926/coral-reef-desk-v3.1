# M19-D002

M19MainInterfaceHybrid._build() used 6 separate TextureRects from region PNGs. Gaps, double borders, and alignment errors resulted.

## Ruling
01 Chrome must use single full 01_runtime_empty_master.png. Region crops forbidden in production.
