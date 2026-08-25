# OLIGARCHY — Omarchy Theme

> **Elite capital. Public code.**

A dark, restrained, self-aware Omarchy theme built for DHH's August 2026
"Oligarchy theme" challenge: funny, but good-looking enough to ship.

## Design

OLIGARCHY is **90% serious desktop / 10% corporate absurdity**:
- near-black private-equity surfaces
- shareholder green accent
- champagne-gold secondary accent
- warm annual-report ivory text
- restrained green→gold active-border gradient
- terminal / annual-report / finance-console visual language

The default wallpaper is intentionally the most shippable. The jokes get
more obvious as you cycle backgrounds.

## The tax department

One optional wallpaper contains:

**PAY YOUR TAXES TO THE OLIGARCH**

**BASE TREASURY:** `0xcF84921FCedeC933a9EdF5eAAE66043424a82D38`

The address is intentionally public-facing and is included as supplied by
the theme author.

## Install from Git

Once this repository is public:

```bash
omarchy theme install https://github.com/YOUR-USER/omarchy-oligarchy-theme.git
```

Omarchy's naming convention strips `omarchy-` and `-theme`, so the installed
theme appears as `oligarchy`.

## Local development install

```bash
mkdir -p ~/.config/omarchy/themes/oligarchy
cp -r ./* ~/.config/omarchy/themes/oligarchy/
omarchy theme set oligarchy
```

Use the background picker to cycle the included wallpapers:

```text
Super + Ctrl + Space
```

## Compatibility target

Built against the current Omarchy Quattro theme model:
- `colors.toml` is the source palette.
- `shell.<section>.toml` files override generated shell sections.
- wallpapers live under `backgrounds/`.
- repo-installed themes must not rely on Lua, terminal config files, or
  `vscode.json`; current Omarchy deliberately strips those from untrusted
  Git-installed themes.

This repository therefore contains **no executable theme code**.

## Included backgrounds

1. `0-annual-report.png` — default, restrained, ship-ready.
2. `1-hostile-takeover.png` — corporate acquisition terminal joke.
3. `2-tax-office.png` — Base wallet / oligarch tax joke.

## Validation

```bash
python validate_theme.py
```

For final visual acceptance on a real Omarchy machine:

```bash
omarchy theme set oligarchy
omarchy capture screenshot fullscreen save
```

Then inspect the theme selector, launcher, notifications, lock screen,
terminal/editor colors, and all three wallpapers.

## Status

See `BUILD_PLAN.md`.
