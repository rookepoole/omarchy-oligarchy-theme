#!/usr/bin/env python3
"""Release gate for the OLIGARCHY theme + Tax Department plugin."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import sys
import tomllib

from PIL import Image


ROOT = Path(__file__).resolve().parent
WALLET = "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38"
PLUGIN_ID = "rookepoole.oligarchy-tax-department"
REPO_URL = "https://github.com/rookepoole/omarchy-oligarchy-theme.git"

REQUIRED_COLORS = {
    "mode", "accent", "selection", "muted",
    "background", "dark_background", "darker_background", "lighter_background",
    "foreground", "dark_foreground", "light_foreground", "bright_foreground",
    "red", "yellow", "orange", "green", "cyan", "blue", "magenta", "brown",
    "bright_red", "bright_yellow", "bright_green", "bright_cyan",
    "bright_blue", "bright_magenta",
}
DENIED_INSTALLED_NAMES = {
    "alacritty.toml", "foot.ini", "ghostty.conf", "kitty.conf", "vscode.json",
}
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def validate_palette() -> dict[str, object]:
    with (ROOT / "colors.toml").open("rb") as source:
        palette = tomllib.load(source)
    missing = sorted(REQUIRED_COLORS - palette.keys())
    assert not missing, f"missing palette keys: {missing}"
    assert palette["mode"] == "dark", "OLIGARCHY must remain a dark theme"
    for key in REQUIRED_COLORS - {"mode"}:
        assert re.fullmatch(r"#[0-9A-Fa-f]{6}", str(palette[key])), f"invalid color {key}={palette[key]}"
    return palette


def validate_safe_theme_surface() -> None:
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        assert path.name not in DENIED_INSTALLED_NAMES, f"Git-installed theme denied file: {path.name}"
        assert path.suffix != ".lua", f"Git-installed theme cannot ship Lua: {path.name}"


def validate_shell_overrides() -> int:
    expected_sections = {
        "bar", "controls", "font", "image-picker", "launcher", "lock",
        "menu", "notifications", "polkit", "popups", "spacing", "tooltip",
    }
    overrides = sorted(ROOT.glob("shell.*.toml"))
    actual_sections = {path.name.removeprefix("shell.").removesuffix(".toml") for path in overrides}
    assert actual_sections == expected_sections, (
        f"shell override coverage differs: expected {sorted(expected_sections)}, got {sorted(actual_sections)}"
    )
    for path in overrides:
        with path.open("rb") as source:
            values = tomllib.load(source)
        assert values, f"empty shell override: {path.name}"
    return len(overrides)


def validate_plugin() -> dict[str, object]:
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    assert manifest["schemaVersion"] == 1
    assert manifest["id"] == PLUGIN_ID
    assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", manifest["id"])
    assert ".." not in manifest["id"] and not manifest["id"].startswith("omarchy.")
    assert manifest["version"] == (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    assert manifest["kinds"] == ["bar-widget", "service"]
    entry = manifest["entryPoints"]["barWidget"]
    service_entry = manifest["entryPoints"]["service"]
    assert entry == "TaxDepartment.qml"
    assert service_entry == "OligarchyService.qml"
    assert (ROOT / entry).is_file()
    assert (ROOT / service_entry).is_file()
    assert (ROOT / "ExecutiveExit.qml").is_file()
    assert manifest["barWidget"]["allowMultiple"] is False
    assert manifest["barWidget"]["defaultSection"] in {"left", "center", "right"}

    symlinks = [path.relative_to(ROOT) for path in ROOT.rglob("*") if path.is_symlink() and ".git" not in path.parts]
    assert not symlinks, f"plugin folder may not contain symlinks: {symlinks}"

    qml = (ROOT / entry).read_text(encoding="utf-8")
    overlay_qml = (ROOT / "ExecutiveExit.qml").read_text(encoding="utf-8")
    service_qml = (ROOT / service_entry).read_text(encoding="utf-8")
    key_catcher_qml = (ROOT / "OligarchyKeyCatcher.qml").read_text(encoding="utf-8")
    saver_qml = (ROOT / "OligarchyScreensaver.qml").read_text(encoding="utf-8")
    model = (ROOT / "TaxModel.js").read_text(encoding="utf-8")
    assert "ShellRoot" not in qml, "plugin entry point must be an Item-derived component"
    assert "ShellRoot" not in overlay_qml, "service-owned overlay must be an Item-derived component"
    assert "ShellRoot" not in service_qml, "service entry point must be an Item-derived component"
    assert re.search(r"\bPanel\s*\{", qml), "expected native Omarchy Panel root"
    assert re.search(r"\bItem\s*\{", service_qml), "expected Item-derived service root"
    assert "IdleMonitor" in service_qml, "expected native idle integration"
    assert "Variants" in service_qml and "PanelWindow" in service_qml, "expected one screensaver surface per output"
    assert 'target: "oligarchy-screensaver"' in service_qml, "expected screensaver IPC target"
    assert 'target: "oligarchy-executive-exit"' in service_qml, "expected service-owned exit IPC target"
    assert re.search(r"\bExecutiveExit\s*\{", service_qml), "service must own the exit overlay"
    assert "function request(actionId: string)" in service_qml, "exit IPC must preserve the confirmation-request boundary"
    assert "function previewScene" in service_qml, "expected direct scene-selection IPC"
    assert "CONTROLLING INTEREST ACQUIRED" in service_qml, "expected one-time onboarding notice"
    assert saver_qml.count("// Scene ") == 5, "expected five distinct animated screensaver scenes"
    assert "CORPORATE PIZZA PARTY" in model and "MANDATORY ATTENDANCE" in saver_qml, "expected native corporate pizza party scene"
    assert "TAX·" in qml, "expected live assessment in the bar"
    assert "ROI·" in qml and "focusRunning" in qml, "expected bar-integrated focus clock"
    assert "Quickshell.Hyprland" in qml, "expected native Hyprland workspace integration"
    assert "PORTFOLIOS" in model and "PORTFOLIO COMPANIES" in qml, "expected workspace acquisition desk"
    assert "COMPOUND INTEREST" in qml and "formatFocusTime" in model, "expected focus desk"
    assert "openAnnualReport" in qml and "omarchy-launch-floating-terminal-with-presentation" in qml, "expected terminal annual report launcher"
    assert "conveneExitCommittee" in qml and '"oligarchy-executive-exit", "open"' in qml, "expected stable service-owned exit route"
    assert "OligarchyKeyCatcher" in qml, "Tax Department must use its mnemonic-safe keyboard router"
    for reserved in ('event.text === "h"', 'event.text === "j"', 'event.text === "k"', 'event.text === "l"', 'event.text === "x"'):
        assert reserved not in key_catcher_qml, f"desk mnemonic is still intercepted: {reserved}"
    assert key_catcher_qml.count("moveRequested(") == 5, "only four arrow branches plus the signal declaration should navigate"
    assert "event.accepted = root.routeKey(event.key, event.text, event.modifiers)" in key_catcher_qml, "production key events must use the verified mnemonic router"
    assert "PanelWindow" in overlay_qml and "WlrLayer.Overlay" in overlay_qml, "expected native fullscreen exit overlay"
    assert "ConfirmDialog" in overlay_qml and "selectedIndex = 0" in overlay_qml, "disruptive session actions must default to safe confirmation"
    for command in (
        "omarchy-system-lock", "systemctl", "suspend", "omarchy-system-logout",
        "omarchy-system-reboot", "omarchy-system-shutdown",
    ):
        assert command in overlay_qml, f"missing fixed exit action: {command}"
    for forbidden in ("bash", "curl", "wget", "sudo", "eval", "rm -"):
        assert forbidden not in overlay_qml, f"exit overlay must dispatch fixed argv without shell interpolation: {forbidden}"
    assert 'pageNames: ["REVENUE", "HOLDINGS", "PRIVILEGES", "IDLE CAPITAL", "ACQUISITIONS", "COMPOUND"]' in qml
    for command in (
        "omarchy-system-lock", "omarchy-toggle-notification-silencing",
        "omarchy-toggle-idle", "omarchy-capture-screenshot",
    ):
        assert command in qml, f"missing executive system action: {command}"
    for path in (ROOT / "branding" / "about.txt", ROOT / "branding" / "screensaver.txt"):
        assert path.is_file() and path.stat().st_size > 100, f"missing institutional branding: {path.name}"
    assert qml.count(WALLET) == 0, "wallet authority belongs in TaxModel.js only"
    assert model.count(WALLET) == 1, "TaxModel.js must contain one wallet authority"
    assert "https://basescan.org/address/" in qml
    return manifest


def validate_installer() -> None:
    installer_path = ROOT / "install-plugin.sh"
    installer = installer_path.read_text(encoding="utf-8")
    assert installer.startswith("#!/bin/bash\n"), "installer must have a Bash shebang"
    assert f'PLUGIN_ID="{PLUGIN_ID}"' in installer, "installer plugin id drifted"
    assert f'REPO_URL="{REPO_URL}"' in installer, "installer repository URL drifted"
    assert 'omarchy plugin update "$PLUGIN_ID" --yes' in installer
    assert 'omarchy plugin add "$REPO_URL" --enable --yes' in installer
    assert 'omarchy plugin enable "$PLUGIN_ID" --section right' in installer
    assert "rescanPlugins" in installer, "installer must rescan shell plugins"
    assert 'bash "$SCRIPT_DIR/keybinding.sh" install' in installer, "installer must provision the global Tax Department binding"
    assert 'bash "$SCRIPT_DIR/launcher-entries.sh" install' in installer, "installer must provision the Apps-menu integration"
    for destructive in ("reset --hard", "plugin remove", "rm -rf"):
        assert destructive not in installer, f"installer must not use destructive recovery: {destructive}"

    keybinding = (ROOT / "keybinding.sh").read_text(encoding="utf-8")
    assert keybinding.startswith("#!/bin/bash\n"), "keybinding manager must have a Bash shebang"
    assert 'CHORD="SUPER + SHIFT + T"' in keybinding
    assert 'PLUGIN_ID="rookepoole.oligarchy-tax-department"' in keybinding
    assert 'readonly COMMAND="omarchy-shell shell toggle $PLUGIN_ID"' in keybinding, "current Tax command must be argument-free"
    assert "hl.unbind" not in keybinding, "keybinding manager must never unbind an existing action"
    assert "configerrors" in keybinding and "prior bindings file was restored" in keybinding
    assert "live_bind_records" in keybinding and "live_managed_binding_present" in keybinding
    assert 'hyprctl eval "$BINDING_LINE"' in keybinding, "live repair fallback must reuse the exact persistent line"

    launcher_manager = (ROOT / "launcher-entries.sh").read_text(encoding="utf-8")
    assert launcher_manager.startswith("#!/bin/bash\n"), "launcher manager must have a Bash shebang"
    assert "X-Oligarchy-Managed=true" in launcher_manager
    assert "is_managed" in launcher_manager and "nothing was changed" in launcher_manager
    entries = {
        "oligarchy-tax-department.desktop": "omarchy-shell shell summon rookepoole.oligarchy-tax-department {}",
        "oligarchy-executive-exit.desktop": "omarchy-shell oligarchy-executive-exit open {}",
        "oligarchy-pizza-party.desktop": "omarchy-shell oligarchy-screensaver previewScene 4",
    }
    for name, command in entries.items():
        content = (ROOT / "launcher" / name).read_text(encoding="utf-8")
        assert content.startswith("[Desktop Entry]\n"), f"invalid launcher header: {name}"
        assert "X-Oligarchy-Managed=true" in content, f"launcher ownership marker missing: {name}"
        assert f"Exec={command}" in content, f"launcher command drifted: {name}"
        assert WALLET not in content, f"wallet authority must not be duplicated in launcher metadata: {name}"


def validate_annual_report() -> None:
    report_path = ROOT / "annual-report.sh"
    report = report_path.read_text(encoding="utf-8")
    assert report.startswith("#!/bin/bash\n"), "annual report must have a Bash shebang"
    assert "TREASURY.txt" in report, "annual report must read the frozen treasury authority"
    assert WALLET not in report, "annual report must not duplicate the treasury wallet"
    for expected in (
        "CONSOLIDATED ANNUAL REPORT", "CONSOLIDATED HOLDINGS",
        "PORTFOLIO COMPANIES", "TREASURY AND VOLUNTARY COMPLIANCE", "qrencode",
    ):
        assert expected in report, f"annual report missing surface: {expected}"
    for forbidden in ("curl ", "wget ", "sudo ", "eval ", "rm -", "systemctl "):
        assert forbidden not in report, f"annual report violates its read-only boundary: {forbidden}"


def validate_images() -> list[Path]:
    backgrounds = sorted(
        path for path in (ROOT / "backgrounds").iterdir()
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    )
    assert [path.name for path in backgrounds] == ["+tax-department.png"], (
        "the Tax Department must remain the one deterministic first-run background"
    )
    with Image.open(backgrounds[0]) as image:
        assert image.size == (3840, 2160), f"unexpected wallpaper size: {image.size}"
    expected_sizes = {
        "preview.png": (1600, 900),
        "preview-unlock.png": (1600, 900),
        "unlock.png": (1600, 800),
    }
    for name, size in expected_sizes.items():
        with Image.open(ROOT / name) as image:
            assert image.size == size, f"unexpected {name} size: {image.size}"
    desk_capture_sizes = {
        "oligarch-os-revenue.png": (595, 393),
        "oligarch-os-holdings.png": (595, 359),
        "oligarch-os-privileges.png": (595, 404),
        "oligarch-os-idle-capital.png": (595, 356),
        "oligarch-os-acquisitions.png": (595, 381),
        "oligarch-os-compound.png": (595, 408),
        "operating-system-tour.gif": (595, 408),
        "executive-exit-committee.png": (1280, 720),
        "executive-exit-confirmation.png": (1280, 720),
    }
    for name, size in desk_capture_sizes.items():
        with Image.open(ROOT / "assets" / name) as image:
            assert image.size == size, f"unexpected {name} size: {image.size}"
            if name == "operating-system-tour.gif":
                assert getattr(image, "n_frames", 0) >= 6, "operating-system tour must show all six desks"
                assert image.info.get("loop") == 0, "operating-system tour must loop"
    showcase_sizes = {
        "apps-menu-launchers.png": (1280, 720),
        "screensaver-pizza-party.png": (1280, 720),
        "screensaver-suite.gif": (1280, 720),
    }
    for name, size in showcase_sizes.items():
        with Image.open(ROOT / "assets" / name) as image:
            assert image.size == size, f"unexpected {name} size: {image.size}"
            if name == "screensaver-suite.gif":
                assert getattr(image, "n_frames", 0) >= 5, "screensaver tour must show all five scenes"
                assert image.info.get("loop") == 0, "screensaver tour must loop"
    return backgrounds


def validate_wallet_authority() -> None:
    assert re.fullmatch(r"0x[0-9A-Fa-f]{40}", WALLET), "wallet shape invalid"
    treasury = (ROOT / "TREASURY.txt").read_text(encoding="utf-8").strip()
    assert treasury == WALLET, "TREASURY.txt differs from frozen wallet"


def validate_qr() -> tuple[str, tuple[int, int]]:
    try:
        import cv2
    except ImportError as exc:
        raise AssertionError(
            "QR decoding requires opencv-python-headless; install the release dependencies first"
        ) from exc

    path = ROOT / "assets" / "treasury-qr.png"
    image = cv2.imread(str(path))
    assert image is not None, "treasury QR could not be loaded"
    decoded, points, _ = cv2.QRCodeDetector().detectAndDecode(image)
    assert points is not None, "treasury QR was not detected"
    assert decoded == WALLET, f"treasury QR decoded to {decoded!r}"
    height, width = image.shape[:2]
    return decoded, (width, height)


def validate_checksums() -> int:
    manifest_path = ROOT / "SHA256SUMS"
    seen: set[str] = set()
    for line in manifest_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        expected, relative = line.split("  ", 1)
        path = ROOT / relative
        assert path.is_file(), f"checksum target missing: {relative}"
        assert sha256(path) == expected, f"checksum mismatch: {relative}"
        seen.add(relative)

    required = {
        path.relative_to(ROOT).as_posix()
        for path in ROOT.rglob("*")
        if path.is_file()
        and ".git" not in path.parts
        and path.name != "SHA256SUMS"
        and "__pycache__" not in path.parts
    }
    missing = sorted(required - seen)
    stale = sorted(seen - required)
    assert not missing, f"files missing from SHA256SUMS: {missing}"
    assert not stale, f"stale SHA256SUMS entries: {stale}"
    return len(seen)


def main() -> None:
    palette = validate_palette()
    validate_safe_theme_surface()
    shell_overrides = validate_shell_overrides()
    manifest = validate_plugin()
    validate_installer()
    validate_annual_report()
    backgrounds = validate_images()
    validate_wallet_authority()
    decoded, qr_size = validate_qr()
    checksum_count = validate_checksums()

    print(f"PASS - OLIGARCHY {manifest['version']} release validates")
    print(f"Palette keys: {len(palette)}")
    print(f"Shell surfaces: {shell_overrides}")
    print(f"Backgrounds: {len(backgrounds)} deterministic default")
    print(f"Plugin: {manifest['id']} @ {manifest['version']}")
    print(f"QR: {qr_size[0]}x{qr_size[1]} -> {decoded}")
    print(f"Checksums: {checksum_count}")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"FAIL - {exc}", file=sys.stderr)
        raise SystemExit(1)
