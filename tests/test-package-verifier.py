#!/usr/bin/env python3
"""Exercise the package gate against copied, deliberately stale artifacts."""

import io
import os
import shutil
import stat
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = ET.parse(ROOT / "src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj").findtext("./PropertyGroup/Version")
NAME = f"Microsoft.SwiftUI.{VERSION}.nupkg"
VERIFIER = ROOT / "tests/Microsoft.SwiftUI.PackageVerifier/bin/Release/net11.0/Microsoft.SwiftUI.PackageVerifier.dll"


def copy_fixture(destination: Path) -> Path:
    native = destination / "native/MicrosoftSwiftUIShim"
    shutil.copytree(ROOT / "native/MicrosoftSwiftUIShim", native)
    generated = destination / ".build/native"
    generated.mkdir(parents=True)
    shutil.copytree(ROOT / ".build/native/MicrosoftSwiftUIShim.xcframework",
                    generated / "MicrosoftSwiftUIShim.xcframework", symlinks=True)
    shutil.copy2(ROOT / ".build/native/MicrosoftSwiftUIShim.provenance.txt", generated)
    project = destination / "src/Microsoft.SwiftUI"
    project.mkdir(parents=True)
    shutil.copy2(ROOT / "src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj", project)
    for name in ("README.md", "LICENSE", "docs/ATTRIBUTION.md"):
        source = ROOT / name
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    for tfm in ("net11.0-ios", "net11.0-macos"):
        built = project / "bin/Release" / tfm
        built.mkdir(parents=True)
        for extension in ("dll", "xml"):
            shutil.copy2(ROOT / "src/Microsoft.SwiftUI/bin/Release" / tfm /
                         f"Microsoft.SwiftUI.{extension}", built)
    artifacts = destination / "artifacts"
    artifacts.mkdir()
    shutil.copy2(ROOT / "artifacts" / NAME, artifacts)
    return artifacts / NAME


def rewrite_zip(archive: bytes, target: str, replacement: bytes | None = None,
                *, mode: int | None = None, host: int | None = None,
                remove: bool = False) -> bytes:
    result = io.BytesIO()
    with zipfile.ZipFile(io.BytesIO(archive)) as original, zipfile.ZipFile(result, "w") as modified:
        if target not in original.namelist():
            raise AssertionError(f"Missing mutation target: {target}")
        for entry in original.infolist():
            if entry.filename == target and remove:
                continue
            contents = replacement if entry.filename == target and replacement is not None else original.read(entry)
            if entry.filename == target and mode is not None:
                entry.external_attr = mode << 16
            if entry.filename == target and host is not None:
                entry.create_system = host
            modified.writestr(entry, contents)
    return result.getvalue()


def add_zip_entry(archive: bytes, name: str, contents: bytes) -> bytes:
    result = io.BytesIO()
    with zipfile.ZipFile(io.BytesIO(archive)) as original, zipfile.ZipFile(result, "w") as modified:
        for entry in original.infolist():
            modified.writestr(entry, original.read(entry))
        extra = zipfile.ZipInfo(name)
        extra.create_system = 3
        extra.external_attr = 0o100644 << 16
        modified.writestr(extra, contents)
    return result.getvalue()


def verify(package: Path, root: Path, expected: str, *, native_only: bool = False) -> None:
    arguments = ["--native-only", str(root)] if native_only else [str(package), str(root)]
    result = subprocess.run(["dotnet", str(VERIFIER), *arguments],
                            text=True, capture_output=True, check=False)
    output = result.stdout + result.stderr
    if expected:
        if result.returncode == 0 or expected not in output:
            raise AssertionError(f"Expected failure containing {expected!r}, got:\n{output}")
    elif result.returncode != 0:
        raise AssertionError(f"Intact package failed verification:\n{output}")
    print(f"PASS {expected or 'intact package'}")


def main() -> None:
    if not VERSION or not VERIFIER.is_file():
        raise ValueError("Build and pack the canonical package before running these tests.")
    with tempfile.TemporaryDirectory(prefix="package-verifier-test.", dir=ROOT / ".build") as scratch:
        fixture = Path(scratch)
        package = copy_fixture(fixture)
        original = package.read_bytes()
        verify(package, fixture, "")

        device_plist = ("ios-arm64/MicrosoftSwiftUIShim.framework/Info.plist")
        generated_plist = fixture / ".build/native/MicrosoftSwiftUIShim.xcframework" / device_plist
        generated_plist.unlink()
        verify(package, fixture, f"XCFramework inventory is missing an entry: {device_plist}")
        shutil.copy2(ROOT / ".build/native/MicrosoftSwiftUIShim.xcframework" / device_plist,
                     generated_plist)

        generated_plist.write_bytes(generated_plist.read_bytes() + b"\n")
        verify(package, fixture, f"Generated XCFramework file differs from inventory: {device_plist}")
        shutil.copy2(ROOT / ".build/native/MicrosoftSwiftUIShim.xcframework" / device_plist,
                     generated_plist)

        resources_link = (fixture / ".build/native/MicrosoftSwiftUIShim.xcframework" /
                          "macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Resources")
        recorded_mode = stat.S_IMODE(resources_link.lstat().st_mode)
        target_mode = stat.S_IMODE(resources_link.stat().st_mode)
        if recorded_mode == 0o600 or os.chmod not in os.supports_follow_symlinks:
            raise AssertionError("Cannot test macOS symlink mode without changing only the link.")
        os.chmod(resources_link, 0o600, follow_symlinks=False)
        if stat.S_IMODE(resources_link.stat().st_mode) != target_mode:
            raise AssertionError("Symlink mode mutation changed its target.")
        verify(package, fixture,
               "Generated XCFramework entry type or mode differs from inventory: "
               "macos-arm64_x86_64/MicrosoftSwiftUIShim.framework/Resources",
               native_only=True)
        os.chmod(resources_link, recorded_mode, follow_symlinks=False)
        verify(package, fixture, "", native_only=True)

        extra_module = generated_plist.parent / "Modules/module.modulemap"
        extra_module.parent.mkdir()
        extra_module.write_text("module Unexpected {}\n")
        verify(package, fixture, "Generated XCFramework has unrecorded entries")
        extra_module.unlink()
        extra_module.parent.rmdir()

        source = fixture / "native/MicrosoftSwiftUIShim/Sources/MicrosoftSwiftUIShim/Host.iOS.swift"
        source.write_bytes(source.read_bytes() + b"\n")
        verify(package, fixture, "Native source changed")
        source.write_bytes((ROOT / "native/MicrosoftSwiftUIShim/Sources/MicrosoftSwiftUIShim/Host.iOS.swift").read_bytes())

        with zipfile.ZipFile(io.BytesIO(original)) as archive:
            resource = next(name for name in archive.namelist()
                            if name.startswith("lib/net11.0-ios") and name.endswith(".resources.zip"))
            resource_bytes = archive.read(resource)
            nuspec = archive.read("Microsoft.SwiftUI.nuspec")
        binary = ("MicrosoftSwiftUIShim.xcframework/ios-arm64/"
                  "MicrosoftSwiftUIShim.framework/MicrosoftSwiftUIShim")
        plist = "MicrosoftSwiftUIShim.xcframework/" + device_plist
        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, plist, remove=True)))
        verify(package, fixture, "package is missing generated framework entries")

        with zipfile.ZipFile(io.BytesIO(resource_bytes)) as native_archive:
            contents = native_archive.read(binary)
        changed_native = rewrite_zip(resource_bytes, binary,
                                     contents[:-1] + bytes([contents[-1] ^ 1]))
        package.write_bytes(rewrite_zip(original, resource, changed_native))
        verify(package, fixture, "packaged native file differs")

        mac_resources = ("MicrosoftSwiftUIShim.xcframework/macos-arm64_x86_64/"
                         "MicrosoftSwiftUIShim.framework/Resources")
        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, mac_resources, mode=0o100644)))
        verify(package, fixture, "ZIP entry type/attributes differ from generated framework")

        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, mac_resources, mode=0o120600)))
        verify(package, fixture, "ZIP entry type/attributes differ from generated framework")

        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, mac_resources, host=0)))
        verify(package, fixture, "ZIP entry host is not Unix")

        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, mac_resources,
                                        b"Versions/A/Resources")))
        verify(package, fixture, "packaged native symlink target differs")

        with zipfile.ZipFile(io.BytesIO(resource_bytes)) as archive:
            manifest = archive.read("manifest")
        for field, invalid in (
            ("ForceLoad", "Invalid"),
            ("Frameworks", "Invalid"),
            ("IdentityWithoutPathSeparatorSuffix", "../other.xcframework"),
            ("IsCxx", "Invalid"),
            ("Kind", "Invalid"),
            ("LinkerFlags", "Invalid"),
            ("LinkWithSwiftSystemLibraries", "Invalid"),
            ("NeedsGccExceptionHandling", "Invalid"),
            ("SmartLink", "true"),
            ("WeakFrameworks", "Invalid"),
        ):
            document = ET.fromstring(manifest)
            document.find(f"./NativeReference/{field}").text = invalid
            corrupted = rewrite_zip(resource_bytes, "manifest", ET.tostring(document))
            package.write_bytes(rewrite_zip(original, resource, corrupted))
            verify(package, fixture, f"manifest {field} differs")

        namespaced_kind = manifest.replace(
            b"<Kind>Framework</Kind>",
            b'<unexpected:Kind xmlns:unexpected="urn:unexpected">Framework</unexpected:Kind>')
        if namespaced_kind == manifest:
            raise AssertionError("Manifest Kind field was not present for the namespace test.")
        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, "manifest", namespaced_kind)))
        verify(package, fixture, "manifest has missing or unexpected fields")

        for mutation in ("missing", "duplicate"):
            document = ET.fromstring(manifest)
            native = document.find("./NativeReference")
            if mutation == "missing":
                native.remove(native.find("Kind"))
            else:
                ET.SubElement(native, "Kind").text = "Framework"
            package.write_bytes(rewrite_zip(original, resource,
                                rewrite_zip(resource_bytes, "manifest", ET.tostring(document))))
            verify(package, fixture, "manifest has missing or unexpected fields")

        document = ET.fromstring(manifest)
        kind = document.find("./NativeReference/Kind")
        kind.clear()
        ET.SubElement(kind, "Value").text = "Framework"
        package.write_bytes(rewrite_zip(original, resource,
                            rewrite_zip(resource_bytes, "manifest", ET.tostring(document))))
        verify(package, fixture, "manifest Kind differs")

        document = ET.fromstring(nuspec)
        groups = [group for group in document.iter() if group.tag.endswith("group")]
        groups[0].set("targetFramework", "net11.0-maccatalyst26.5")
        package.write_bytes(rewrite_zip(original, "Microsoft.SwiftUI.nuspec",
                                        ET.tostring(document)))
        verify(package, fixture, "dependency groups are missing or duplicate")

        document = ET.fromstring(nuspec)
        group = next(group for group in document.iter() if group.tag.endswith("group"))
        group.set("targetFramework", "net11.0-ios27.0")
        changed_nuspec = rewrite_zip(original, "Microsoft.SwiftUI.nuspec", ET.tostring(document))
        renamed = io.BytesIO()
        with zipfile.ZipFile(io.BytesIO(changed_nuspec)) as archive, zipfile.ZipFile(renamed, "w") as modified:
            for entry in archive.infolist():
                contents = archive.read(entry)
                entry.filename = entry.filename.replace("lib/net11.0-ios26.5/",
                                                        "lib/net11.0-ios27.0/", 1)
                modified.writestr(entry, contents)
        package.write_bytes(renamed.getvalue())
        verify(package, fixture, "dependency groups are missing or duplicate")

        document = ET.fromstring(nuspec)
        group = next(group for group in document.iter() if group.tag.endswith("group"))
        namespace = document.tag.partition("}")[0] + "}"
        ET.SubElement(group, namespace + "dependency",
                      id="Microsoft.Maui.Controls", version="11.0.0")
        package.write_bytes(rewrite_zip(original, "Microsoft.SwiftUI.nuspec",
                                        ET.tostring(document)))
        verify(package, fixture, "NuGet dependency groups must be empty")

        for name in ("build/Microsoft.SwiftUI.targets",
                     "buildTransitive/Microsoft.SwiftUI.targets",
                     "analyzers/dotnet/cs/Injected.dll",
                     "contentFiles/any/any/injected.txt",
                     "tools/injected.sh",
                     "unexpected/injected.txt"):
            package.write_bytes(add_zip_entry(original, name, b"unexpected payload"))
            verify(package, fixture, "NuGet package entries differ from the approved payload")

        with zipfile.ZipFile(io.BytesIO(original)) as archive:
            documentation = next(name for name in archive.namelist()
                                 if name.startswith("lib/net11.0-ios") and name.endswith(".xml"))
        package.write_bytes(rewrite_zip(original, documentation, remove=True))
        verify(package, fixture, "Expected exactly one net11.0-ios XML documentation file")

        with zipfile.ZipFile(io.BytesIO(original)) as archive:
            readme = archive.read("README.md")
        package.write_bytes(rewrite_zip(original, "README.md", readme + b"\n"))
        verify(package, fixture, "NuGet document differs from the repository: README.md")

        assembly = fixture / "src/Microsoft.SwiftUI/bin/Release/net11.0-ios/Microsoft.SwiftUI.dll"
        modified_assembly = assembly.read_bytes().replace(b"DetachController", b"AttachController")
        if modified_assembly == assembly.read_bytes():
            raise AssertionError("Managed method name was not present in the assembly metadata.")
        assembly.write_bytes(modified_assembly)
        with zipfile.ZipFile(io.BytesIO(original)) as archive:
            library = next(name for name in archive.namelist()
                           if name.startswith("lib/net11.0-ios") and name.endswith("/Microsoft.SwiftUI.dll"))
        package.write_bytes(rewrite_zip(original, library, modified_assembly))
        verify(package, fixture, "lacks public static SwiftUIHost.DetachController")


if __name__ == "__main__":
    main()
