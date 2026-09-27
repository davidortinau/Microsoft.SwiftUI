# Builds and generated artifact provenance

The `native/MicrosoftSwiftUIShim` Swift package builds from source, not from
the prebuilt binary in the pinned `maui-labs` commit. The build script archives
three framework variants with `SKIP_INSTALL=NO`,
`BUILD_LIBRARY_FOR_DISTRIBUTION=YES`, and `CODE_SIGNING_ALLOWED=NO`, then invokes
`xcodebuild -create-xcframework`. The required variants are iOS arm64 device,
iOS arm64/x86_64 simulator, and macOS arm64/x86_64. Verification checks both
the XCFramework's Info.plist, each slice's Info.plist, any declared header
path, and each Mach-O binary with `lipo`.

Run `bash scripts/build-xcframework.sh` from this repository. Its ignored
outputs are `.build/native/MicrosoftSwiftUIShim.xcframework` and
`.build/native/MicrosoftSwiftUIShim.provenance.txt`. The provenance file
records the UTC generation time, pinned source reference, Xcode and Swift
versions, SHA-256 of package sources and the generated Info.plist and binaries,
and a JSON inventory of every regular file, symlink, and directory. The
inventory records file hashes and Unix modes, symlink modes and exact targets,
and directory modes. It covers both iOS slice plists, the macOS versioned
Resources plist and symlinks, plus any headers, module maps, resources, or
signature files the build emits. Packing requires an exact match to this
build-time inventory, including entries that did not appear in the older
top-level plist/binary hash list.

Each run uses a fresh archive directory under `.build/native`; an existing
XCFramework and its provenance are moved to timestamped sibling paths, never
silently overwritten. Only the unique archive directory created by that run
is removed after success; a failed run preserves its scratch for diagnosis.
The script hashes every Swift source before and after archiving and refuses
to publish a build if sources change during the run. Do not check generated
binaries into Git.

The binding project's `NativeReference` embeds the generated framework as an
Apple binding resource. `dotnet pack` includes it in the NuGet package per
target framework, with each assembly's XML documentation, this repository's
MIT metadata, README, and `docs/ATTRIBUTION.md`. The upstream `maui-labs`
notice is included with each package; no upstream binary or application
backend is packaged. The binding emits XML documentation for both targets;
CS1591 is suppressed because generated binding declarations lack XML comments.
The canonical package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.3.nupkg` (SHA-256
`6537f3c8f8004ff0d256a61678247a248ff6e093ea135a53e3196c9c1037698d`,
412178 bytes; last rebuilt September 27, 2026, 06:48:40 UTC).
Preview.2 artifacts already existed. Preview.3 had never been pushed or
published, so its earlier bytes were backed up at
`.build/package-history/Microsoft.SwiftUI.0.1.0-preview.3.before-final-hardening-20260927T064144Z.nupkg`
before rebuilding the same public version. Restore it using a new isolated
NuGet cache, not the old preview.3 cache.

Use `scripts/pack-and-verify.sh`, not a standalone incremental `dotnet pack`:
it verifies that the native framework's source and binary hashes match its
build provenance, checks each native binary for `deactivateHost:`, snapshots
the managed sources, rebuilds both Release bindings, packs them without
rebuilding, and refuses a managed-source change during the build. The
package verifier reads both assemblies' metadata for the public
`DetachController` (and macOS `DetachView`) methods and the generated
`MSUBridge.DeactivateHost` binding, including their parameter and return
types. It compares each packaged assembly
byte-for-byte to its rebuilt Release output, and every file, symlink, and
directory in **each** packaged iOS/macOS native resource to the build
inventory. It checks ZIP entry types, Unix host/external attributes, directory
structure, and symlink targets. It reads each symlink's own mode without
following the target, compares it with the build inventory, then checks the
packaged ZIP attributes against that measured mode. The binding manifest must
have exactly one unqualified `NativeReference` with each of its ten required
unqualified fields exactly once and with the expected value; namespaced
substitutes such as a qualified `Kind` are rejected. Both nuspec dependency
groups must be empty. An exact 13-entry allowlist permits only NuGet's three
container metadata files, the nuspec, README, LICENSE, attribution, and each
platform's DLL, XML documentation, and native resource ZIP; unexpected
`build`, `buildTransitive`, analyzer, content, tool, or other entries fail.
The platform group and lib paths are pinned to the verified Preview 7
`net11.0-ios26.5` and `net11.0-macos26.5` outputs; a toolchain change
requires an explicit allowlist review.
The verification fails on stale or source-divergent artifacts, not merely
on missing paths. `tests/test-build-scratch-cleanup.sh` injects failures
to check both build scripts retain failed-run scratch; its successful
native/Ailoha builds confirm each cleans only its own new scratch.
The separately built, externally sourced Ailoha agent is
[sample Debug instrumentation](ailoha-debug.md), not an input to this
XCFramework or NuGet package.

`build-xcframework.sh` sorts the root plist's `AvailableLibraries` before
recording provenance: Xcode emitted identical slices in different array
orders on two same-input builds. The canonicalized plist and all 20 native
inventory entries then matched across two further builds.
`pack-and-verify.sh` fixes `SOURCE_DATE_EPOCH=1790475928` (September 27,
2026, 02:25:28 UTC) for the outer NuGet ZIP. The Apple binding task still
stamps its inner `manifest` with the current time, so the script normalizes
both generated `.resources.zip` archives to that epoch while preserving
every payload, Unix external attribute, and symlink target. Two fresh
Release rebuilds and packs from unchanged inputs on the installed
Preview 7 toolchain produced byte-identical preview.3 packages. The
ignored provenance's generation time is intentionally not fixed;
different source content, Xcode/.NET toolchains, or package metadata can
change the package hash and require new verification.
For the final hardening, the framework provenance was generated at
2026-09-27T06:40:56Z with 20 inventory entries (7 files, 3 symlinks,
10 directories). Four consecutive verified packages, including the final
two packed between 2026-09-27T06:48:33Z and 06:48:41Z, were byte-identical.
The verifier passed 37 deliberately corrupted copies and two intact checks.
Logs, the four package hashes, and fresh-consumer evidence are in
`.build/evidence/final-hardening.tYTOEJ/`.

Before running any `dotnet` command in a new checkout, inspect in this order:

```bash
find . -maxdepth 4 -name global.json -print
dotnet --list-sdks
dotnet --info | head -20
dotnet workload list
```

Then run:

```bash
swift test --package-path native/MicrosoftSwiftUIShim --scratch-path .build/swiftpm
bash scripts/build-xcframework.sh
dotnet build src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj -f net11.0-macos
dotnet build src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj -f net11.0-ios -p:RuntimeIdentifier=iossimulator-arm64
dotnet build src/Microsoft.SwiftUI/Microsoft.SwiftUI.csproj -f net11.0-ios -p:RuntimeIdentifier=ios-arm64
dotnet build samples/Microsoft.SwiftUI.Sample.MacOS/Microsoft.SwiftUI.Sample.MacOS.csproj -f net11.0-macos
dotnet build samples/Microsoft.SwiftUI.Sample.iOS/Microsoft.SwiftUI.Sample.iOS.csproj -f net11.0-ios -p:RuntimeIdentifier=iossimulator-arm64
python3 scripts/verify-ios-launch.py samples/Microsoft.SwiftUI.Sample.iOS/bin/Debug/net11.0-ios/iossimulator-arm64/Microsoft.SwiftUI.Sample.iOS.app
dotnet build tests/Microsoft.SwiftUI.Tests/Microsoft.SwiftUI.Tests.csproj -f net11.0-macos
tests/Microsoft.SwiftUI.Tests/bin/Debug/net11.0-macos/osx-arm64/Microsoft.SwiftUI.Tests.app/Contents/MacOS/Microsoft.SwiftUI.Tests
bash scripts/pack-and-verify.sh
python3 tests/test-package-verifier.py
```

Before packing, run
`bash tests/test-build-scratch-cleanup.sh "$AILOHA_AGENT_XCFRAMEWORK"`
when the externally verified official Ailoha agent is available. It performs
real native and Debug-shim builds and checks each script's success/failure
scratch behavior. Rerun `pack-and-verify.sh` after the scratch test to check
the newly generated framework and canonical package together.

On this machine the binding tool requires the already-installed Preview 7
SDK. Run the last command from its ignored pinned directory so SDK selection
remains compatible without altering the machine or repository defaults:

```bash
(cd .build/sdk-preview7 && bash ../../scripts/pack-and-verify.sh)
```

To audit an existing package without rebuilding, run
`(cd .build/sdk-preview7 && dotnet run --project ../../tests/Microsoft.SwiftUI.PackageVerifier -c Release -- ../../artifacts/Microsoft.SwiftUI.0.1.0-preview.3.nupkg ../..)`
from the repository root. This checks package/native provenance and byte
parity with the most recent Release binding outputs; only
`pack-and-verify.sh` also forces a fresh managed rebuild.

The managed test project is a self-contained native macOS executable with no
test-framework package dependency. Run its `.app` executable directly to
capture assertions and the process exit code; `dotnet run` can report a
successful app launch without forwarding the app's assertion output.

The iOS sample uses `LaunchScreen.storyboard` with
`UILaunchStoryboardName=LaunchScreen`. Its project also includes the primary
`Info.plist` as a non-overwriting `PartialAppManifest` input: in the installed
Preview 7 Apple SDK, `_CompileAppManifestInputs` tracks partial plist files
but not edits to the primary plist. Before that input was declared, the
source launch key and orientations were present while the compiled `.app`
manifest silently retained an older version without either key. Always run
`verify-ios-launch.py` on the **built** `.app`, not just `plutil -lint` on the
source plist.

## Local toolchain qualification (September 27, 2026 UTC)

Xcode 26.6 and Apple Swift 6.3.3 produced and verified all three slices.
The installed .NET SDK `11.0.100-rc.1.26425.128` builds stock iOS simulator
and macOS apps, but the matching Apple binding tool's `bgen.runtimeconfig.json`
requests `Microsoft.NETCore.App 11.0.0-rc.1.26426.105`, while the installed
runtime is `11.0.0-rc.1.26425.128`. Binding builds stop with exit code 150.
No SDK, runtime, or workload was installed or changed.

The *already installed* SDK `11.0.100-preview.7.26381.103`, its installed
Apple workload `26.5.11997-net11-p7`, and its matching runtime successfully
build the binding and the consumers on this machine. To reproduce this
qualification without changing the checkout's default SDK, create an
**ignored** `.build/sdk-preview7/global.json` with the installed SDK version,
`"rollForward": "disable"`, and `"allowPrerelease": true`, repeat the four
diagnostics from that directory, then run the build commands there with
absolute project paths. This is a per-invocation selection of an existing
installation, not a change to installed SDKs or workloads. The default RC
binding path remains externally blocked until a compatible tool/runtime pair
is supplied.

Independent apps with an isolated local `PackageReference` to the generated NuGet
package built for macOS and iOS simulator in Debug and Release. The macOS
consumer instantiated `NSHostingView` and invoked a managed action through
the packaged Objective-C block in both Debug and a **fresh, locally ad-hoc
signed Release** build. An unsigned Release build was rejected by macOS with
`SIGKILL (Code Signature Invalid)` and `CODESIGNING: Invalid Page`; `codesign
--verify --deep --strict` also failed. For local Release testing supply
`-p:CodesignKey=-` on a fresh build output and verify the `.app` signature
before launch. Reusing the unsigned output with a newly supplied signing key
did not fix its stale signing state. Production distribution needs an
appropriate Apple identity; an ad-hoc signature is for local testing only.

The iOS simulator consumer builds without a provisioning profile. A device
**app** build with `-p:RuntimeIdentifier=ios-arm64 -p:CodesignKey=-` fails
`MT7139` for the generated `application-identifier` and
`keychain-access-groups` entitlements until an Apple provisioning profile is
specified. The iOS device **framework** slice and binding build successfully;
no physical-device installation or simulator reset was attempted.
