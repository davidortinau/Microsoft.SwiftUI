#!/usr/bin/env python3
"""Record every XCFramework directory, regular file, and symlink at build time."""

import hashlib
import json
import stat
import sys
from pathlib import Path


def inventory(framework: Path) -> dict:
    root = framework.resolve(strict=True)
    if not stat.S_ISDIR(framework.lstat().st_mode):
        raise ValueError(f"Not an XCFramework directory: {framework}")
    entries = []

    def collect(path: Path) -> None:
        status = path.lstat()
        entry = {
            "path": path.relative_to(framework).as_posix()
            if path != framework else "",
            "mode": stat.S_IMODE(status.st_mode),
        }
        if stat.S_ISLNK(status.st_mode):
            target = path.readlink().as_posix()
            if not path.resolve(strict=True).is_relative_to(root):
                raise ValueError(f"XCFramework symlink escapes its root: {path}")
            entry.update(kind="symlink", target=target)
        elif stat.S_ISDIR(status.st_mode):
            entry["kind"] = "directory"
        elif stat.S_ISREG(status.st_mode):
            entry.update(kind="file", sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        else:
            raise ValueError(f"Unsupported XCFramework entry: {path}")
        entries.append(entry)
        if entry["kind"] == "directory":
            for child in sorted(path.iterdir()):
                collect(child)

    collect(framework)
    return {"version": 1, "entries": entries}


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: inventory-xcframework.py PATH/TO/FRAMEWORK.xcframework")
    print(json.dumps(inventory(Path(sys.argv[1])), sort_keys=True, separators=(",", ":")))
