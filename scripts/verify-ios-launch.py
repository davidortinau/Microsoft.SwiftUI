#!/usr/bin/env python3
"""Check the compiled iOS app manifest, not only the source plist."""

import plistlib
import sys
from pathlib import Path


def verify(app: Path) -> None:
    source = Path(__file__).resolve().parents[1] / "samples/Microsoft.SwiftUI.Sample.iOS/Info.plist"
    with source.open("rb") as stream:
        expected = plistlib.load(stream)
    with (app / "Info.plist").open("rb") as stream:
        actual = plistlib.load(stream)

    for key in ("UILaunchStoryboardName", "UISupportedInterfaceOrientations",
                "UISupportedInterfaceOrientations~ipad"):
        if expected[key] != actual.get(key):
            raise ValueError(f"Compiled Info.plist has the wrong {key}: {actual.get(key)!r}")

    storyboard = app / f"{actual['UILaunchStoryboardName']}.storyboardc/Info.plist"
    if not storyboard.is_file():
        raise FileNotFoundError(f"Missing compiled launch storyboard: {storyboard}")
    print(f"Launch storyboard and orientations verified in {app}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: verify-ios-launch.py PATH/TO/Sample.iOS.app")
    verify(Path(sys.argv[1]))
