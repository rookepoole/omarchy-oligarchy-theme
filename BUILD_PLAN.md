# OLIGARCHY — Challenge Build Ledger

## Goal

Win the $500 Oligarchy theme challenge by making something that lands both
criteria in the brief:

1. **Funny**
2. **Good-looking enough to ship in Omarchy**

## Visual thesis

**Bloomberg terminal × 1980s annual report × private banking × Unix workstation.**

The theme should not look like a meme pack. The joke comes from corporate
language, finance-terminal motifs, and increasingly absurd optional wallpapers.

## v0.1.0 — IMPLEMENTED

- [x] Current-format `colors.toml`
- [x] Green/gold active-border gradient
- [x] Bar section override
- [x] Shared controls section override
- [x] Popup section override
- [x] Notification section override
- [x] Launcher section override
- [x] Menu section override
- [x] Lock section override
- [x] 2560×1440 default annual-report wallpaper
- [x] 2560×1440 hostile-takeover wallpaper
- [x] 2560×1440 tax-office wallpaper
- [x] Base treasury wallet joke:
  `0xcF84921FCedeC933a9EdF5eAAE66043424a82D38`
- [x] Transparent unlock asset
- [x] Unlock preview
- [x] Static validation script
- [x] Git-install-safe source layout

## TESTED LOCALLY IN THIS PACKAGE

- [x] TOML syntax parses
- [x] Required palette keys exist
- [x] All palette colors use valid hex values
- [x] Base wallet has 20-byte / 40-hex-character address shape
- [x] Required wallpaper directory exists
- [x] Backgrounds are supported PNG format
- [x] Backgrounds are 2560×1440
- [x] No Git-installed-theme denied files are present
- [x] ZIP packaging integrity

## BLOCKED UNTIL REAL OMARCHY UI

- [ ] Run `omarchy theme set oligarchy`
- [ ] Inspect shell palette rendering
- [ ] Inspect launcher/menu selection state
- [ ] Inspect notification left border
- [ ] Inspect lock screen
- [ ] Inspect Chromium/editor/terminal generated theme output
- [ ] Capture full-screen screenshots
- [ ] Tune contrast based on screenshots
- [ ] Capture final demo GIF/video if useful

## v0.2 TARGET

- [ ] Visual tuning from real Omarchy screenshots
- [ ] Decide whether gold is too prominent in active borders
- [ ] Add one exceptionally polished fourth wallpaper only if it improves the set
- [ ] Final repository metadata
- [ ] Final challenge submission email
