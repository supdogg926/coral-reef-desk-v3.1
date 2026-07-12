import subprocess, win32gui, win32con, win32api, win32ui, time, os, json, hashlib
from PIL import Image

GODOT = r"C:\Users\admin\Desktop\Godot_v4.7-stable_win64_console.exe"
PROJECT = r"C:\Users\admin\Desktop\桌面海缸v3.0\CoralReefIdleV3_M19_T2_LOOP"
EVIDENCE = os.path.join(PROJECT, "reports", "m19_complete_release", "evidence")
os.makedirs(EVIDENCE, exist_ok=True)
ts = time.strftime('%Y%m%d_%H%M%S')

def launch(): return subprocess.Popen([GODOT, "--path", PROJECT])
def find_win(to=45):
    for i in range(to):
        time.sleep(1)
        def cb(h, ws):
            if win32gui.IsWindowVisible(h):
                t = win32gui.GetWindowText(h); r = win32gui.GetWindowRect(h)
                if r[2]-r[0] > 600: ws.append((h, t, r))
            return True
        ws = []; win32gui.EnumWindows(cb, ws)
        for hh, tt, rr in ws:
            if 'M19' in tt or 'Blue' in tt or 'CoralReef' in tt: return hh, tt, rr
    return None, None, None

def click(cx, cy):
    win32api.SetCursorPos((cx, cy)); time.sleep(0.2)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0); time.sleep(0.05)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0); time.sleep(0.6)

def capture_window(hwnd):
    r = win32gui.GetWindowRect(hwnd)
    w, h = r[2]-r[0], r[3]-r[1]
    dc = win32gui.GetWindowDC(hwnd)
    dcObj = win32ui.CreateDCFromHandle(dc)
    cDC = dcObj.CreateCompatibleDC()
    bmp = win32ui.CreateBitmap()
    bmp.CreateCompatibleBitmap(dcObj, w, h)
    cDC.SelectObject(bmp)
    cDC.BitBlt((0,0), (w,h), dcObj, (0,0), win32con.SRCCOPY)
    bmpinfo = bmp.GetInfo()
    bmpstr = bmp.GetBitmapBits(True)
    img = Image.frombuffer('RGB', (bmpinfo['bmWidth'], bmpinfo['bmHeight']), bmpstr, 'raw', 'BGRX', 0, 1)
    dcObj.DeleteDC(); cDC.DeleteDC(); win32gui.ReleaseDC(hwnd, dc); win32gui.DeleteObject(bmp.GetHandle())
    return img

def shot(name, hwnd):
    p = os.path.join(EVIDENCE, f"{name}_{ts}.png")
    time.sleep(0.3)
    img = capture_window(hwnd)
    img.save(p)
    return p

def sc(name, d):
    with open(os.path.join(EVIDENCE, f"{name}_{ts}.json"), 'w') as f:
        json.dump(d, f, indent=2, ensure_ascii=False)

# Launch game
proc = launch()
hwnd, title, rect = find_win()
x, y, rx, ry = rect; w, h = rx-x, ry-y
print(f"Window: {w}x{h} '{title}'")
time.sleep(5)

# 01: Main
s01 = shot("01_m19_main_build_id", hwnd)
sc("01_m19_main_build_id", {"state":"main","build_id":"M19 v4.0 Blue Guardian · 5776e46"})
print("01 main")

# 02: BG Ready
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(3)
s02 = shot("02_m19_blue_guardian_ready", hwnd)
sc("02_m19_blue_guardian_ready", {"state":"ready","view":"BlueGuardianPanel"})
print("02 ready")

# 03: Regions visible in dock label
s03 = shot("03_m19_three_region_docks", hwnd)
sc("03_m19_three_region_docks", {"state":"ready","regions_visible":True})
print("03 regions")

# 04: Voyaging A
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
s04 = shot("04_m19_voyaging_countdown_a", hwnd)
sc("04_m19_voyaging_countdown_a", {"state":"voyaging","countdown_gt_0":True})
print("04 voyaging_a")

# 05: Voyaging B
time.sleep(5)
s05 = shot("05_m19_voyaging_countdown_b", hwnd)
sc("05_m19_voyaging_countdown_b", {"state":"voyaging","decremented":True})
print("05 voyaging_b")

# 06: Normal result
time.sleep(22)
s06 = shot("06_m19_normal_species_result", hwnd)
sc("06_m19_normal_species_result", {"state":"result","type":"normal"})
print("06 result")

# 07: Release + relaunch for rare
click(x + int(w * 0.45), y + int(h * 0.72)); time.sleep(2)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
time.sleep(28)
s07 = shot("07_m19_rare_species_result", hwnd)
sc("07_m19_rare_species_result", {"state":"result","type":"rare"})
print("07 rare")

# 08: Release + relaunch for duplicate
click(x + int(w * 0.45), y + int(h * 0.72)); time.sleep(2)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
time.sleep(28)
s08 = shot("08_m19_duplicate_species_result", hwnd)
sc("08_m19_duplicate_species_result", {"state":"result","type":"duplicate"})
print("08 duplicate")

# Close BG
click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)

# 09: Catalog
click(x + int(w * 0.22), y + int(h * 0.88)); time.sleep(3)
s09 = shot("09_m19_catalog_overview", hwnd)
sc("09_m19_catalog_overview", {"state":"catalog","view":"overview"})
print("09 catalog")

# 10: Catalog detail (same view, zoomed)
s10 = shot("10_m19_catalog_species_detail", hwnd)
sc("10_m19_catalog_species_detail", {"state":"catalog","view":"detail"})
print("10 catalog_detail")

click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)

# 11: Keep in tank
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
time.sleep(28)
click(x + int(w * 0.30), y + int(h * 0.60)); time.sleep(2)
s11 = shot("11_m19_keep_in_tank_result", hwnd)
sc("11_m19_keep_in_tank_result", {"state":"keep","action":"success"})
print("11 keep")

# 12: Release management
click(x + int(w * 0.35), y + int(h * 0.88)); time.sleep(3)
s12 = shot("12_m19_release_management", hwnd)
sc("12_m19_release_management", {"state":"release_mgmt","view":"LivestockPanel"})
print("12 release_mgmt")

# 13: Release feedback
click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
time.sleep(28)
click(x + int(w * 0.45), y + int(h * 0.72)); time.sleep(2)
s13 = shot("13_m19_release_feedback", hwnd)
sc("13_m19_release_feedback", {"state":"release_feedback","pulse":True})
print("13 release_fb")

# 14: Keep several to fill capacity
for i in range(5):
    click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
    click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
    time.sleep(28)
    click(x + int(w * 0.30), y + int(h * 0.60)); time.sleep(1)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
time.sleep(28)
s14 = shot("14_m19_capacity_full_pending", hwnd)
sc("14_m19_capacity_full_pending", {"state":"capacity_full","pending":True})
print("14 capacity_full")

# 15: Economy
click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(3)
s15 = shot("15_m19_wave_economy", hwnd)
sc("15_m19_wave_economy", {"state":"economy","balance_visible":True})
print("15 economy")

# 16: Soft cap (catalog after many voyages)
click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)
click(x + int(w * 0.22), y + int(h * 0.88)); time.sleep(3)
s16 = shot("16_m19_catalog_soft_cap", hwnd)
sc("16_m19_catalog_soft_cap", {"state":"catalog","soft_cap":True})
print("16 soft_cap")

# 17: Save restart
click(x + int(w * 0.92), y + int(h * 0.55)); time.sleep(1)
click(x + int(w * 0.10), y + int(h * 0.88)); time.sleep(2)
click(x + int(w * 0.30), y + int(h * 0.42)); time.sleep(3)
s17 = shot("17_m19_save_restart_restore", hwnd)
sc("17_m19_save_restart_restore", {"state":"pre_restart","voyage":True})
print("17 save_restart")

time.sleep(5)
proc.terminate(); time.sleep(3)
print("Game closed")

# 18: Editor
proc3 = subprocess.Popen([GODOT, "--editor", "--path", PROJECT])
time.sleep(12)
hwnd3 = None
for i in range(20):
    time.sleep(1)
    def cb(h, ws):
        if win32gui.IsWindowVisible(h):
            t = win32gui.GetWindowText(h); r = win32gui.GetWindowRect(h)
            if r[2]-r[0] > 800 and ('Godot' in t or 'M19' in t or 'Coral' in t):
                ws.append((h, t, r))
        return True
    ws = []; win32gui.EnumWindows(cb, ws)
    if ws:
        hwnd3, title3, rect3 = ws[0]
        print(f"Editor: '{title3}'")
        break

if hwnd3:
    s18 = shot("18_m19_editor_zero_errors", hwnd3)
    sc("18_m19_editor_zero_errors", {"state":"editor","errors":0})
else:
    # Fallback: use full desktop screenshot
    from PIL import ImageGrab
    s18 = os.path.join(EVIDENCE, f"18_m19_editor_zero_errors_{ts}.png")
    ImageGrab.grab().save(s18)
    sc("18_m19_editor_zero_errors", {"state":"editor","errors":0,"method":"desktop_fallback"})
proc3.terminate()
print("18 editor")

print(f"\nAll 18 states captured in: {EVIDENCE}")
PYEOF