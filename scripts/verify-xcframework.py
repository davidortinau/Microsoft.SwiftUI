#!/usr/bin/env python3
"""Verify each Apple variant and its actual Mach-O architectures."""

import plistlib
import subprocess
import sys
from pathlib import Path

REQUIRED = {
    ("ios", ""): {"arm64"},
    ("ios", "simulator"): {"arm64", "x86_64"},
    ("macos", ""): {"arm64", "x86_64"},
}
SLICE_PLATFORMS = {
    ("ios", ""): "iPhoneOS",
    ("ios", "simulator"): "iPhoneSimulator",
    ("macos", ""): "MacOSX",
}


def verify(path: Path, binary_name: str = "MicrosoftSwiftUIShim") -> None:
    if not binary_name.isidentifier():
        raise ValueError(f"Invalid framework binary name: {binary_name}")
    with (path / "Info.plist").open("rb") as stream:
        libraries = plistlib.load(stream)["AvailableLibraries"]

    found = {}
    for library in libraries:
        platform = library["SupportedPlatform"]
        variant = library.get("SupportedPlatformVariant", "")
        key = (platform, variant)
        identifier = library["LibraryIdentifier"]
        framework = path / identifier / library["LibraryPath"]
        executable = path / identifier / library["BinaryPath"]
        if key in found or not executable.is_file():
            raise ValueError(f"Duplicate or missing framework binary: {identifier}")
        if key not in REQUIRED or library["LibraryPath"] != f"{binary_name}.framework":
            raise ValueError(f"Unexpected framework slice: {identifier}")
        info = framework / "Resources/Info.plist" if platform == "macos" else framework / "Info.plist"
        with info.open("rb") as stream:
            slice_info = plistlib.load(stream)
        supported = slice_info.get("CFBundleSupportedPlatforms")
        if (slice_info.get("CFBundleExecutable") != binary_name or
                slice_info.get("CFBundlePackageType") != "FMWK" or
                (supported is not None and supported != [SLICE_PLATFORMS[key]]) or
                (binary_name == "MicrosoftSwiftUIShim" and supported is None)):
            raise ValueError(f"Invalid per-slice Info.plist: {info}")
        if headers := library.get("HeadersPath"):
            header_dir = path / identifier / headers
            if not header_dir.is_dir() or not any(header_dir.rglob("*.h")):
                raise ValueError(f"Missing required XCFramework headers: {identifier}/{headers}")
        declared = set(library["SupportedArchitectures"])
        actual = set(
            subprocess.check_output(["xcrun", "lipo", "-archs", str(executable)], text=True)
            .strip()
            .split()
        )
        if declared != actual:
            raise ValueError(f"{identifier}: plist {declared} differs from binary {actual}")
        found[key] = actual
        print(f"{identifier}: {', '.join(sorted(actual))}")

    if found != REQUIRED:
        raise ValueError(f"Expected {REQUIRED}, got {found}")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        sys.exit("Usage: verify-xcframework.py PATH/TO/FRAMEWORK.xcframework [BinaryName]")
    verify(Path(sys.argv[1]), sys.argv[2] if len(sys.argv) == 3 else "MicrosoftSwiftUIShim")
