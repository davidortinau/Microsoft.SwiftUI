#!/usr/bin/env python3
"""Verify an external Ailoha release before using it in Debug sample builds."""

import hashlib
import os
import plistlib
import sys
import zipfile
from pathlib import Path, PurePosixPath

EXPECTED_SHA256 = "7c61cc0705afd160910c962d56afa576550b60de464a4d79722514d622ec710f"
REQUIRED_SLICES = {
    ("ios", ""): {"arm64"},
    ("ios", "simulator"): {"arm64", "x86_64"},
    ("macos", ""): {"arm64", "x86_64"},
}


def verify(framework: Path) -> None:
    if not framework.is_absolute() or framework.name != "AilohaAgent.xcframework" or not framework.is_dir():
        raise ValueError("Expected an external AilohaAgent.xcframework directory")
    archive_path = framework.with_name("AilohaAgent.xcframework.zip")
    actual_hash = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    if actual_hash != EXPECTED_SHA256:
        raise ValueError(f"Ailoha v0.1.13 archive SHA-256 mismatch: {actual_hash}")
    for extension in (".sha256", ".checksum"):
        sidecar = archive_path.with_name(archive_path.name + extension)
        if sidecar.read_text().split()[0].lower() != EXPECTED_SHA256:
            raise ValueError(f"Ailoha checksum sidecar mismatch: {sidecar}")

    with zipfile.ZipFile(archive_path) as archive:
        if invalid := archive.testzip():
            raise ValueError(f"Damaged Ailoha archive entry: {invalid}")
        entries = {}
        for item in archive.infolist():
            parts = PurePosixPath(item.filename).parts
            if not parts or parts[0] == "__MACOSX" or item.is_dir():
                continue
            if ".." in parts or "AilohaAgent.xcframework" not in parts:
                raise ValueError(f"Unexpected path in Ailoha archive: {item.filename}")
            relative = Path(*parts[parts.index("AilohaAgent.xcframework") + 1:])
            if relative in entries:
                raise ValueError(f"Duplicate Ailoha archive entry: {relative}")
            entries[relative] = item

        verified = set()
        for item in framework.rglob("*"):
            if item.is_dir() and not item.is_symlink():
                continue
            relative = item.relative_to(framework)
            if relative not in entries:
                raise ValueError(f"Unrecognized file in extracted Ailoha artifact: {relative}")
            contents = archive.read(entries[relative])
            if item.is_symlink():
                if not item.resolve().is_relative_to(framework.resolve()):
                    raise ValueError(f"Ailoha artifact symlink escapes the framework: {relative}")
                if item.readlink().as_posix().encode() != contents:
                    raise ValueError(f"Ailoha artifact symlink mismatch: {relative}")
            elif not item.is_file() or hashlib.sha256(item.read_bytes()).digest() != hashlib.sha256(contents).digest():
                raise ValueError(f"Ailoha extracted file differs from official ZIP: {relative}")
            verified.add(relative)
        if verified != entries.keys():
            raise ValueError(f"Missing files from extracted Ailoha artifact: {entries.keys() - verified}")

    with (framework / "Info.plist").open("rb") as stream:
        libraries = plistlib.load(stream)["AvailableLibraries"]
    slices = {
        (entry["SupportedPlatform"], entry.get("SupportedPlatformVariant", "")):
        set(entry["SupportedArchitectures"])
        for entry in libraries
    }
    for platform, architectures in REQUIRED_SLICES.items():
        if slices.get(platform) != architectures:
            raise ValueError(f"Missing or incorrect Ailoha {platform} slice: {slices.get(platform)}")
    print(f"Ailoha v0.1.13 verified: ZIP SHA-256 {actual_hash}, {len(verified)} files, required slices")


if __name__ == "__main__":
    if len(sys.argv) > 2:
        sys.exit("Usage: verify-ailoha-input.py [/external/path/AilohaAgent.xcframework]")
    agent = sys.argv[1] if len(sys.argv) == 2 else os.environ.get("AILOHA_AGENT_XCFRAMEWORK")
    if not agent:
        sys.exit("Supply an absolute XCFramework argument or AILOHA_AGENT_XCFRAMEWORK.")
    try:
        verify(Path(agent))
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        sys.exit(f"Ailoha input verification failed: {error}")
