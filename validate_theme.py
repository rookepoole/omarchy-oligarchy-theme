#!/usr/bin/env python3
from pathlib import Path
import tomllib, re, sys
from PIL import Image

ROOT = Path(__file__).resolve().parent
WALLET = "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38"

required = {
    "mode", "accent", "selection", "muted",
    "background", "dark_background", "darker_background", "lighter_background",
    "foreground", "dark_foreground", "light_foreground", "bright_foreground",
    "red", "yellow", "orange", "green", "cyan", "blue", "magenta", "brown",
    "bright_red", "bright_yellow", "bright_green", "bright_cyan",
    "bright_blue", "bright_magenta"
}

with open(ROOT / "colors.toml", "rb") as f:
    palette = tomllib.load(f)

missing = sorted(required - palette.keys())
assert not missing, f"missing palette keys: {missing}"
assert palette["mode"] == "dark"

hex_re = re.compile(r"^#[0-9A-Fa-f]{6}$")
for key in required - {"mode"}:
    assert hex_re.match(palette[key]), f"invalid color {key}={palette[key]}"

assert re.fullmatch(r"0x[0-9A-Fa-f]{40}", WALLET), "wallet shape invalid"

denied = {"alacritty.toml", "foot.ini", "ghostty.conf", "kitty.conf", "vscode.json"}
for p in ROOT.rglob("*"):
    if p.is_file():
        assert p.name not in denied, f"Git-installed theme denied file: {p.name}"
        assert p.suffix != ".lua", f"Git-installed theme cannot ship Lua: {p.name}"

backgrounds = sorted((ROOT / "backgrounds").glob("*"))
assert len(backgrounds) >= 3, "expected >= 3 backgrounds"
for p in backgrounds:
    assert p.suffix.lower() in {".jpg",".jpeg",".png",".gif",".bmp",".webp"}
    with Image.open(p) as im:
        assert im.size == (2560, 1440), f"unexpected wallpaper size {p.name}: {im.size}"

assert (ROOT / "unlock.png").is_file()
assert (ROOT / "preview-unlock.png").is_file()

print("PASS — OLIGARCHY theme package validates")
print(f"Palette keys: {len(palette)}")
print(f"Backgrounds: {len(backgrounds)}")
print("Wallet:", WALLET)
