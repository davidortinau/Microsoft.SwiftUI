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
The prior preview.3 package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.3.nupkg` (SHA-256
`6537f3c8f8004ff0d256a61678247a248ff6e093ea135a53e3196c9c1037698d`,
412178 bytes; last rebuilt September 27, 2026, 06:48:40 UTC).
Preview.2 artifacts already existed. Preview.3 had never been pushed or
published, so its earlier bytes were backed up at
`.build/package-history/Microsoft.SwiftUI.0.1.0-preview.3.before-final-hardening-20260927T064144Z.nupkg`
before rebuilding the same public version. Restore it using a new isolated
NuGet cache, not the old preview.3 cache.

## SwiftUI App.main bridge preview.5 (historical, October 3, 2026)

The prior lifecycle bridge package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.5.nupkg` (SHA-256
`0f7db24ebd52b782e58dd1d7e9964716431136608ab620f5a804deba0855396d`).
Preview.3 remains byte-identical to the historical archive above. An
intermediate preview.4 (`3034865d60a1ef318195587bf238d911e4448efd01af1c8b70a585c2559575ef`)
was preserved rather than overwritten after a subsequent accessibility
change; consumers must reference the manifest-matching preview.5. This version
adds a native `App.main()`/`WindowGroup` startup path, bound `NavigationStack`
paths, independently navigable `TabView` children, `Form`/`Section`,
`SecureField`, string-valued `Picker`, and the SwiftUI controls used by the
current iOS slice; it does not replace existing explicit UIKit/AppKit hosts.
Feature declarations remain in C# and bridge controls render in SwiftUI.

The preview.5 native framework was archived with Xcode 26.6 / Swift 6.3.3
on the existing installed Preview 7 .NET Apple binding toolchain and contains three
verified device/simulator/macOS slices. Its build provenance recorded five
per-file source SHA-256 hashes, all binary hashes, and its 20-entry inventory;
the preview.5 SwiftUI node source hash was
`4d913512d83dfe46cc5b7da8d481ab087d36cd68c83e677b062ebda61262efc9`
and the `Application.swift` source hash is
`763e9be6fdf925f6e2d271557edea90846e84ecdeca30ea81f39c07ef6acb94d`.
The existing Preview 7 SDK pin is local and ignored. On this machine the
networked Preview 7 NuGet restore may hang; run the existing package script
with a project-local offline config (`RestoreConfigFile`, `RestoreSources`,
`NuGetAudit=false`) pointing at `artifacts/`. No SDK or workload changes are
needed. The package verifier checked source/binary/package parity for both
TFMs, preserving the existing host teardown API.

`tests/Microsoft.SwiftUI.AppMainProbe.iOS` is an isolated, C#-authored
consumer of the preview.5 package, compiled with the already installed .NET
RC1 SDK and Xcode 26.6 against iOS 26.5. Its distinct bundle ID must be used
for simulator interaction; never uninstall another app. Its neighboring
`AppMainUITests.xcodeproj` drives form, bound picker, native Back, and both
tabs, retaining screenshots in an `.xcresult` stored under `.build/`.
Swift tests passed 8/8, managed native-macOS tests passed 23/23, and the
dedicated iOS UI test passed 1/1. The running C# consumer visibly receives
both `OnAppear` and `scenePhase.Active`, updates a picker-backed C# label,
pushes a route, observes native Back and retains an independent Resources
tab path. Its executable manifest has no application-authored scene delegate.

XCTest on iOS 26.5 exposes native `SecureTextField`, `Picker`, and button
labels but does **not** expose the child automation identifiers inside
SwiftUI `Form`/`Section`; the same test finds identifiers on SwiftUI `List`
detail controls. The UI test therefore uses visible labels for Form
interactions, while the missing Form child identifiers remain an explicit
automation limitation rather than proof of stable-ID support. See
`docs/consumer-verification.md` for the earlier independent Ailoha issue.

## First-journey preview.6 (historical local package, October 3, 2026)

`artifacts/Microsoft.SwiftUI.0.1.0-preview.6.nupkg` has SHA-256
`6495e84e6081220bdbcdb92b100e13ab9490bcdb8c49df967d603a7b60766dc9`.
The preview.3, preview.4, and preview.5 archives remain unchanged. The native
source hash for `SwiftUINode.swift` is
`1b223bad5e6df2ab1c2ecffba3ec11bb33ef7663bdb90b67f73b6cde0a1dc763`;
the current `.build/native/MicrosoftSwiftUIShim.provenance.txt` records that
source and the unchanged `Application.swift` hash with generated per-slice
binary hashes. Source and package were verified together after a full rebuild
of both target frameworks.

Only four concrete first-journey blockers were added: `IsEnabled` applies
SwiftUI `.disabled` to keep busy/invalid controls visible and noninteractive;
`Button(SwiftView, Action)` renders a C#-composed padded label in one SwiftUI
Button with a rectangular content shape; `FileImporter(..., onCancelled)`
separates user cancellation from read failures; and `CanNavigateBack` blocks
both native and programmatic pop while an operation is in flight.
`WithTabBarHidden` uses SwiftUI toolbar visibility for pushed iOS destinations,
and existing `WithNavigationTitle` updates a mounted title without replacing
the stack.

The C#-authored iOS 26.5 consumer built with the existing RC1 SDK, and
XCTest passed 3/3 on the existing isolated simulator: disabled-to-enabled
secure entry, native Back lock/unlock and live title refresh, composed-card
icon/metadata/edge taps, separate navigation stacks, and system file-importer
Cancel without `readFailed`. A focused fourth run passed 1/1 asserting
Form child `probe.password` and `probe.language` accessibility IDs, which were
absent in preview.5. Swift tests passed 9/9 and managed macOS tests 25/25.
Native title/path/tab identity on *actual* SentenceStudio presenter refreshes
remains the iOS integration owner's validation step; no product parity claim
follows from this micro consumer.

One directly slice-blocking .NET build-tool friction was observed: after
restoring preview.6, an incremental RC1 consumer build left the preview.5
framework embedded in the app and failed at launch with
`-[MSUNode setIsEnabled:]` unrecognized selector. A targeted
`dotnet build -t:Rebuild` refreshed the framework without uninstalling an app,
and the rebuilt consumer passed the tests above. For each bridge package
version change, inspect the app-bundled native selectors before launch; no
generalized workaround, installed-SDK change, or upstream issue was needed for
this first occurrence.

## Source-style preview.7 (October 3, 2026)

`artifacts/Microsoft.SwiftUI.0.1.0-preview.7.nupkg` has SHA-256
`d463170f5f473bc488ceb59f63696a4a483f70fe72cf855e4770ee978c878514`.
The preview.3, preview.4, preview.5 and preview.6 archives retain their
prior SHA-256 identities. The final native `SwiftUINode.swift` source SHA-256
is `9b8cdbc82810c0b32211913af95fdd6ccceb70e2a90f98f78eb1a1e3ce642aa9`;
`Application.swift` remains
`763e9be6fdf925f6e2d271557edea90846e84ecdeca30ea81f39c07ef6acb94d`.
The freshly archived three-platform XCFramework and both rebuilt binding
assemblies match `.build/native/MicrosoftSwiftUIShim.provenance.txt` and
passed `scripts/pack-and-verify.sh`'s exact per-file package checks.

This version adds the *source-blocking* primitives: explicit dynamic
font metrics using SwiftUI system/custom fonts; mounted preferred color
scheme and paired foreground/background/tint; per-edge padding and
centered max-width frames with rounded surfaces/stroke/shadow; real
determinate `ProgressView` with a height-specific `ProgressViewStyle`;
`safeAreaInset(edge: .bottom, spacing: 0)` with separate content/footer;
and mounted container-width/Dynamic Type callbacks plus identity-preserving
`AnyLayout` for cramped control rows. It does not bundle application fonts,
choose a product theme, author a product screen in Swift, or perform
application-owned reconciliation.

Swift tests passed 12/12 and the macOS managed facade tests passed 30/30.
The distinct C# `App.main()` iOS probe built with the already installed
RC1 SDK, using a fresh project-local NuGet cache to guarantee the **final**
preview.7 package bytes. Its RC1 ILLink/runtime/crossgen dependencies
were reused from their existing on-machine caches via symlinks; no SDK,
workload or NuGet dependency was installed. The app-bundled native framework
was checked for the new Objective-C selectors before a non-destructive
install on the dedicated iOS simulator. The running-consumer assertions
and remaining limitations are documented in
[`consumer-verification.md`](consumer-verification.md).
The initial preview.7 candidate was preserved at
`.build/package-history/Microsoft.SwiftUI.0.1.0-preview.7.before-inheritance-fix.nupkg`
(SHA-256 `0a98637c811fd1d74ef80b0c06e33a2d51671b309029689a5e61d11565161981`)
before repacking: XCTest screenshots proved its child `.foregroundColor(nil)`
discarded the parent's source palette, and the final native implementation
does not apply a nil font, foreground or tint modifier.

## Native source-style correction preview.8 (October 3, 2026)

`artifacts/Microsoft.SwiftUI.0.1.0-preview.8.nupkg` has SHA-256
`e6c3c87b1a5a8fdd18c3088d95c24e4024cf7f421c0f83f04f620edad8ba74c8`.
The preview.3 through preview.7 archives retain their previous hashes.
Native source `SwiftUINode.swift` is
`96a4b2a961d521f503008fd3f95896d8a7ebe5ba6204e194d393d1689c7ca136`;
`Application.swift` is unchanged. The generated iOS device/simulator and
macOS native binaries are listed in the current
`.build/native/MicrosoftSwiftUIShim.provenance.txt`. The existing
`build-xcframework.sh` and `pack-and-verify.sh` verified all three slices,
both rebuilt managed assemblies, and the packaged byte inventory.

Four opt-in methods correct observed native style gaps:
`WithNativeListColors` keeps actual SwiftUI `Form`/`List` controls while
hiding their system scroll canvas and applying paired native row/Section
surfaces; `WithInlineNavigationTitle` requests iOS inline title layout;
`WithCenterWhenShort` aligns only undersized `Scroll` content using
`defaultScrollAnchor(.center, for: .alignment)` on iOS 18+/macOS 15+
(an available-viewport `GeometryReader` fallback handles older supported
versions); `WithPlaceholderColor` supplies native SwiftUI `Text` prompts
for real text and secure fields. `WithMinimumHeight` now sizes the native
Button label/content shape before AX identification, rather than an outer,
noninteractive frame. Existing calls that omit the new methods keep their
prior defaults. No app fonts, project theme, UIKit renderer or feature UI
was added to the bridge.

Swift tests passed 13/13, managed macOS facade tests 33/33, and the distinct
C# iOS consumer rebuilt from a fresh preview.8 NuGet cache with 0 warnings
and 0 errors on the installed RC1 SDK. Its nine XCTest cases passed on
the existing isolated iOS 26.5 simulator; see
[`consumer-verification.md`](consumer-verification.md) and the session
`files/swiftui-source-styling-20261003/style-bridge-contract-v8.json`.
No new SDK, workload, NuGet dependency or host library was installed.

One iOS Release archive failed with Swift's `OpaqueTypeInference` diagnostic
when the enlarged node `body` recursively inferred private `some View`
collection/scroll helpers; macOS Debug Swift tests alone did not expose it.
The same installed Swift 6.3.3 / Xcode 26.6 iOS SDK reproduced it via
`swiftc -typecheck -enable-library-evolution -O`. Narrow private
`ScrollNodeView` and `NativeCollectionNodeView` SwiftUI components broke
the recursive opaque-type dependency without changing node identity or
substituting a renderer. Re-archiving and package verification passed; the
failed archive scratch remains in `.build/native/` for diagnosis.

## Opt-in button, circle and underline preview.9 (October 4, 2026)

`artifacts/Microsoft.SwiftUI.0.1.0-preview.9.nupkg` has SHA-256
`b77b0b0b08d5cc295da615d6d5c6201826a6406cc33da0443a504f3b9500cf13`.
The source-matched native `SwiftUINode.swift` hash is
`07da0a5c91e7895e458b8a782e6cecade5ca67f68ea52133ee812508a4c106b8`;
`Application.swift` is unchanged. The current
`.build/native/MicrosoftSwiftUIShim.provenance.txt` records the three
verified framework binaries and its 20-entry byte/mode/symlink inventory.
`build-xcframework.sh` archived iOS device, iOS simulator and macOS with
Xcode 26.6/Swift 6.3.3. `pack-and-verify.sh` rebuilt both Release binding
assemblies with the preexisting Preview 7 .NET SDK pin and matched the
packaged native resources to the archive. Preview.3 through preview.8
archives retain their prior SHA-256 values; preview.8 remains
`e6c3c87b1a5a8fdd18c3088d95c24e4024cf7f421c0f83f04f620edad8ba74c8`.
The first same-task preview.9 candidate was preserved at
`.build/package-history/Microsoft.SwiftUI.0.1.0-preview.9.before-readme-20261004.nupkg`
(SHA-256 `895e22ed9d095641a55250d65402b2313a7ad60beaaa38bd24b44e1c239420e2`)
before final packing so the package README matches the current source.

The bridge adds `WithButtonAppearance` only to `Button`: both nullable
fill colors are null for real transparency, a light/dark border pair
is required, and the custom native `ButtonStyle` uses the SwiftUI
`isEnabled` environment to apply the requested disabled opacity once.
The existing SwiftUI Button and native action guard remain intact.
`SwiftUI.Circle` is a native `Circle().fill(...).frame(width:height:)`;
`WithUnderline` modifies native `Text`, not a replacement control.
No application screen, font file, theme, UIKit renderer or new package
dependency is included.

Native Swift tests passed **15/15**, macOS managed host tests **35/35**,
and the distinct C# App.main iOS microconsumer **12/12 XCTest cases**
with zero skips. The consumer uses the preexisting RC1 SDK pin, a fresh
isolated preview.9 NuGet cache containing the same final archive SHA-256,
and the dedicated iOS 26.5 simulator. Its built and installed executable
both hash to
`3a1ca11502c07dd8012003af27beb7c68eb412a894b725e55486ec6e59415d31`;
the built and installed native framework both hash to
`8569d6dfa45377dcbe50f94d4b90aea24d14005085169709b6fd7036770068ce`.
See `.build/style-v9-ui-final-package.xcresult`,
[`consumer-verification.md`](consumer-verification.md), and the
session `files/swiftui-source-styling-20261003/style-bridge-contract-v9.json`
for actual light/dark pixels, 8-point dot bounds at normal/XL,
near-edge taps and explicit limits. The dedicated probe data was backed
up before its non-destructive update. No canonical product app, account,
database or physical device was changed.

## Per-button inner stroke width preview.10 (October 4, 2026)

The pinned source's Vapor Light `.btn-outline-success` has a late
`border-width:2px` override, while preview.9's real SwiftUI Button appearance
hard-coded a one-point stroke. Preview.10 adds only
`SwiftView.WithButtonBorderWidth(double points)`: finite positive points,
Button-only, default one point, and effective only when
`WithButtonAppearance` has enabled the existing opt-in native style.
The original appearance method's signature and all omitted-width callers
are unchanged. The native node publishes mounted updates; the same
`ButtonStyle` strokes the original rounded shape inside the existing
44-point hit region.

The new local archive is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.10.nupkg` (SHA-256
`9f884dd4a9ad91fd059a1ff02d3fab870c4e0e3cbc66ffe3deb80d14f9cf1d8f`).
The archived `SwiftUINode.swift` SHA-256 is
`ec04df9be7de4c08fbcfe896dd2fcbab48000e86480959e4eeff3a18f5d73924`;
`Application.swift` remains
`763e9be6fdf925f6e2d271557edea90846e84ecdeca30ea81f39c07ef6acb94d`.
The three framework slices and 20-entry source/binary inventory passed the
existing exact verifier, and both iOS and macOS Release binding assemblies
were rebuilt before packing. Preview.3 through preview.9 archives retain
their recorded hashes; preview.9 remains
`b77b0b0b08d5cc295da615d6d5c6201826a6406cc33da0443a504f3b9500cf13`.

Native tests passed 15/15; managed macOS facade tests passed 35/35.
The existing C# App.main iOS probe rebuilt from an isolated preview.10 NuGet
cache under the already-installed RC1 SDK. On the dedicated iOS 26.5
simulator its 13/13 XCTest cases passed, including the 12 prior cases.
The new Vapor Light case measured six physical green border pixels at 3x
scale versus three on an omitted-width sibling, a transparent interior,
mounted changes from two points to one and back, 44-point native Button AX
targets, near-edge actions and disabled/parent-disabled no-ops. The
result is `.build/style-v10-ui-final.xcresult`; the screenshots, AX tree,
package/native hashes and exact head-call example are in the rebuild
session's `files/swiftui-source-styling-20261003/style-bridge-contract-v10.json`.
The distinct probe sandbox was backed up before updating it; no native
SentenceStudio head or canonical simulator was built or modified.
This is a package-contract proof, not product styling parity.

## Elliptical source corners and single-pass opacity preview.11 (October 4, 2026)

The frozen Sketchy `.btn-sm` source specifies `255px 25px 225px 25px /
25px 225px 25px 255px` in top-left, top-right, bottom-right, bottom-left
order. Four circular radii or one scalar cannot represent its eight
horizontal/vertical axes. The opt-in
`SwiftView.WithButtonEllipticalCornerRadii` retains the original scalar
appearance API, requires a live Button and eight finite nonnegative values,
and leaves callers without the new setter on their existing
`RoundedRectangle`. Nine native node properties carry eight axes and one
opt-in flag; the same real SwiftUI `ButtonStyle` constructs a closed
four-cubic `InsettableShape` for fill, inner stroke, and declared interaction
shape. The opt-in Button label uses `.contentShape(.interaction, shape)`;
old labels retain their rectangular default.

The shape follows [CSS Backgrounds and Borders §4.5](https://www.w3.org/TR/css-backgrounds-3/#corner-overlap):
the *original* border box determines a **single** adjacent-radius overlap
factor for all eight axes. `inset(by:)` keeps that factor and subtracts the
inset from each used axis, rather than normalizing again against a smaller
rect. A zero-axis corner is square. The existing ButtonStyle also applies
SwiftUI `compositingGroup()` before disabled opacity; source-equal disabled
fill and border therefore fade once as a group. The native action guard,
inherited `.disabled`, and minimum 44pt button target remain in place.
See the [SwiftUI `InsettableShape` and `strokeBorder` contract](https://developer.apple.com/documentation/swiftui/insettableshape),
[interaction content shapes](https://developer.apple.com/documentation/swiftui/contentshapekinds/interaction),
and [Apple's compositing group documentation](https://developer.apple.com/documentation/swiftui/view/compositinggroup%28%29).

The verified local package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.11.nupkg`, SHA-256
`8dbe6a0ecb041c00ee1f47534fc578cc24efb9bb75b94f8a8176fb2593424b72`.
`SwiftUINode.swift` SHA-256 is
`d2647d3ff4675b15cc50d6f5f87479d9d7760ee49bb66c4d43ece7202896ff11`;
`Application.swift` retains
`763e9be6fdf925f6e2d271557edea90846e84ecdeca30ea81f39c07ef6acb94d`.
An earlier **unshipped** preview.11 candidate
(`050b2c309d97ddb9a4ca4e280ae73ffbc61bf9130b2100a26f45ff55eb15b54a`)
was preserved under `.build/package-history/` before the final native
label-shape update. Compared with that candidate, the final archive changes
only the two packaged iOS/macOS native resource ZIPs; managed assemblies,
ABI, README, XML and package metadata remain byte-identical.
The three Xcode 26.6 slices passed the existing 20-entry binary/source
inventory, both .NET preview.7 iOS/macOS Release bindings were rebuilt and
verified, and the previous preview.3–preview.10 archives were left intact.
Swift geometry/node tests passed 17/17, and the signed macOS C# runner
passed 36/36. The distinct C# iOS probe uses the installed .NET RC1 SDK,
an isolated preview.11 cache containing the exact package bytes, and only
its pre-backed-up dedicated simulator bundle; see
[`consumer-verification.md`](consumer-verification.md) for measured pixels.
All 15 iOS XCTest cases passed on the preview.11 probe (zero skipped or
failed) in `.build/style-v11-final-full.xcresult`. The final focused 2/2 run
measured six source-stroke pixels versus three on the untouched one-point
button, and differentiated **all four** ellipse-only border samples from
the old circular sibling in both appearance modes. A separate diagnostic
XCTest observed that a native Button can still activate for taps 1pt inside
its rectangular AX bounds but outside the painted curved corner, even
with the interaction shape on the label. The 44pt accessible native target
was deliberately preserved; do **not** claim strict silhouette-only hit
testing or replace the Button with a fake gesture surface.
This is a bridge primitive and compositor correction, not a source-screen
parity or release decision for SentenceStudio.

## Source Brite Button shadow preview.12 (October 4, 2026)

The pinned Brite stylesheet's late `.btn` rule gives its resting button a
black, zero-blur box shadow at `x=3px, y=3px`; its `3px` margin and inverse
translation cancel in the resting layout. `.btn-outline-secondary` and
`.btn-outline-success` reset the shadow to none. Only C# callers mapped
to a class that retains the shadow should opt in; the bridge does not
choose an app theme or add a page offset.

`WithShadow(lightHex, darkHex, radius, opacity, offsetY)` retains its
original signature and behavior for rounded surfaces. It now also accepts
an already configured real `Button` with `WithButtonAppearance`. The
single new public method, `WithButtonShadowOffsetX(double points)`,
requires a live Button with that appearance and a finite offset. Its
native `shadowOffsetX` defaults to zero. In the existing native Button
style, the same rounded or eight-axis shape that supplies the fill,
stroke and content shape casts the shadow. A grouped shadow-only layer
removes the original shape's interior, so a clear-fill text link remains
transparent and the label glyphs do not acquire shifted copies. The
existing outer `compositingGroup()` applies the disabled 0.65 opacity
once to the fill, stroke, label and shadow. See Apple's
[`shadow(color:radius:x:y:)`](https://developer.apple.com/documentation/swiftui/view/shadow%28color%3Aradius%3Ax%3Ay%3A%29)
and [`compositingGroup()`](https://developer.apple.com/documentation/swiftui/view/compositinggroup%28%29)
contracts. The old rounded-surface renderer still uses its original
zero-X shadow.

The verified **local-only** archive is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.12.nupkg`, SHA-256
`e87d5052c466daec5f3f8f26ab95f35f8fb8eed6f95953a5e364d544d6097101`.
The existing three-slice Xcode 26.6 source/binary inventory and both
Preview 7 .NET bindings passed `scripts/pack-and-verify.sh` using an
explicit project-local offline NuGet config. Native NodeTests passed
18/18, and the signed macOS managed tests passed 37/37. On the dedicated
iOS 26.5 3x simulator, two focused C#-authored Button tests passed.
The enabled, directly disabled, inherited-disabled and transparent-link
Buttons each have nine right and nine bottom device pixels of shadow
in both modes; the outline's corresponding bands have zero. The disabled
shadow composites from black once to `(89,89,89)` on white and
`(12,13,14)` on Brite's dark background. Toggling only the link shadow
left every sampled interior/glyph pixel unchanged (maximum RGB delta
zero). The old rounded surface retained X=0 and Y=3. The complete
existing-plus-new iOS XCTest suite passed 17/17 on the same package.
Seven independently sampled legacy Flatly/Vapor RGB positions and
their AX frames match preview.11 exactly (maximum channel delta zero).
These are bridge microconsumer proofs, not current-product-head or
full-application acceptance.

## Transparent source stroke and joined preference groups preview.14

The pinned source `59c72262ab649047d29addbb5177c81958c18ac1`
declares a Sketchy onboarding `.btn-link.btn-sm` with a clear two-point
stroke. CSS border edges contribute to the outer box even when the
border is transparent ([W3C box model](https://www.w3.org/TR/css-box-3/#box-model)).
The prior native inner `strokeBorder` painted within the **existing**
Button label dimensions, so a width of two alone could not reserve
four points on each axis. Preview.14 accepts a matched null border
pair through the existing managed Button API, passes empty paired
native strings to `Color.clear`, and reserves `borderWidth` around
the styled label **only** for that clear pair. The old opaque stroke
geometry remains untouched. Apple's
[`InsettableShape.strokeBorder`](https://developer.apple.com/documentation/swiftui/insettableshape/strokeborder(_:linewidth:antialiased:))
draws inside the same eight-axis shape used for
[`contentShape`](https://developer.apple.com/documentation/swiftui/view/contentshape(_:eofill:));
SwiftUI's standard [`ButtonStyle`](https://developer.apple.com/documentation/swiftui/buttonstyle)
continues to own the single real Button's action, pressed state and
inherited disabled behavior.

The pinned Brite and Sketchy `.btn-group` rules use a negative two-point
left margin on each subsequent **original** child, while onboarding
`.btn-group.flex-wrap` wraps six original choices at available width.
Preview.14 introduces a Button-only factory, not negative `Spacing`
for arbitrary stacks. Its narrow
[`Layout`](https://developer.apple.com/documentation/swiftui/composing-custom-layouts-with-swiftui.md)
asks each ordered `LayoutSubview` for its intrinsic size, computes
rows against a finite proposal, and places each original child with
its own matching proposal. The first item of every later row keeps
its original negative left margin. A `ForEach(id: \.id)` retains
native child identity, accessibility order, and managed actions through
width, text and Dynamic Type changes; selected/hovered/focused/pressed
children get source-like z-order at the seam. A separate
[`accessibilitySortPriority`](https://developer.apple.com/documentation/swiftui/view/accessibilitysortpriority(_:))
requests original VoiceOver traversal order independently of visual
z-order. `XCUIElementQuery.allElementsBoundByIndex` instead reports
hierarchy lookup indices, so a raised selected Button can appear last
in that query even with original VoiceOver sort priority.
The caller continues to
own source colors, shadow, corner resets and original first/last
selection. This narrow layout does not implement general flex grow,
CSS row stretch, or browser overflow policy.

The existing C# `App.main()` microconsumer has a preview.14 route
`probe.v13.open` with clear-versus-opaque source-link geometry,
selected two-Button seam actions and six variable-width Buttons at
320 and 195pt and accessibility XL. Its package provenance,
actual simulator frames, focus/accessibility observations, installed
binaries, and current test counts belong in the session's
`style-bridge-contract-v13.json`; these bridge checks do **not**
accept J-02/J-03 or any SentenceStudio head state on the head
owner's behalf. That historical preview.14 build used the Preview 7
SDK pin and a project-local offline NuGet config. Do not carry that
pin into the preview.15 build.

Preview.13 is retained as an intermediate archive: its first focused
iOS run exposed selected children appearing last in the accessibility
tree even though their visual overlap and callbacks worked. Preview.14
corrected that issue; do not integrate preview.13 into a head.

## Source ButtonGroup layout modifier preview.15 (October 4, 2026)

The pinned source revision `59c72262ab649047d29addbb5177c81958c18ac1`
uses `.btn-group.w-100` on Dashboard and `.btn-group` without `w-100`
on Resources. Its pinned Bootstrap rules give each child `flex: 1 1 auto`,
the full-width group `width: 100%`, and later children
`margin-left: calc(var(--bs-border-width) * -1)`. The effective grouped
seam is one point under ordinary Bootstrap and two under Brite and
Sketchy (Brite explicitly sets `calc(-1 * 2px)` on the sibling).
The new **group-only** `SwiftView.WithButtonGroupLayout(double overlapPoints,
bool fillAvailableWidth = false)` accepts finite nonnegative overlap,
rejects wrong-kind and disposed views, and leaves the three-parameter
`SwiftUI.ButtonGroup(...)` ABI intact. Existing callers still use
intrinsic widths and a fixed two-point overlap. A nonwrapping Dashboard
group can use `.WithButtonGroupLayout(1, fillAvailableWidth: true)`
plus `.WithFlexibleWidth()`; Resources can use
`.WithButtonGroupLayout(1)` with trailing alignment; Brite/Sketchy
callers pass `2`. Only positive surplus of a finite proposed width
is added equally to the children's *intrinsic bases*. Wrapped groups
still follow their original indices, corners, and intrinsic flow even
when the fill flag is set. The `Layout` measures and places every
original child with the same size proposal, as described by Apple's
[`LayoutSubview.place(at:anchor:proposal:)`](https://developer.apple.com/documentation/swiftui/layoutsubview/place(at:anchor:proposal:).md).

The source-built Xcode 27.1 (27A9269) XCFramework, .NET SDK
`11.0.100-rc.2.26478.115` iOS/macOS Release bindings, and exact
`artifacts/Microsoft.SwiftUI.0.1.0-preview.15.nupkg`
(`f3932e0562c32ed1bd46435f993614925ffd8333a11f22da15a74af9a5108392`)
passed the existing 13-entry package/source/native-inventory verifier.
Preview.3 through preview.14 archives were checked byte-for-byte
unchanged. The isolated C# `App.main()` probe rebuilt against this exact
archive with RC2 and ran on the iOS 26.5 simulator. The default iOS app
build stopped at the official Xcode 27.0 recommendation; **only that
build invocation** used Captain's approved
`-p:ValidateXcodeVersion=false`. No SDK pin, installed workload, global
Xcode setting, or project-level bypass changed. The seven focused native
UI tests passed; current installed Mach-O/DLL/PDB and source hashes were
frozen before testing. The full Swift native suite passed 23/23.

The macOS managed test executable could not run under the selected RC2
SDK: its restore requires `Microsoft.NETCore.App.Runtime.osx-arm64` and
`Microsoft.AspNetCore.App.Runtime.osx-arm64` version
`11.0.0-rc.2.26478.115`, absent from the installed cache and the public
NuGet index. A bounded local RC1-runtime fallback additionally lacked
matching macOS 27 Apple runtime packages, so no runtime or SDK was
downgraded. The running iOS C# probe separately checks the new modifier's
default `-1` selection, zero/negative/nonfinite overlap guards, wrong-kind
and disposed-view rejection, mounted selection, retained actions, and
child IDs. This is **not** a claim that the macOS managed suite passed.

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
The earlier packages used `net11.0-ios26.5` and `net11.0-macos26.5`.
With the installed .NET 11 RC2 Apple bindings, the preview.15 package uses
`net11.0-ios27.0` and `net11.0-macos27.0`; the verifier's exact allowlist
now pins these two targets. The generated nuspec was compared with preview.14:
both have exactly two empty dependency groups and the same 13 allowed entries
(only the target paths and library bytes differ). The corruption check now
rejects the earlier 26.5 group/path instead of accepting it as current.
The RC2 library-only binding build has `_CanOutputAppBundle=false`, so the
normal Apple SDK target does not run its **app-only** Xcode-version gate.
This does not relax `ValidateXcodeVersion` or qualify a C# iOS/macOS app:
RC2 recommends Xcode 27.0, whereas the available Xcode is 27.1.
The verification fails on stale or source-divergent artifacts, not merely
on missing paths. `tests/test-build-scratch-cleanup.sh` injects failures
to check both build scripts retain failed-run scratch; its successful
native/Ailoha builds confirm each cleans only its own new scratch.
The separately built, externally sourced Ailoha agent is
[sample Debug instrumentation](ailoha-debug.md), not an input to this
XCFramework or NuGet package.

## Four-screen iOS source bridge preview.16 (October 5, 2026)

The eight bounded iOS source-journey primitives are in the standalone
SwiftUI shim, managed bindings, and existing direct tests. The pinned
SentenceStudio reference was `59c72262ab649047d29addbb5177c81958c18ac1`.
ImageIO/CoreGraphics decodes owned bytes to a SwiftUI `Image`; the new
implementation adds no UIKit/UIImage image path. The original host-compat
API remains unchanged.

With Xcode 27.1 (27A9269) and selected .NET SDK
`11.0.100-rc.2.26478.115`,
`(cd native/MicrosoftSwiftUIShim && swift test --filter NodeTests)` passed
**28/28**. `scripts/build-xcframework.sh` archived all three
device/simulator/macOS slices. For the local, offline verified package:

```bash
RestoreConfigFile="$PWD/.build/style-v14-local-nuget.config" \
NuGetAudit=false bash scripts/pack-and-verify.sh
```

The native verifier matched **five source hashes and all 20 inventory
entries**, while both rebuilt iOS/macOS bindings had zero compiler warnings
and zero errors. The exact 13-entry NuGet payload is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.16.nupkg`, SHA-256
`b8115fcbac6c91808f0db3fc381d2d819bd2bf958d9fd6f76ed5603981cfbeaa`.
The installed preview.15 archive remains SHA-256
`f3932e0562c32ed1bd46435f993614925ffd8333a11f22da15a74af9a5108392`.
Some earlier, **different** preview.16 draft bytes were preserved under
`.build/package-history/`; restore the canonical archive into a new
isolated NuGet cache rather than reusing any old preview.16 cache.

The existing C# iOS App.main consumer restored the exact canonical
archive from `.build/style-v16k-consumer-nuget`, rebuilt its Debug app
with `-p:ValidateXcodeVersion=false` on that invocation alone, and
updated only its isolated simulator bundle in place after a hash-verified
data backup. The built and installed executable, PDB, managed DLL and
native framework match byte-for-byte. Its six focused current-binary
XCTest checks passed, including previous Light/Dark and ButtonGroup
controls; actual USB HID Up/Down/Return/Escape reached managed callbacks
once. See [consumer verification](consumer-verification.md) and the
private four-screen evidence contract for exact artifact paths. The
unavailable RC2 macOS runtime packs were not installed or downgraded;
the macOS managed executable did not run. No SentenceStudio product head
or source-parity state was certified by this isolated library proof.

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

For the **historical preview.3** qualification, the binding tool required
the then-installed Preview 7 SDK. This is not an instruction for preview.15:
use the globally selected RC2 SDK from this repository root, without a
checkout `global.json` or any new SDK/workload installation. For
preview.3 reproduction only, the old command was:

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

## Bounded TextEditor placeholder and retained Quick Add preview.17 (October 5, 2026)

Preview.17 retains every preview.16 managed signature and native default.
The opt-in `SwiftView.WithTextEditorPlaceholder(string)` leaves
`SwiftUI.TextEditor(text, onChanged)` intact; existing
`WithPlaceholderColor(lightHex, darkHex)` also accepts TextEditor.
The native TextEditor remains the input and only accessibility element;
a SwiftUI Text overlay follows empty, focused, typed and cleared
binding state without intercepting taps. Its empty accessibility
representation removes the purely visual placeholder from the native
tree. The retained Quick Add view takes a two-child snapshot on every
body evaluation and checks child identity before overlay, scroll and
dismissal callbacks; there is no UIKit path or navigation rewrite.

The selected SDK was `11.0.100-rc.2.26478.115` and Xcode was
27.1 (27A9269). Native Swift `NodeTests` passed **30/30**.
`scripts/build-xcframework.sh` archived iOS device, iOS simulator
and macOS slices under this checkout's `.build/native/`. Using a
bridge-local `NUGET_PACKAGES` and an offline config with the already
installed RC2 packages as a fallback, `scripts/pack-and-verify.sh`
rebuilt both binding assemblies with **zero compiler warnings/errors**.
Its verifier checked five native source hashes, 20 XCFramework entries,
both binding assemblies and the exact 13-file package payload.
No SDK, runtime or workload was installed.

The **canonical** local archive is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.17.nupkg`, SHA-256
`0dca7b0fd103697581c19bb85186ae2a813f270ac581c2c97dcb1f47e309df22`.
The iOS simulator universal framework inside it has SHA-256
`b6ff035ac531a34974348e4d71510159f198fb1e0aeb3ea5b37b0e5dbdeeb5fd`.
Earlier **unconsumed** preview.17 drafts are preserved under
`.build/package-history/p17-ax-draft-*/`; do not restore them by
version alone or reuse an earlier preview.17 NuGet cache. The final
archive differs from the tested previous draft **only in README.md**:
all other 12 NuGet entries, including iOS/macOS assemblies and native
resource ZIPs, are byte-identical. The preview.16 archive remains
SHA-256
`b8115fcbac6c91808f0db3fc381d2d819bd2bf958d9fd6f76ed5603981cfbeaa`.

The dedicated iOS 26.5 C# microconsumer installed its rebuilt app in
place on simulator `DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7` after
content-hashed backups of its persistent sandbox. Its built and
installed executable, PDB, managed DLL and thinned Swift framework
match byte-for-byte. Three focused **separate** XCTest runs passed:
TextEditor placeholder empty/focus/type/clear with one accessible
TextView; Quick Add closed/open→native Back→reopen; and the previous
anchored candidate-selection/outside-dismissal path. Screenshots,
accessibility trees and paths are in
[consumer verification](consumer-verification.md). The in-place
install invalidated four OS SplashBoard snapshot caches; subsequent
UI tests refreshed two OS Saved Application State files. Those six
OS-owned files were backed up first; all other 12 pre-existing
persistent files still matched. No app uninstall or data reset occurred.

Neither the macOS managed executable (matching RC2 runtime packs
unavailable) nor the real SentenceStudio iOS Resource Form has been
accepted by this isolated bridge proof. Its owner must restore the
**exact** archive into a fresh cache, use fresh generated native
outputs, and prove actual Back, Quick Add and Delete-open/cancel
without confirming a real deletion. The sampled preview.16 trap's
source symbol has no matching shipped iOS dSYM; do not claim that the
retained-view guard resolves the product trap until the real app runs.

## Source-backed horizontal SwiftUI grid preview.18 (October 5, 2026)

The single added generic factory, `SwiftUI.HorizontalGrid(
IReadOnlyList<double> columnMinWidths, SwiftView headerRow, params SwiftView[]
rows)`, provides the pinned Resource Add table's missing horizontal
scroll and shared column measurement. Every C# `HStack` row supplies one
cell per column; the shim uses a real `ScrollView(.horizontal)`,
`Grid`, and `GridRow`, keyed by the existing node IDs. Minimums use zero
for native intrinsic measurement and the caller's positive points only
where needed (pinned Type cell: 120). The separate existing vertical
`Scroll`/`LazyVGrid` paths remain unchanged. Apple's
[`Grid`](https://developer.apple.com/documentation/swiftui/grid) and
[`GridRow`](https://developer.apple.com/documentation/swiftui/gridrow)
documentation define shared column sizing and generated rows; the
[`ScrollView`](https://developer.apple.com/documentation/swiftui/scrollview)
provides native horizontal panning.

The immutable previous preview.17 archive remains SHA-256
`0dca7b0fd103697581c19bb85186ae2a813f270ac581c2c97dcb1f47e309df22`.
The canonical preview.18 archive is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.18.nupkg`, SHA-256
`5697e528d8f1114bd9d9cd0995c15eb8548e6613329e3bf92f058e37c6cabf26`.
The XCFramework/provenance verifier checked all three slices, five
native source hashes, and 20 framework entries. The package verifier
checked the 13-entry NuGet payload and both rebuilt .NET 11 iOS/macOS
binding assemblies at zero compiler warnings/errors. The simulator
universal framework in the archive is SHA-256
`5dac246da01f48b72f24ea374ec6fb96ae4c6bcf86609245f3d2e75b342f5d1f`,
byte-identical to the fresh isolated consumer extraction and
generated framework. The current signed app framework has arm64 UUID
`5C415557-02A4-3313-BC66-F7D9376898B2`; the preserved preview.17
framework's arm64 UUID is
`0FC8EE68-3E6C-32E1-BAEF-E5E52915E800`.

The native focused Grid and pre-existing vertical Scroll tests passed
**2/2**. The C# iOS consumer restored preview.18 in a fresh project-local
NuGet cache, rebuilt from fresh per-project artifacts, and exercised the
managed width guard, typed/selected cells, row removal and retained
input on the dedicated simulator. A direct macOS managed test build
cannot resolve two already-known RC2 macOS CoreCLR runtime packages
(`Microsoft.macOS.Runtime.osx.net11.0_27.0` and
`Microsoft.macOS.Runtime.osx-arm64.net11.0_27.0`); no SDK or package was
installed for this iOS slice. The consumer's bounded UI evidence is in
[`consumer-verification.md`](consumer-verification.md). Neither the
actual SentenceStudio form nor a human source-parity state is certified
by this library probe.

## Native composed Menu label preview.19 (October 5, 2026)

The new managed-only overload
`SwiftUI.Menu(SwiftView label, params SwiftView[] actions)` accepts
one caller-composed label followed by real Button actions. A label is
the menu node's first structural child; the native implementation
uses Apple's [SwiftUI Menu
`init(content:label:)`](https://developer.apple.com/documentation/swiftui/menu/init(content:label:)),
frames that **inner** label to the offered width with leading
alignment and gives it a rectangular interaction shape. The prior
`Menu(string title, params SwiftView[] actions)` remains unchanged.
No Objective-C selector or bound C# declaration was replaced.
The caller owns value/option state and places theme padding, outline,
selected-value text and trailing chevron inside the actual Menu label.

The immutable previous preview.18 archive remains SHA-256
`5697e528d8f1114bd9d9cd0995c15eb8548e6613329e3bf92f058e37c6cabf26`.
The canonical distinct
`artifacts/Microsoft.SwiftUI.0.1.0-preview.19.nupkg` is SHA-256
`6ae23480f3a2c2122df9d60eff2673840c9441b9e76ed4898c45a1855c2bf429`.
The source-built iOS simulator universal native framework has
SHA-256 `080a3166bdaa25dda9c9358936c07061738469d7ca8c64162600d8574e2fa6b9`;
the .NET binding assemblies in the archive are SHA-256
`ceaa4159f43cc1dc3994db34ce253bf08e019400f492681e0055517982231736`
(iOS) and
`c7cc6424ab007bf04d0910eec66401ab3523b83f0f278b5b68be4343ed778d9c`
(macOS). Native source/provenance verification checked five source
hashes, 20 framework entries and all three platform slices; NuGet
verification checked the exact 13-entry payload and both zero-warning
binding builds. Native focused tests passed 3/3 (composed Menu, old
Grid and old Scroll). The independent C# iOS probe restored preview.19
into a fresh project-local cache, rebuilt with zero warnings/errors,
and proved that its fresh extracted universal native framework and
binding DLL match this archive. Its built signed framework has arm64
UUID `D4B8FFF9-4E65-3437-B328-17C4D952984D`.

**Runtime acceptance is blocked:** the previously approved DCE iOS
simulator is no longer registered or present on disk. No replacement
device was created, and the human-owned sim977 was not used for a
build deployment, launch, screenshot or XCTest. The current
`AppMainUITests.swift` contains the focused full-width left/right
tap, leading-value/trailing-chevron, option callback, accessible
value/selection and Back assertions, but they have **not run** against
preview.19. Xcode's generic-simulator destination also rejected a
build-only XCTest runner compile; that is not a test result. The
package is a source/package-verified candidate for Root's later
device-bound verification, **not** proof of Resource Edit source/UI
parity or a fix for the distinct Resource Add preview.18 Type Picker
edge defect.

## Local toolchain qualification (September 27, 2026 UTC)

Xcode 26.6 and Apple Swift 6.3.3 produced and verified all three slices.
The installed .NET SDK `11.0.100-rc.1.26425.128` builds stock iOS simulator
and macOS apps, but the matching Apple binding tool's `bgen.runtimeconfig.json`
requests `Microsoft.NETCore.App 11.0.0-rc.1.26426.105`, while the installed
runtime is `11.0.0-rc.1.26425.128`. Binding builds stop with exit code 150.
No SDK, runtime, or workload was installed or changed.

At that historical checkpoint, the *already installed* SDK
`11.0.100-preview.7.26381.103`, its installed
Apple workload `26.5.11997-net11-p7`, and its matching runtime successfully
build the binding and the consumers. To reproduce that
qualification without changing the checkout's default SDK, create an
**ignored** `.build/sdk-preview7/global.json` with the installed SDK version,
`"rollForward": "disable"`, and `"allowPrerelease": true`, repeat the four
diagnostics from that directory, then run the build commands there with
absolute project paths. This is a per-invocation selection of an existing
installation, not a change to installed SDKs or workloads. The RC2
binding/package path is now verified above; the unavailable RC2 macOS
*app* runtime packs are a separate limitation.

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
