#!/usr/bin/env python3
"""Fail if a Release sample bundle ships Ailoha or its Debug adapter."""

import io
import plistlib
import subprocess
import sys
import zipfile
from pathlib import Path

FORBIDDEN = ("ailohaagent", "ailohadebugshim", "sample.ailohadebugbinding")


def verify(app: Path) -> None:
    if not app.is_dir() or app.suffix != ".app":
        raise ValueError(f"Expected a built Release .app: {app}")
    nested = [path for path in app.rglob("*")
              if any(name in path.name.lower() for name in FORBIDDEN)]
    if nested:
        raise ValueError(f"Release app contains Ailoha files: {nested}")

    mac = (app / "Contents/Info.plist").is_file()
    manifest = app / ("Contents/Info.plist" if mac else "Info.plist")
    with manifest.open("rb") as stream:
        executable_name = plistlib.load(stream)["CFBundleExecutable"]
    executable = app / ("Contents/MacOS" if mac else "") / executable_name
    dependencies = subprocess.check_output(["otool", "-L", str(executable)], text=True)
    if any(name in dependencies.lower() for name in FORBIDDEN):
        raise ValueError(f"Release executable depends on Ailoha: {executable}")
    print(f"No Ailoha native or managed files in Release: {app}")


def verify_package(package: Path) -> None:
    with zipfile.ZipFile(package) as archive:
        for name in archive.namelist():
            if any(forbidden in name.lower() for forbidden in FORBIDDEN):
                raise ValueError(f"Reusable NuGet package includes Ailoha: {name}")
            if name.endswith(".resources.zip"):
                with zipfile.ZipFile(io.BytesIO(archive.read(name))) as native:
                    for member in native.namelist():
                        if any(forbidden in member.lower() for forbidden in FORBIDDEN):
                            raise ValueError(f"Reusable native resources include Ailoha: {member}")
                        if member.endswith("/MicrosoftSwiftUIShim") and b"ailoha" in native.read(member).lower():
                            raise ValueError(f"Reusable framework links Ailoha: {member}")
    print(f"No Ailoha binary or binding in reusable NuGet package: {package}")


if __name__ == "__main__":
    if len(sys.argv) not in (3, 4):
        sys.exit("Usage: verify-ailoha-release.py /path/to/iOS.app /path/to/macOS.app [library.nupkg]")
    for candidate in sys.argv[1:3]:
        verify(Path(candidate))
    if len(sys.argv) == 4:
        verify_package(Path(sys.argv[3]))
