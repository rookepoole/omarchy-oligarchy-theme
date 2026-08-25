#!/usr/bin/env python3
"""Materialize the verified OLIGARCHY treasury QR from the frozen address."""

from pathlib import Path

import qrcode
from qrcode.constants import ERROR_CORRECT_H


ROOT = Path(__file__).resolve().parents[1]
WALLET = "0xcF84921FCedeC933a9EdF5eAAE66043424a82D38"
OUTPUT = ROOT / "assets" / "treasury-qr.png"


def main() -> None:
    qr = qrcode.QRCode(
        version=None,
        error_correction=ERROR_CORRECT_H,
        box_size=14,
        border=6,
    )
    qr.add_data(WALLET, optimize=0)
    qr.make(fit=True)
    # Conventional dark modules on a light field are materially more robust
    # than an inverted decorative code. The colors are still the theme's
    # private-equity black and shareholder green.
    image = qr.make_image(fill_color="#060806", back_color="#B8F37C").convert("RGB")
    image.save(OUTPUT, format="PNG", optimize=True)
    print(f"wrote {OUTPUT} ({image.width}x{image.height})")


if __name__ == "__main__":
    main()
