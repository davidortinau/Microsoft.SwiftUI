# Optional Ailoha agent in Debug sample hosts

This is **sample-only instrumentation**, not a Microsoft.SwiftUI library
dependency. Ailoha's official `Redth/ailoha-releases` v0.1.13 ZIP has
SHA-256 `7c61cc0705afd160910c962d56afa576550b60de464a4d79722514d622ec710f`,
matching the published Swift package manifest and sidecars. Run
`scripts/verify-ailoha-input.py` against an **external** extracted
`AilohaAgent.xcframework` with its ZIP and sidecars beside it; the script
compares all extracted files and required iOS/macOS slices. Neither the
official ZIP nor its XCFramework belongs in Git, the reusable NuGet package,
or a Release bundle. Every opted-in Debug sample build runs the complete extracted-XCFramework
verifier, including all files, symlinks, checksum sidecars, and required
slices, even when the binding is already up to date. The Debug binding also
checks the official ZIP SHA-256 with MSBuild's `VerifyFileHash` on each build.
A missing or mismatched input fails instead of selecting an unverified agent.

The [Ailoha Binary Distribution License](https://github.com/Redth/ailoha-releases/blob/v0.1.13/LICENSE)
is custom and **not** MIT or open source. It permits use of an unmodified
official binary package within applications, but restricts modified and
standalone redistribution, source distribution, and reverse engineering.
This repository contains only its own small adapter source. The locally
generated Debug shim and its source/binary hashes live in ignored
`.build/ailoha-debug/`; the official binary stays at the externally supplied
path. Do not distribute a Debug sample bundle as an Ailoha package.

## Build and prove the boundary

First follow the [ordered SDK diagnostics](build-and-provenance.md) and select
an already installed compatible .NET SDK. Then, from this repository:

```bash
export AILOHA_AGENT_XCFRAMEWORK=/absolute/external/path/AilohaAgent.xcframework
python3 scripts/verify-ailoha-input.py "$AILOHA_AGENT_XCFRAMEWORK"
bash scripts/build-ailoha-debug.sh "$AILOHA_AGENT_XCFRAMEWORK"
dotnet build samples/Microsoft.SwiftUI.Sample.iOS/Microsoft.SwiftUI.Sample.iOS.csproj -c Debug -f net11.0-ios -p:RuntimeIdentifier=iossimulator-arm64 -p:AilohaAgentXCFramework="$AILOHA_AGENT_XCFRAMEWORK"
dotnet build samples/Microsoft.SwiftUI.Sample.MacOS/Microsoft.SwiftUI.Sample.MacOS.csproj -c Debug -f net11.0-macos -p:AilohaAgentXCFramework="$AILOHA_AGENT_XCFRAMEWORK"
dotnet build samples/Microsoft.SwiftUI.Sample.iOS/Microsoft.SwiftUI.Sample.iOS.csproj -c Release -f net11.0-ios -p:RuntimeIdentifier=iossimulator-arm64 -p:AilohaAgentXCFramework="$AILOHA_AGENT_XCFRAMEWORK"
dotnet build samples/Microsoft.SwiftUI.Sample.MacOS/Microsoft.SwiftUI.Sample.MacOS.csproj -c Release -f net11.0-macos -p:RuntimeIdentifier=osx-arm64 -p:CodesignKey=- -p:AilohaAgentXCFramework="$AILOHA_AGENT_XCFRAMEWORK"
python3 scripts/verify-ailoha-release.py samples/Microsoft.SwiftUI.Sample.iOS/bin/Release/net11.0-ios/iossimulator-arm64/Microsoft.SwiftUI.Sample.iOS.app samples/Microsoft.SwiftUI.Sample.MacOS/bin/Release/net11.0-macos/osx-arm64/Microsoft.SwiftUI.Sample.MacOS.app artifacts/Microsoft.SwiftUI.0.1.0-preview.3.nupkg
```

Setting `AilohaAgentXCFramework` opts into the Debug project reference and
native shim. Missing inputs fail the Debug build explicitly. Without that
property, the samples retain their ordinary dependency-free Debug path.
Passing the property in Release is intentionally ineffective. The iOS Debug
bundle embeds the verified official framework; native macOS Debug cannot
embed the supplied macOS slice because the original framework fails
`codesign --verify` and its root `Modules` directory is rejected as unsealed
content. Rather than repack or alter the licensed binary, the Mac Debug shim
links to the verified **external** framework path at runtime. The macOS Debug
build checks both architectures of the generated shim's load commands and
fails if its embedded rpath differs from the selected agent; rerun
`scripts/build-ailoha-debug.sh` after changing that path. It works only while
that exact local path exists. Both Release bundles exclude the agent, the
sample binding, and the shim.

## CLI evidence and remaining limit

The locally installed Ailoha CLI reports `0.1.10-preview.1`; the verified
agent binary is from release `v0.1.13`. The broker first discovered the iOS
sample on port 9233 and native Mac sample on port 9234. After a relaunch in
the same session, those ports swapped. **Never reuse a remembered port**:
match the exact `packageId` in `ailoha agent list --json` immediately before
each action and pass its current port. Confirm an iOS tree begins at
`UIWindow` and a macOS tree at `NSHostingView`; `--platform ios` does not
correct a port aimed at a different app.

```bash
ailoha ui tree --platform ios --agent-port <ios-port> --depth 0 --json
ailoha ui fill --automationId sample.name Navigator --platform ios --agent-port <ios-port> --json
ailoha ui tree --agent-port <mac-port> --depth 0 --json
ailoha ui fill --automationId sample.name Skipper --agent-port <mac-port> --json
```

Both trees expose the real native text input as `tid:sample.name`. Filling
by that stable ID changed an earlier iOS input and shared C# greeting to
`Hello, Navigator`. The full simulator screenshot after the action is
`.build/evidence/ailoha-ios-final-clean-input.png` (1206x2622, SHA-256
`e79b3500ce4c832cfdcbf2d7936fd5325a70df853b114b9b81aca0ac2e69c792`).
On macOS the input value became `Skipper`. The captures
`.build/evidence/ailoha-macos-sdkroot-before.png` (SHA-256
`d5322f79235aef449a268925959598b85b32796812944fb5f332e710ffdddc5a`)
and `.build/evidence/ailoha-macos-sdkroot-after.png` (SHA-256
`34373cdcdf93564aae6d5879cc3e2ec80e49e7d9b150f4cc50bb81b11b1c9317`)
show the native field changing, but the agent's screenshot omits much of
SwiftUI's rendered content, so it does not prove full-screen visual parity.
Ailoha screenshots immediately after a fill can also precede SwiftUI's
render pass; check the live tree and a settled simulator capture.

With the rebuilt native host-deactivation bridge, `sample.name` changed to
`NativeGuard` on iOS and `MacNativeGuard` on macOS. The iOS simulator capture
`.build/evidence/cycle3-complete-ios-20260927T051156Z-75154.png`
(1206x2622; SHA-256
`1ab07e3c398163d7c067c0e74d445c128421ef841f86e01367c54aeaf4586863`)
shows `Hello, NativeGuard` across the entire display. The macOS agent
capture `.build/evidence/cycle3-complete-macos-20260927T051247Z-77483.png`
(SHA-256
`4d59a52d18f44707a952027e4870301e7202134fa7baffafae4b04b77db5dad6`)
shows the changed native field, subject to the same SwiftUI screenshot limit.
Both final native trees still omit `sample.add`.

For the preview.3 package review, the newly built iOS Debug sample was
installed on an iPhone 17 Pro iOS 26.2 simulator where the bundle ID was
absent; the earlier installed sample and its data were not replaced. The
installed executable matched the newly built one (SHA-256
`75f247985e03b8c3401e48cf4f1f76e8dc229d2193c941bc4b0a984733554222`).
The new sample's Ailoha tree exposed `UIWindow` and `sample.name` but still
not `sample.add`. Filling `sample.name` by stable ID with `PreviewThree`
succeeded; `.build/evidence/revision-preview3-consumers/ailoha-preview3-input.png`
(SHA-256
`eeb6ca229e05992836e77e5c9946a4dd93d21ef2f2394b0b9dc934ef6a2c8d4a`)
shows `Hello, PreviewThree` in the running app. No Add action or proxy was
used.

The Text-based SwiftUI **Add** button is not an element in this agent's
native-view tree. `ailoha ui tap --automationId sample.add` returns
`No elements found`. The public Ailoha modifier `.ailohaIdentifier(...)`
must be applied when that SwiftUI button is composed; a sample host cannot
retrofit it onto an opaque child of another framework's hosting view.
This limitation is tracked upstream as `Redth/ailoha#132`; do not work
around it with a proxy control or a coordinate tap.
An iOS Debug hierarchy probe enumerated 80 actual `UIView` nodes: the
native `UIButton` belonged to the picker, the `UITextField` was the tagged
Name input, and no `UIView` carried `sample.add` or an `Add` accessibility
label. The temporary probe code was removed after capturing that result.
The reusable library remains Ailoha-free.
