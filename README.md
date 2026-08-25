# OLIGARCHY

> **Elite capital. Public code. Pay your taxes.**

![OLIGARCHY — Department of Oligarch Revenue](preview.png)

A complete Omarchy Quattro theme and native shell experience for the 2026 **Oligarchy** challenge.

OLIGARCHY 3.0 is not a wallpaper with matching colors. It turns the desktop into a usable financial terminal, tax office, family office, executive panic room, and animated monument to capital allocation—while leaving Omarchy's real system behavior intact.

## The joke now survives contact with the desktop

| Surface | Oligarchy treatment | Still useful for |
| --- | --- | --- |
| Bar | Live `TAX·nn` assessment ticker | Opening the operating panel; instant copy/reassessment |
| Revenue desk | Department of Oligarch Revenue | Verified QR, address copy, BaseScan, fresh assessments |
| Holdings desk | Machine as family-office balance sheet | Live load, memory, disk, uptime, and battery telemetry |
| Privileges desk | System controls renamed for executives | Lock, DND, stay-awake, fullscreen screenshot |
| Idle Capital desk | Four-scene native screensaver manager | Preview, opt-in default, restore, system branding |
| Screensaver | Animated wealth extraction in Quickshell | Multi-monitor idle display, activity dismissal, burn-in drift |
| About + fallback saver | Institutional shareholder propaganda | Reversible Omarchy branding |
| Launcher, menus, popups, notifications, Polkit, lock | Financial-terminal surface system | Cohesive readable shell chrome |
| Desktop + unlock | Assessment notice and treasury identity | Deterministic first-run wallpaper and lock art |

## Oligarch Operating System

Click the bar assessment to open four keyboard-friendly desks. Right-click still copies the exact treasury address; middle-click still issues a new assessment.

### 1. Revenue

![Revenue desk with verified treasury QR](assets/oligarch-os-revenue.png)

The Revenue desk keeps the original joke honest: the QR is real, the address is exact, and the public ledger is one action away. No wallet connection or payment request exists.

### 2. Holdings

![Live system holdings desk](assets/oligarch-os-holdings.png)

This is real local system telemetry wearing a ridiculous annual report: one-minute load, memory utilization, root-disk occupancy, uptime, and battery capacity. Nothing is fetched from a network.

### 3. Executive Privileges

![Executive system controls](assets/oligarch-os-privileges.png)

The buttons are jokes; the actions are not:

- **Lock Estate** locks the Omarchy session.
- **Silence Staff** toggles Do Not Disturb.
- **Keep Markets Open** toggles stay-awake/idle behavior.
- **Capture Asset** saves a fullscreen screenshot.

### 4. Private Idle Capital

![Native screensaver management desk](assets/oligarch-os-idle-capital.png)

Preview the suite without changing system state, make it the idle default with one explicit action, restore the original Omarchy behavior, or install matching About/fallback-saver branding.

## Four native animated screensavers

These are live QML scenes, not background images. They render once per output, drift to reduce burn-in, rotate every 15 seconds, honor Omarchy's configured idle time, respect idle inhibitors, and dismiss on activity.

![OLIGARCHY animated screensaver suite](assets/screensaver-suite.gif)

### Trickle-Up Economy

![Trickle-Up Economy screensaver](assets/screensaver-trickle-up.png)

Every coin eventually finds its natural owner. Settlement may take three to five generations.

### The Market Has Spoken

![Market Maker screensaver](assets/screensaver-market-maker.png)

Continuous price discovery for human capital, starter homes, marine deductions, and regulatory capture.

### Shell Company Orbital

![Shell Company Orbital screensaver](assets/screensaver-shell-orbit.png)

Nine disclosure vehicles orbit one beneficial owner who remains tastefully redacted.

### Annual General Meeting

![Board Meeting screensaver](assets/screensaver-board-meeting.png)

Minority shareholders are represented by a decorative chair. The motion still carries 1–0.

## Pay your taxes to the oligarch

**Network:** Base  
**Chain ID:** 8453  
**Treasury:**

```text
0xcF84921FCedeC933a9EdF5eAAE66043424a82D38
```

<img src="assets/treasury-qr.png" alt="Verified OLIGARCH treasury QR" width="360">

The standalone QR uses high error correction, a six-module quiet zone, and hard pixel edges. Release validation decodes the source asset and the compositor-rendered panel back to the exact address.

No payment is required to use the theme. Voluntary compliance remains mandatory.

## Install

Install the safe visual theme:

```bash
omarchy theme install https://github.com/rookepoole/omarchy-oligarchy-theme.git
```

Add the native operating system layer:

```bash
omarchy plugin add https://github.com/rookepoole/omarchy-oligarchy-theme.git --enable
```

Omarchy correctly treats plugins as code and shows its normal review warning. The visual theme and executable plugin remain separate approval boundaries even though they share one repository.

### Upgrade from 2.x

```bash
omarchy theme update
omarchy theme set oligarchy
omarchy plugin update rookepoole.oligarchy-tax-department --yes
omarchy plugin enable rookepoole.oligarchy-tax-department
```

## Screensaver integration and restoration

Previewing the suite changes nothing. **Make Idle Default** performs a reversible, user-requested switch:

1. Record whether Omarchy's stock screensaver was already disabled.
2. Use Omarchy's documented `screensaver-off` state flag so the stock terminal saver does not race the native suite.
3. Preserve that prior preference under `~/.local/state/oligarchy/`.
4. Start the native suite at the `idle.screensaver` time already configured in `shell.json`.

**Restore Omarchy** puts the prior screensaver preference back and restores any About/screensaver branding that OLIGARCHY backed up. It does not guess or overwrite an unknown prior state.

Direct controls are also available:

```bash
omarchy-shell oligarchy-screensaver preview
omarchy-shell oligarchy-screensaver enable
omarchy-shell oligarchy-screensaver disable
omarchy-shell oligarchy-screensaver status
```

## Keyboard controls

| Input | Result |
| --- | --- |
| Left-click `TAX·nn` | Open or close the operating panel |
| Right-click `TAX·nn` | Copy the exact Base treasury address |
| Middle-click `TAX·nn` | Issue a fresh assessment |
| `1`–`4` | Select Revenue, Holdings, Privileges, or Idle Capital |
| Tab / Shift+Tab | Move between desks |
| Arrow keys / `h j k l` | Move between actions |
| Enter / Space | Run the selected action |
| `c o r` | Copy, open ledger, reassess on Revenue |
| `l d a s` | Lock, DND, stay awake, screenshot on Privileges |
| `p m x b` | Preview, make default, restore, brand on Idle Capital |
| Escape | Close the panel or screensaver |

## Safety boundary

The Git-installed visual layer contains no Lua, terminal launch configuration, symlink, or `vscode.json`, so Omarchy's safe staging path remains visual-only.

The separately approved plugin:

- uses Omarchy's own `Panel`, `KeyboardPanel`, controls, theme tokens, service loader, and `IdleMonitor`;
- makes no remote request and starts no external daemon;
- never requests a wallet connection, signature, secret, or payment;
- stores only reversible user state under `~/.local/state/oligarchy/`;
- backs up branding before changing it and restores the previous bytes;
- uses fixed system commands rather than interpolating external input.

Remove the interactive layer without touching the theme:

```bash
omarchy plugin remove rookepoole.oligarchy-tax-department
```

If the custom saver was made default, use **Restore Omarchy** first so the prior idle preference is restored before removal.

## Included visual surfaces

OLIGARCHY overrides the full current Quattro palette plus bar, controls, spacing, typography, popups, tooltips, notifications, launcher, menus, Polkit, lock screen, and image picker. It also ships matching unlock art, `Yaru-sage` icons, and shareholder-green keyboard RGB.

The active `backgrounds/` directory contains one deterministic wallpaper, `+tax-department.png`, so the Department of Oligarch Revenue remains the first-run desktop instead of losing a filename lottery.

## Validate a release

```bash
python validate_theme.py
node tests/model.test.js
omarchy plugin validate .
```

The release gate checks palette and shell coverage, Git-theme safety, manifest and service contracts, multi-output screensaver structure, wallet authority, image dimensions, QR decoding, branding assets, and the exact SHA-256 manifest. Runtime verification additionally loads both plugin entry points under current Quickshell/Omarchy UI modules, renders every desk and screensaver scene under Wayland, exercises reversible system state, and decodes the QR from the rendered panel.

## Palette

- **Private Equity Black** — `#080B0A`
- **Shareholder Green** — `#A6D96A`
- **Golden Parachute** — `#D4B35A`
- **Annual Report Ivory** — `#E9E5D6`
- **Liquidation Red** — `#DA655E`
- **Base Blue** — `#5D8CEB`

## License

MIT. Public code, naturally.
