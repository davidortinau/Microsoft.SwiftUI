#!/usr/bin/env python3
"""Give generated Apple binding resources reproducible ZIP timestamps."""

import copy
import os
import struct
import sys
import tempfile
import time
import zipfile
from pathlib import Path


def fixed_extra(extra: bytes, epoch: int) -> bytes:
    result = bytearray()
    offset = 0
    while offset < len(extra):
        if len(extra) - offset < 4:
            raise ValueError("Truncated ZIP extra field")
        kind, size = struct.unpack_from("<HH", extra, offset)
        offset += 4
        field = extra[offset:offset + size]
        if len(field) != size:
            raise ValueError("Truncated ZIP extra field data")
        offset += size
        if kind == 0x5455:
            if len(field) < 5 or (len(field) - 1) % 4:
                raise ValueError("Invalid extended ZIP timestamp")
            field = field[:1] + epoch.to_bytes(4, "little") * ((len(field) - 1) // 4)
        result.extend(struct.pack("<HH", kind, len(field)))
        result.extend(field)
    return bytes(result)


def normalize(path: Path, epoch: int) -> None:
    timestamp = time.gmtime(epoch)[:6]
    with tempfile.NamedTemporaryFile(prefix=f".{path.name}.", suffix=".tmp",
                                     dir=path.parent, delete=False) as scratch:
        temporary = Path(scratch.name)
    try:
        with zipfile.ZipFile(path) as original, zipfile.ZipFile(temporary, "w") as rewritten:
            names = [entry.filename for entry in original.infolist()]
            if len(names) != len(set(names)) or names.count("manifest") != 1:
                raise ValueError(f"Invalid Apple binding resource entries: {path}")
            for entry in original.infolist():
                contents = original.read(entry)
                fixed = copy.copy(entry)
                fixed.date_time = timestamp
                fixed.extra = fixed_extra(entry.extra, epoch)
                rewritten.writestr(fixed, contents)
            rewritten.comment = original.comment
        os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: normalize-resource-zips.py IOS.resources.zip MACOS.resources.zip")
    value = os.environ.get("SOURCE_DATE_EPOCH", "")
    if not value.isdecimal():
        sys.exit("SOURCE_DATE_EPOCH must be a fixed nonnegative Unix timestamp.")
    epoch = int(value)
    if epoch > 0xffffffff or not 1980 <= time.gmtime(epoch).tm_year <= 2107:
        sys.exit("SOURCE_DATE_EPOCH must fit the ZIP timestamp range.")
    for argument in sys.argv[1:]:
        normalize(Path(argument), epoch)
