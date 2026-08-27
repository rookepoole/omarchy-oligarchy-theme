#!/usr/bin/env python3
"""Hostile-path and legitimate-state tests for oligarchy-state."""

from __future__ import annotations

import fcntl
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
HELPER = ROOT / "oligarchy-state"


class StateSafetyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.case = Path(self.temp.name)
        self.home = self.case / "home"
        self.bin = self.case / "bin"
        self.home.mkdir(mode=0o700)
        self.bin.mkdir(mode=0o700)
        notifier = self.bin / "omarchy-notification-send"
        notifier.write_text(
            "#!/bin/sh\nprintf '%s\\n' \"$1\" >>\"$HOME/notifications\"\n",
            encoding="utf-8",
        )
        notifier.chmod(0o700)
        self.env = os.environ.copy()
        self.env["HOME"] = str(self.home)
        self.env["PATH"] = f"{self.bin}:{self.env.get('PATH', '')}"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def run_helper(
        self,
        *args: str,
        ok: bool = True,
        timeout: float = 2.0,
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [str(HELPER), *args],
            env=self.env,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=False,
        )
        if ok and result.returncode != 0:
            self.fail(f"helper failed: {result.stderr}")
        if not ok and result.returncode == 0:
            self.fail(f"helper unexpectedly succeeded: {result.stdout}")
        return result

    @property
    def state(self) -> Path:
        return self.home / ".local/state/oligarchy"

    @property
    def toggles(self) -> Path:
        return self.home / ".local/state/omarchy/toggles"

    @property
    def branding_state(self) -> Path:
        return self.state / "branding"

    @property
    def branding_dest(self) -> Path:
        return self.home / ".config/omarchy/branding"

    def branding_sources(self) -> tuple[Path, Path]:
        sources = self.case / "sources"
        sources.mkdir(exist_ok=True)
        about = sources / "about.txt"
        screensaver = sources / "screensaver.txt"
        about.write_bytes(b"new about\n")
        screensaver.write_bytes(b"new screensaver\n")
        return about, screensaver

    def test_default_round_trip_from_enabled(self) -> None:
        self.assertEqual(self.run_helper("default-status").stdout.strip(), "no")
        self.run_helper("default-enable")
        self.assertEqual((self.state / "screensaver-prior").read_bytes(), b"enabled")
        self.assertTrue((self.state / "screensaver-managed").is_file())
        self.assertTrue((self.toggles / "screensaver-off").is_file())
        self.assertEqual(self.run_helper("default-status").stdout.strip(), "yes")

        self.run_helper("default-disable")
        self.assertFalse((self.toggles / "screensaver-off").exists())
        self.assertFalse((self.state / "screensaver-prior").exists())
        self.assertFalse((self.state / "screensaver-managed").exists())
        self.assertEqual(self.run_helper("default-status").stdout.strip(), "no")

    def test_default_round_trip_preserves_pre_disabled_state_and_first_snapshot(self) -> None:
        self.toggles.mkdir(parents=True)
        (self.toggles / "screensaver-off").write_bytes(b"")
        self.run_helper("default-enable")
        self.assertEqual((self.state / "screensaver-prior").read_bytes(), b"disabled")

        (self.toggles / "screensaver-off").write_bytes(b"still-disabled")
        self.run_helper("default-enable")
        self.assertEqual((self.state / "screensaver-prior").read_bytes(), b"disabled")
        self.run_helper("default-disable")
        self.assertEqual((self.toggles / "screensaver-off").read_bytes(), b"still-disabled")

    def test_branding_round_trip_preserves_exact_first_backup(self) -> None:
        about_source, screensaver_source = self.branding_sources()
        self.branding_dest.mkdir(parents=True)
        (self.branding_dest / "about.txt").write_bytes(b"original about\x00bytes")
        (self.branding_dest / "screensaver.txt").write_bytes(b"original saver\n")

        self.run_helper("branding-install", str(about_source), str(screensaver_source))
        self.assertEqual((self.branding_dest / "about.txt").read_bytes(), b"new about\n")
        self.assertEqual(
            (self.branding_state / "about.txt.backup").read_bytes(),
            b"original about\x00bytes",
        )

        about_source.write_bytes(b"updated about\n")
        screensaver_source.write_bytes(b"updated saver\n")
        self.run_helper("branding-install", str(about_source), str(screensaver_source))
        self.assertEqual(
            (self.branding_state / "about.txt.backup").read_bytes(),
            b"original about\x00bytes",
        )

        self.run_helper("branding-restore")
        self.assertEqual((self.branding_dest / "about.txt").read_bytes(), b"original about\x00bytes")
        self.assertEqual((self.branding_dest / "screensaver.txt").read_bytes(), b"original saver\n")
        for name in (
            "managed",
            "about.txt.backup",
            "screensaver.txt.backup",
            "about.absent",
            "screensaver.absent",
        ):
            self.assertFalse((self.branding_state / name).exists())

    def test_branding_round_trip_removes_files_that_were_absent(self) -> None:
        about_source, screensaver_source = self.branding_sources()
        self.run_helper("branding-install", str(about_source), str(screensaver_source))
        self.assertTrue((self.branding_state / "about.absent").is_file())
        self.assertTrue((self.branding_state / "screensaver.absent").is_file())
        self.run_helper("branding-restore")
        self.assertFalse((self.branding_dest / "about.txt").exists())
        self.assertFalse((self.branding_dest / "screensaver.txt").exists())

    def test_welcome_marker_is_once_per_version(self) -> None:
        self.run_helper("welcome", "4.4.5")
        self.run_helper("welcome", "4.4.5")
        notifications = (self.home / "notifications").read_text(encoding="utf-8").splitlines()
        self.assertEqual(notifications.count("CONTROLLING INTEREST ACQUIRED"), 1)

    def test_fifo_prior_is_rejected_without_blocking(self) -> None:
        self.state.mkdir(parents=True)
        (self.state / "screensaver-managed").write_bytes(b"")
        os.mkfifo(self.state / "screensaver-prior")
        result = self.run_helper("default-disable", ok=False, timeout=1.0)
        self.assertIn("not a regular file", result.stderr)
        self.assertTrue((self.state / "screensaver-managed").is_file())

    def test_held_operation_lock_fails_within_a_bounded_time(self) -> None:
        self.state.mkdir(parents=True)
        lock_path = self.state / ".operation.lock"
        lock_fd = os.open(lock_path, os.O_RDWR | os.O_CREAT, 0o600)
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = self.run_helper("welcome", "4.4.5", ok=False, timeout=1.25)
            self.assertIn("did not release its lock", result.stderr)
        finally:
            os.close(lock_fd)
        self.assertFalse((self.state / "welcome-4.4.5").exists())

    def test_final_symlinks_are_rejected_and_external_file_is_unchanged(self) -> None:
        sentinel = self.case / "sentinel"
        sentinel.write_bytes(b"do not alter")

        self.state.mkdir(parents=True)
        (self.state / "screensaver-prior").symlink_to(sentinel)
        self.run_helper("default-enable", ok=False)
        self.assertEqual(sentinel.read_bytes(), b"do not alter")

        (self.state / "screensaver-prior").unlink()
        (self.state / "welcome-4.4.5").symlink_to(sentinel)
        self.run_helper("welcome", "4.4.5", ok=False)
        self.assertEqual(sentinel.read_bytes(), b"do not alter")

        (self.state / "screensaver-managed").symlink_to(sentinel)
        status = self.run_helper("default-status", ok=False)
        self.assertNotEqual(status.stdout.strip(), "yes")
        self.assertEqual(sentinel.read_bytes(), b"do not alter")

    def test_toggle_destination_symlink_is_rejected(self) -> None:
        sentinel = self.case / "sentinel"
        sentinel.write_bytes(b"toggle victim")
        self.toggles.mkdir(parents=True)
        (self.toggles / "screensaver-off").symlink_to(sentinel)
        self.run_helper("default-enable", ok=False)
        self.assertEqual(sentinel.read_bytes(), b"toggle victim")

    def test_branding_destination_and_backup_symlinks_are_rejected(self) -> None:
        about_source, screensaver_source = self.branding_sources()
        sentinel = self.case / "sentinel"
        sentinel.write_bytes(b"branding victim")
        self.branding_dest.mkdir(parents=True)
        (self.branding_dest / "about.txt").symlink_to(sentinel)
        self.run_helper("branding-install", str(about_source), str(screensaver_source), ok=False)
        self.assertEqual(sentinel.read_bytes(), b"branding victim")

        (self.branding_dest / "about.txt").unlink()
        self.branding_state.mkdir(parents=True, exist_ok=True)
        (self.branding_state / "managed").write_bytes(b"")
        (self.branding_state / "about.txt.backup").symlink_to(sentinel)
        self.run_helper("branding-restore", ok=False)
        self.assertEqual(sentinel.read_bytes(), b"branding victim")

    def test_branding_fifo_and_source_symlink_are_rejected_without_blocking(self) -> None:
        about_source, screensaver_source = self.branding_sources()
        self.branding_state.mkdir(parents=True)
        os.mkfifo(self.branding_state / "about.txt.backup")
        self.run_helper("branding-restore", ok=False, timeout=1.0)

        source_target = self.case / "source-target"
        source_target.write_bytes(b"not an approved source")
        about_source.unlink()
        about_source.symlink_to(source_target)
        self.run_helper("branding-install", str(about_source), str(screensaver_source), ok=False)

    def test_symlinked_parent_directory_is_rejected(self) -> None:
        external = self.case / "external"
        external.mkdir()
        local_state = self.home / ".local/state"
        local_state.mkdir(parents=True)
        (local_state / "oligarchy").symlink_to(external, target_is_directory=True)
        self.run_helper("default-enable", ok=False)
        self.assertEqual(list(external.iterdir()), [])

    def test_invalid_prior_value_and_temp_cleanup(self) -> None:
        self.state.mkdir(parents=True)
        (self.state / "screensaver-managed").write_bytes(b"")
        (self.state / "screensaver-prior").write_bytes(b"invented")
        self.run_helper("default-disable", ok=False)
        self.assertEqual((self.state / "screensaver-prior").read_bytes(), b"invented")
        self.assertFalse(list(self.home.rglob(".*.tmp-*")))


if __name__ == "__main__":
    unittest.main(verbosity=2)
