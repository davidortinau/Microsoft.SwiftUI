#!/usr/bin/env python3
"""Reject a macOS Debug shim linked to a different external Ailoha path."""

import os
import re
import subprocess
import sys
from pathlib import Path

EXPECTED_AGENT_LOAD = "@rpath/AilohaAgent.framework/Versions/A/AilohaAgent"
EXPECTED_ARCHITECTURES = {"arm64", "x86_64"}
RPATH = re.compile(
    r"(?m)^[ \t]*cmd LC_RPATH\n[ \t]*cmdsize \d+\n[ \t]*path (.+?) \(offset \d+\)$"
)


def otool(binary: Path, architecture: str, option: str) -> str:
    return subprocess.run(
        ["xcrun", "otool", "-arch", architecture, option, str(binary)],
        check=True, capture_output=True, text=True
    ).stdout


def verify(agent: Path, shim: Path) -> None:
    if not agent.is_absolute() or agent.name != "AilohaAgent.xcframework":
        raise ValueError("Select an absolute external AilohaAgent.xcframework path")
    if not shim.is_absolute():
        raise ValueError("Select an absolute AilohaDebugShim.xcframework path")
    binary = shim / "macos-arm64_x86_64/AilohaDebugShim.framework/AilohaDebugShim"
    if not binary.is_file():
        raise ValueError(f"Missing generated macOS Debug shim: {binary}")
    architectures = set(subprocess.run(
        ["xcrun", "lipo", "-archs", str(binary)],
        check=True, capture_output=True, text=True
    ).stdout.split())
    if architectures != EXPECTED_ARCHITECTURES:
        raise ValueError(f"Mac Debug shim architectures {architectures} do not match {EXPECTED_ARCHITECTURES}")

    allowed_rpaths = {"/usr/lib/swift", "@loader_path/../../..", str(agent / "macos-arm64_x86_64")}
    for architecture in sorted(EXPECTED_ARCHITECTURES):
        rpaths = RPATH.findall(otool(binary, architecture, "-l"))
        if len(rpaths) != len(allowed_rpaths) or set(rpaths) != allowed_rpaths:
            raise ValueError(
                f"{architecture} shim rpaths {rpaths} do not match selected Ailoha path "
                f"{agent}; rebuild with scripts/build-ailoha-debug.sh"
            )
        dependencies = [
            line.strip().split(" (", 1)[0]
            for line in otool(binary, architecture, "-L").splitlines()
            if "AilohaAgent.framework" in line
        ]
        if dependencies != [EXPECTED_AGENT_LOAD]:
            raise ValueError(f"{architecture} shim Ailoha load path is {dependencies}, expected {EXPECTED_AGENT_LOAD}")
    print(f"Ailoha macOS Debug shim verified: both architectures load {agent}")


if __name__ == "__main__":
    agent_path = os.environ.get("AILOHA_AGENT_XCFRAMEWORK")
    shim_path = os.environ.get("AILOHA_DEBUG_SHIM_XCFRAMEWORK")
    if not agent_path or not shim_path:
        sys.exit("Supply AILOHA_AGENT_XCFRAMEWORK and AILOHA_DEBUG_SHIM_XCFRAMEWORK.")
    try:
        verify(Path(agent_path), Path(shim_path))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"Ailoha macOS shim verification failed: {error}")
