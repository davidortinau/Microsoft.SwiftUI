# Consumer verification and handoff

The two sample shells intentionally depend on the shared C# feature project;
the SwiftUI library owns no process lifecycle, account, storage, or Maui
integration. The samples use distinct bundle IDs and never touch an existing
application's data.

## Debug-only Ailoha verification

The official v0.1.13 Swift agent is now available at an external path,
verified against the published ZIP SHA-256 and all extracted files. The
sample-only Swift adapter and managed binding start it in Debug on iOS and
native macOS; neither the reusable library nor either Release bundle
contains Ailoha. Its binary license is distinct from this repository's MIT
license. See [Debug integration and license boundary](ailoha-debug.md).

The agent connected on both platforms and exposed native UI trees.
`sample.name` resolves to the actual native text input: filling by that
stable identifier changed the iOS field and shared C# greeting to
`Hello, Navigator`; macOS reported value `Skipper` and changed its captured
input. The existing SwiftUI Text-based Add button is **not present** in the
agent's native tree. `ui tap --automationId sample.add` fails with
`No elements found`; do not interpret a connected agent or changed input as
proof that the SwiftUI button works through stable-ID automation.

## Before SentenceStudio slice work

The packed NuGet library compiled in independent pure
.NET iOS and macOS consumers in Debug and Release. The canonical Cycle 3
package, `artifacts/Microsoft.SwiftUI.0.1.0-preview.3.nupkg` (SHA-256
`6537f3c8f8004ff0d256a61678247a248ff6e093ea135a53e3196c9c1037698d`),
was rebuilt from current source and restored from a fresh isolated local
cache. The package verifier checked both assemblies' exact detach method
signatures, the generated native binding, all source hashes, and both
packaged frameworks against the generated XCFramework; regression checks
rejected source divergence, modified native resources, and a missing detach
method. The complete per-slice inventory now also rejects a missing iOS
device Info.plist; resource ZIP checks reject a macOS Resources symlink
replaced with a regular file and a native-reference manifest whose
framework Kind is `Invalid`. Both native macOS consumer configurations ran
the packaged view, controller, detach, action, callback
suspension/restoration, and slider label checks, and both iOS simulator
configurations built. The iOS Debug
consumer also launched on an iPhone 17 Pro simulator running iOS 26.5, with
the packaged SwiftUI view visible and host deactivation exercised during
scene creation. Six native Swift tests and twenty managed tests passed.
The samples now have optional Ailoha Debug hosts, but the SwiftUI Add
button still needs a supported way to surface its identifier to the native
agent; the upstream limitation is tracked in `Redth/ailoha#132`. Do not
replace the button with an unrelated proxy action. Begin the SentenceStudio
slice only after the actual Add button and input both pass stable-ID
interaction on iOS and macOS.

For the preceding package-inventory revision, two consecutive native builds
produced identical inventories (7 regular files, 3 symlinks, 10 directories);
two fresh Release rebuilds/packs produced identical preview.3 packages for
that revision. `tests/test-package-verifier.py` passed its intact-package check
and 14 independent corruption checks. New NuGet-only consumers restored
that exact hash into `.build/evidence/revision-inventory-consumers/nuget`,
built iOS and macOS in both Debug and Release, and executed both macOS
configurations successfully. The iOS Debug app launched on an iOS 26.5
simulator and Release on a separate iOS 26.2 simulator, both under a new
bundle ID, without replacing existing installations. The macOS Release
consumer's ad-hoc code signature validated.

The rebuilt Ailoha Debug samples exposed `sample.name` in both native trees.
Stable-ID fills changed the new iOS sample's field to `InventoryGate` and
the Mac sample's field to `MacInventory`; their JSON tree and fill evidence
is in `.build/evidence/revision-inventory-consumers/`. Neither tree exposed
`sample.add`, and no proxy action was attempted. Both Release sample bundles
and the reusable NuGet package passed the Ailoha exclusion check; the
Release sample signatures validated. The Add-button limit remains tracked
upstream in `Redth/ailoha#132`.

## Final verifier hardening (September 27, 2026 UTC)

The canonical preview.3 package above was rebuilt with XML documentation for
both platforms and an exact 13-entry payload allowlist. The verifier now
rejects populated NuGet dependency groups, all unexpected package paths,
namespaced substitutes or malformed fields in the native-reference XML, and
symlink mode drift in both the generated framework and packaged ZIPs.
`tests/test-package-verifier.py` passed 37 corruption checks, including a
native-only change of the macOS Resources link from mode 0755 to 0600, and
two intact checks. Four successive verified packs had the same SHA-256;
the last two finished at 2026-09-27T06:48:37Z and 06:48:41Z. The rebuilt
native framework has 20 inventoried entries; its provenance was recorded
at 2026-09-27T06:40:56Z.

Fresh NuGet-only consumers restored the exact canonical bytes to
`.build/evidence/final-hardening.tYTOEJ/consumers/nuget`. Debug and Release
builds passed for iOS and native macOS. Both macOS configurations ran the
packaged view/controller detach, action, callback, and slider-label checks;
their signatures verified. The iOS Debug app launched and rendered on an
iOS 26.5 simulator, and Release on a separate iOS 26.2 simulator, under a
previously unused bundle ID on each. Their captures are
`.build/evidence/final-hardening.tYTOEJ/consumer-ios-Debug.png` and
`consumer-ios-Release.png`. Swift tests passed 6/6, managed tests 20/20,
and native/Ailoha scratch-failure retention and success cleanup passed.

The official Ailoha Debug input and both Debug sample builds verified.
Stable-ID fills changed real native `sample.name` fields to `FinalGateIOS`
and `FinalGateMac`; JSON tree and fill outputs are in the same evidence
directory. Both Release sample bundles and the NuGet package exclude Ailoha;
the Release macOS signature verified. Neither tree exposed `sample.add`;
no proxy or coordinate tap was attempted. `Redth/ailoha#132` remains the
blocking stable-ID Add-button issue. No physical device was touched.

The iOS sample was installed without uninstalling any app on an otherwise
unused iPhone 17 Pro simulator running iOS 26.5. Its launch storyboard and
orientations are present in the built app manifest. The final full-screen
capture `.build/evidence/cycle3-complete-ios-20260927T051156Z-75154.png` is
1206x2622 pixels, matching that simulator's display, with no visible
letterboxing (SHA-256
`1ab07e3c398163d7c067c0e74d445c128421ef841f86e01367c54aeaf4586863`).
The earlier simulator automation service returned errors for its own
accessibility-tree reads and taps; Ailoha's separate agent provided the
native-tree and input evidence above. Native and managed tests establish
the slider label's data path, but runtime VoiceOver labeling remains to
be inspected. Keep simulator data intact, leave `maui-labs` untouched,
and do not deploy to a physical device for this handoff.
