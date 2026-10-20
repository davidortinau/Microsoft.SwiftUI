# Consumer verification and handoff

The two original sample shells intentionally depend on the shared C# feature
project and still use explicit platform hosts. Preview.5 additionally provides
`SwiftUIApplication.Run` for native `App.main()`/`WindowGroup` startup.
The library owns no account, storage, or MAUI integration. Both the samples
and the newer lifecycle probe use distinct bundle IDs and never uninstall or
touch another application's data.

## Native SwiftUI App.main consumer (October 3, 2026)

An independent C# iOS consumer at `tests/Microsoft.SwiftUI.AppMainProbe.iOS`
restored the locally verified preview.5 NuGet archive, built on the installed
.NET RC1 SDK, and launched in its own bundle on an existing iOS 26.5
simulator. The `AppMainUITests` XCTest verified `OnAppear` and scene-phase
callbacks reaching C#, a real SwiftUI `Form` containing `SecureField` and a
bound string-valued picker, a C# `NavigationStack.Push` destination, native
Back synchronizing the managed path, and independent `TabView` stacks.
Screenshots and the one-passing/zero-failing XCTest result are in the task's
session evidence (`files/swiftui-refactor-20261003/`) and the bridge checkout's
ignored `.build/task-swiftui-20261003/ui-test-05.xcresult`.

The preview.5 iOS 26.5 XCTest accessibility snapshot exposed native Form controls by
role and label but omitted their child `accessibilityIdentifier` values. The
same probe exposes identifiers for the destination's `List` controls. The
end-to-end test uses labels for Form interactions, not a proxy control;
stable-ID automation inside Form remains an open limitation. This is separate
from the earlier Ailoha native-tree button issue below.

## First-journey preview.6 extension

The local preview.6 package adds actual SwiftUI disabled controls, one
composed-label button hit target, a cancellation-only importer callback,
guarded navigation Back, and destination tab-bar visibility. Three iOS
XCTest cases passed: a managed secure input enabled its submit button; a
resource card opened by taps on both its right/bottom metadata edge and
left/top icon edge; a system file-importer Cancel invoked only the managed
`onCancelled` callback. The original App.main, picker, scene phase, tabs,
native Back, and title-refresh paths remained working. A fourth focused
test asserted Form child `probe.password` and `probe.language` identifiers:
preview.6 exposed them in the XCTest AX tree. This does not prove all
SentenceStudio form identifiers or resolve the separate historical Ailoha
button limitation. Tests and screenshots are in
`files/swiftui-refactor-20261003/` (session evidence).

The first preview.6 iOS consumer build restored the correct NuGet version but
retained preview.5 native framework bytes in the `.app`; its first launch
threw `-[MSUNode setIsEnabled:]` unrecognized selector. A targeted
`dotnet build -t:Rebuild` updated the bundled native framework, and the
next 3/3 XCTest pass came from that rebuilt app. No app was uninstalled or
simulator data reset.

## Source-style preview.7 C# consumer

The final `Microsoft.SwiftUI.0.1.0-preview.7.nupkg` is
`d463170f5f473bc488ceb59f63696a4a483f70fe72cf855e4770ee978c878514`
(SHA-256). The independent C# `App.main()` probe rebuilt with .NET 11 RC1
from that package in a fresh project-local NuGet cache. Its embedded native
framework contains the new font, preferred-scheme, progress, adaptive-stack,
and viewport selectors. The bundle remains
`com.davidortinau.microsoftswiftui.appmainprobe20261003`; it was updated
without uninstall or reset on the separate iOS 26.5 iPhone simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`.

The full `.build/style-source-preview7-ui-full.xcresult` passed **5/5** native
XCTest cases. The previously passing C# App.main, navigation, form, importer
and composed-card tests still pass. New cases exercised the *C#-authored*
style tree: a mounted dark-to-light preference change; source-palette
foreground, surface and tint on actual SwiftUI nodes; 440pt centered
max-width with a full-card tap region; native AX `ProgressIndicator` nodes
at 8pt and 4pt, updated from 33% to 67%; a phone/landscape viewport callback;
Accessibility1 Dynamic Type with vertically stacking filter controls; and
a retained focused `TextField` whose changed value reached a visible
managed C# label in the inset footer. With the keyboard up, the AX tree
measured the ScrollView at `{{12,128},{378,326.3}}`, the footer at
`{{0,466.3},{402,72.7}}`, and the keyboard beginning at `y=583`.
Swift tests passed 12/12 and macOS managed facade tests passed 30/30.
The screenshot/AX extracts and exact public signatures are in the current
rebuild session's
`files/swiftui-source-styling-20261003/style-bridge-contract.json`.

An initial probe assertion for `Input: crew` in a *scrolled-off*
`LazyVStack` row was not valid AX evidence: the native input contained
`crew`, but the out-of-viewport status was not mounted in the accessibility
snapshot. Moving that synthetic status to the already-required pinned
footer made the callback visible, and the final 5/5 XCTest run passed. An
earlier same-task preview.7 archive was also preserved before fixing
`.foregroundColor(nil)` on child nodes: image analysis proved it had
discarded an ancestor's explicit source text palette. Final screenshots
show the exact requested dark `#060913` body / `#F8FAFF` text /
`#121B33` card / `#6B8CFF` tint and light `#F7F8FF` body /
`#0B0D12` text / `#EEF1FF` card / `#1E4DFF` tint.

This is **not** SentenceStudio source-styling acceptance. The affected
hybrid pages currently compute a Bootstrap `system-ui` family on iOS;
neither those original font assets nor any app theme was bundled in this
bridge. Exact custom PostScript faces, if chosen by a real source rule,
must be registered by the consumer. Font baseline/introspection was not
captured, and older iOS/macOS versions below 26 use a line-spacing
approximation instead of `.lineHeight(.multiple(factor:))`. The rotated
iPhone's 750pt usable width is below the source 768pt breakpoint, so it
does not prove wide-iPad 2/3-column layout. The head must read stored
appearance, apply its source default before presenting, retain SwiftUI
nodes during state refresh to keep focus, and exercise the actual app
states. All 177 source states and 56 discrepancies remain open.

## Native source-style preview.8 C# consumer

The final `Microsoft.SwiftUI.0.1.0-preview.8.nupkg` has SHA-256
`e6c3c87b1a5a8fdd18c3088d95c24e4024cf7f421c0f83f04f620edad8ba74c8`.
The same independent C# `App.main()` probe restored that exact package in
an isolated local NuGet cache, rebuilt with the installed RC1 SDK, and
updated only its distinct bundle on simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`. The app-bundled framework was
inspected for all new native selectors before installation. The complete
`.build/style-v8-ui-full.xcresult` passed **9/9** XCTest cases: all five
preview.7 tests and four new narrow source-style tests. Swift tests
passed 13/13; managed macOS tests passed 33/33.

The new tests declare every view in C#. AX still exposes real SwiftUI
`Form`/`List` as native `CollectionView` with distinct child IDs and a
true focused `SecureTextField`. `WithNativeListColors` produced dark
canvas `#060913` and grouped rows `#121B33` in **both** collections,
replacing the measured system `#000000`/`#1C1C1E` pair without replacing
native rows. A mounted dark-to-light change produced light `#F7F8FF`
canvas and `#EEF1FF` rows. Native `Text` prompts produced exact dark
`#93A3C7` and light `#7A8699` placeholder pixels; a secure entry invoked
its managed C# change callback while retaining secure AX role and focus.
Both styled navigation bars measured 54pt instead of the old 106pt
large-title band, and native Back remained available. The label-first
button correction yielded Next/Done AX heights of 58pt and a composed
visibility-button height of 44pt, each with a single stable button ID
and functional near-edge tap.

The opt-in sign-in `Scroll` centers its shorter source-like card within
the available phone viewport. With a keyboard, the same native scroll
reaches its lower controls; with the Accessibility1 Dynamic Type launch
setting, the secure field remains focusable and the submit button stays
reachable above the keyboard. Labeled screenshots and AX trees are under
`files/swiftui-source-styling-20261003/style-bridge-v8-captures/`; public
signatures and framework/package hashes are in `style-bridge-contract-v8.json`
there. No product bundle, user database, physical device, canonical app
simulator, original font file, or preview.3-preview.7 archive was changed.

This proves the **bridge**, not source parity in SentenceStudio. The head
must apply these opt-in modifiers to its actual forms, lists, buttons,
titles, and sign-in screen and rerun its own canonical captures; no
wide-iPad run or pre-iOS 18/pre-macOS 15 centered-scroll fallback was
exercised in this iOS 26.5 probe. All 177 required source states and
56 findings remain under the existing acceptance process.

## Opt-in button, circle and underline preview.9 C# consumer

The distinct `com.davidortinau.microsoftswiftui.appmainprobe20261003`
bundle was rebuilt from the SHA-verified preview.9 package with the
preexisting RC1 .NET SDK and updated **without uninstall** on simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7` (iOS 26.5,
402 x 874 points). All **12/12** XCTest cases passed, zero skipped:
the nine prior App.main/style checks and three new checks for the
C#-authored button, Circle and Text paths. Native Swift tests passed
15/15 and macOS managed host tests 35/35. The exact current result
bundle is `.build/style-v9-ui-final-package.xcresult`; screenshots and AX trees
are in the session
`files/swiftui-source-styling-20261003/style-bridge-v9-package-captures/`.

The native button style kept a single >=44-point SwiftUI Button per
action, including an image-and-text label and near-edge activation.
In light mode, a clear outline showed white `[255,255,255]` over the
body and `[238,241,255]` over a card; in dark mode it showed
`[6,9,19]` and `[18,27,51]` over those different surfaces. Its
one-point borders sampled `[107,120,136]` light and
`[147,163,199]` dark. A filled secondary sampled exact source
`#F8F9FA` light and `#121B33` dark. The Flatly-like primary disabled
fill sampled `[118,129,141]` on white, within one channel unit of the
expected 0.65 composite, rather than the old plain-style 0.5 fade.
Dark disabled fill sampled `[72,94,173]`. Direct-disabled and
parent-disabled native Buttons were both reported disabled and neither
delivered a tap callback. Radius 6, 25 and 2.4 points differed at
their measured corner pixels without adding any border outside the
native hit region.

Six native Circle fills each measured 8 x 8 points with starts at
`x=167,179,191,203,215,227`, four-point gaps and a centered
68-point group at normal and Accessibility XL; the group moved from
`y=225` to `y=265` but its circle dimensions did not change.
Only the current step carried the `Step 3 of 6` label. Native
`Text.underline` visibly changed pixels when toggled on a retained
link label; its containing Button was one 378 x 44-point AX target at
normal and 378 x 56 points at XL. Its near-edge tap reached the
managed action without signing out or changing an account.

This is **microconsumer rendering proof**, not accepted product
source parity. The separate SentenceStudio head must consume this
exact package, remove its provisional opaque outline/SF-symbol dots,
apply source font/padding/colors in C#, and recheck the affected
original-source states with independent review. The full 177-state
scope, 56 findings and zero exclusions are unchanged. No VoiceOver
spoken-audio check, earlier iOS/macOS runtime, iPad layout, or
canonical SentenceStudio bundle was tested by this probe.

## Opt-in Button border width in a native C# consumer

`Microsoft.SwiftUI.0.1.0-preview.10.nupkg` has SHA-256
`9f884dd4a9ad91fd059a1ff02d3fab870c4e0e3cbc66ffe3deb80d14f9cf1d8f`.
The distinct C# `App.main()` probe restored that exact package into
`.build/style-source-preview10-nuget`, rebuilt on the installed .NET RC1
SDK, and updated only
`com.davidortinau.microsoftswiftui.appmainprobe20261003` on simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`. A verified copy of its prior
sandbox is in `.build/style-v10-probe-preinstall-data`. No uninstall or
canonical application install occurred.

The 13/13 native XCTest result at `.build/style-v10-ui-final.xcresult`
includes the prior 12 regression cases and a C#-authored source-style
Vapor Light Button case. On its real SwiftUI Buttons the selected
`#3CF281` stroke measured **6 pixels/2 points** and the omitted-width
sibling **3 pixels/1 point** on the same 3x simulator. The `#1A0933`
background shows through both clear fills. The button with width set
before appearance produced the same result; changing its width on the
mounted node repainted the stroke at one point and then two without
changing its single accessibility identifier. All five probe Buttons
measured at least 44 points, including direct and inherited disabled
controls; both disabled taps left the managed status unchanged and
their border pixels matched a single 0.65 composite. An enabled near-edge
tap reached the C# action without performing a quiz score or account
operation. Screenshots, AX snapshots and measured pixel runs are saved in
`files/swiftui-source-styling-20261003/style-bridge-v10-attachments/`
in the rebuild session; the exact signatures and hashes are recorded in
`style-bridge-contract-v10.json` alongside them. This isolated bridge
proof does not certify the actual SentenceStudio head or all selected
themes; the separate head owner must consume the new archive, apply
the source-dependent two-point width and rebuild its current app.

## Eight-axis SwiftUI Button and disabled compositing probe

The new `Microsoft.SwiftUI.0.1.0-preview.11.nupkg` is SHA-256
`8dbe6a0ecb041c00ee1f47534fc578cc24efb9bb75b94f8a8176fb2593424b72`.
The isolated C#-authored `App.main()` probe rebuilt under the installed
.NET RC1 SDK with that *exact* local package in
`.build/style-source-preview11-final-nuget`, and only its existing
`com.davidortinau.microsoftswiftui.appmainprobe20261003` bundle was
updated in place on iOS 26.5 simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`. Fourteen existing regular
sandbox files were hash-backed-up at `.build/style-v11-probe-preinstall-data`
before the first install; a second 12-file backup at
`.build/style-v11-probe-pre-hitfix-data` preceded the final in-place
update. The built and installed executable, managed binding DLL, and
arm64 native framework match byte-for-byte.

The focused two-case native XCTest result in
`.build/style-v11-final-focus.xcresult` measured a real **88 x 44-point**
Sketchy source-style Button with eight independent CSS radii. At its actual
bounds, the common overlap factor was `44/280`; both light and dark
screenshots sampled the exact selected green border at all four quarter
arcs and the correct backdrop just outside each. On the same mounted
Button, changing to eight zero axes made its corner square; restoring the
eight values restored the ellipse while the sibling was unaffected. Native
AX exposed exactly one stable Button per identifier, the enabled near-edge
tap reached the C# callback, and direct/inherited disabled near-edge taps
did not. A sibling with no ellipse setter retained its circular corner.
The same final focused Sketchy case measured a **six-pixel** source border
at 3x versus **three pixels** on the unchanged one-point sibling, and
sampled four additional points where the ellipse is green but the old
circle remains the parent background, for **each** of light and dark.
This rules out a plausible scalar-corner substitution on the actual
native Button, not merely in shape math.

The same focused run measured Brite's enabled black border and green
`#A2E436` fill, and its disabled *equal-color* border and fill after a
single 65% opacity layer. On white, both disabled border positions and
the fill were exactly RGB `(194,237,124)`; on dark `#212529` they were
exactly `(117,161,49)`. Before grouping, the disabled light border had
been `(173,231,78)` while the fill was `(194,237,124)`. The new result
is produced by the generic `compositingGroup()` renderer change, not a
product-specific replacement color or a fake button. Screenshots, AX
hierarchies, and measured samples are under
`.build/style-v11-final-focus-attachments` and the session's
`style-bridge-v11-final-attachments/` evidence folder. No auth submission, quiz score,
backend, physical device, or canonical SentenceStudio bundle was touched.
The complete existing-plus-new iOS XCTest suite also passed 15/15 with
zero skips or failures in `.build/style-v11-final-full.xcresult`; the
source-style pixel tests above are included in this final suite.
Seven matched native screenshot samples against the preview.10 full suite
were **identical** before and after the renderer fix (maximum RGB channel
delta zero): Flatly's light/dark disabled fills, Vapor's default border and
transparent interior, its source two-point border, and both direct and
inherited disabled borders. Bounds came from each run's own native AX tree,
not hard-coded screenshot coordinates; see
`.build/style-v11-final-prior-button-pixels.json`.
The post-test data check confirmed zero user-owned Documents, Preferences
or SQLite files before and after, an unchanged container metadata plist,
and reverified 14-file and 12-file preinstall backups **after the final
15-case suite**. OS scene and snapshot caches can change during a normal
in-place install or UI run.
One additional diagnostic assertion, which was **not** a required source
acceptance case, tested taps 1pt inside the AX rectangle but outside the
painted ellipse; the native Button activated even with
`.contentShape(.interaction, ellipse)` applied to its label. Preserve the
approved >=44pt native accessible hit target rather than substituting a
Text gesture, clipping the label, or claiming strict silhouette-only
hit testing. The final passing suite checks in-shape near-edge activation
and direct/inherited disabled no-action.
The native source has a 36px visual small-button minimum versus the
preserved 44pt native hit target: this isolated microconsumer does **not**
claim full product-source parity. The product head remains read-only here
and needs its own rebuild, saved-state run, data check, and independent
visual review after consuming the new package.

## Opt-in source Brite real-Button shadow preview.12

The local `Microsoft.SwiftUI.0.1.0-preview.12.nupkg` is SHA-256
`e87d5052c466daec5f3f8f26ab95f35f8fb8eed6f95953a5e364d544d6097101`.
The dedicated C# `App.main()` probe restored this exact archive to a
new, project-local NuGet cache (only verified installed RC1 runtime packs
were reused), rebuilt on .NET RC1/Xcode 26.6, and updated **in place**
on iOS 26.5 simulator `DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`.
The installed executable, managed binding and thinned native framework
match the rebuilt app byte-for-byte. The sandbox's 16 preinstall regular
files were backed up and reverified after all tests; user-owned
Documents, Preferences and Application Support contained zero files
before and after. No uninstall, simulator reset or product bundle change
occurred.

In `.build/style-v12-focused-edge.xcresult`, both focused cases passed
on the real native Buttons. On a 3x, 402×874pt iPhone, independent reads
of the screenshot and AX bounds measured **nine device pixels** beyond
each right and bottom edge in both modes for the enabled Brite primary,
direct/inherited disabled primary and transparent underlined link. The
outline-secondary analog had no resting shadow. Disabled green
fill/border remained `(194,237,124)` on white and `(117,161,49)` on
dark; its once-faded black shadow measured `(89,89,89)` on white and
`(12,13,14)` on dark. Comparing sampled interior/link glyph pixels
before/after changing only the mounted shadow gave maximum RGB delta
zero. A synthetic eight-axis Button's hard shadow followed its
curved shape rather than a rectangle; a legacy rounded surface kept
X=0 and Y=3. The same Button identifiers, >=44pt hit heights,
enabled near-edge actions and direct/inherited disabled no-action
remained intact. The final `.build/style-v12-full.xcresult` passed
**17/17** existing and new iOS XCTest cases; native Swift NodeTests
passed **18/18**, and signed macOS managed cases passed **37/37**.
The seven previously recorded Flatly/Vapor nonshadow pixel samples
and AX bounds remain unchanged (maximum RGB delta zero) against
preview.11; see `.build/style-v12-prior-button-pixels.json` and
`.build/style-v12-measured-shadow-pixels.json`.

This proves the reusable bridge and its isolated C# consumer, **not**
the current SentenceStudio head. Its owner must opt in only where the
pinned source class retains Brite's late `.btn` shadow, rebuild the
normal app, check protected account data, and revalidate its real
source states. The existing 177 required states, 56 open findings
and zero exclusions have not changed.

## Clear stroke and intrinsic wrapping: preview.14 isolated probe

The existing managed `App.main()` iOS probe exposes
`probe.v13.open` under Resources without touching the production
SentenceStudio app, authentication or SQLite. On that screen,
`probe.v13.link.clear` and `probe.v13.link.opaque` use otherwise
identical real SwiftUI Buttons: the clear two-point stroke reserves
four extra points in both width and height without painting the
parent in either light or dark mode. The link uses a left SF Symbol,
no underline, source ellipse, one identifier, 44pt minimum hit
region, and its own managed action. Direct and parent-disabled clear
links keep native disabled action/no-op behavior.

The same screen exercises `probe.v13.joined.first` and
`probe.v13.joined.second`: the second starts exactly two points
before the first border box ends. At that seam, the selected first
Button owns the hit; after `probe.v13.joined.select.second` updates
selection on the mounted group, the second owns it without new
Buttons or changed identifiers. `probe.v13.choice.0` through
`probe.v13.choice.5` remain original ordered children as the group's
finite width changes between 320 and 195pt. The XCTest cases
capture accessibility frames, color-scheme screenshots and both
normal and accessibility-XL reflow. The native Swift tests measure
actual `NSHostingView` intrinsic box dimensions and test ordered
two-point row geometry; managed tests retain the old ABI/defaults
and validate misuse and mounted callbacks. The native group applies
explicit accessibility sort priority in original child order so
selected visual stacking does not move the selected child to the
end of assistive traversal. The first preview.13 focused run detected
this defect; the unchanged preview.13 archive is not the deliverable.
XCTest `allElementsBoundByIndex` reports the rendered hierarchy's index
order, not VoiceOver's sort order: a raised selected child can still
appear last in that raw query. The iOS probe asserts six distinct
accessible IDs, logical row placement, seam actions and changing row
counts; native `ForEach(id: \.id)` keeps original children, and Apple's
`accessibilitySortPriority` orders assistive reading independently of
z-order. A direct VoiceOver swipe-order or hardware-keyboard focus
session on the eventual SentenceStudio head remains a separate check;
neither this package nor the XCTest hierarchy accepts that product
state on the head owner's behalf.

Only use the dedicated simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7` and
`com.davidortinau.microsoftswiftui.appmainprobe20261003` for an
in-place update, after backing up that probe's sandbox. Do not
uninstall any app. Preview.14 is a **bridge-only** check: the native
SentenceStudio iOS owner must install the exact archive into a newly
frozen head, retain original first/last corner assignments, verify
real-screen J-02/J-03 and outstanding starter-loading/feedback
captures, and check protected app data. The original 177 required
states, 56 findings and zero exclusions remain unchanged here.

## Source group layout: preview.15 isolated C# probe

The current local archive is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.15.nupkg`
(SHA-256 `f3932e0562c32ed1bd46435f993614925ffd8333a11f22da15a74af9a5108392`).
It was rebuilt with Xcode 27.1 and the globally selected .NET 11 RC2
SDK; the binding package passes the existing source/binary/native
inventory verifier. The distinct C# `App.main()` consumer restores
that exact archive from the bridge-local feed, not preview.14. Its
normal app build rejected Xcode 27.1 because the RC2 Apple pack
recommends 27.0; the successful **build invocation only** used
`-p:ValidateXcodeVersion=false` under Captain's scoped approval. The
SwiftUI app then launched and passed seven focused UI tests on the
existing iOS 26.5 simulator after an in-place install and verified
persistent-data backup; no uninstall or device reset occurred.

The first original Button has AX frame `{{12,485},{71,44}}` and the
second `{{82,485},{147.7,44}}` with a one-point overlap and intrinsic
total width 217.7pt. After the same managed group node receives
`WithButtonGroupLayout(1, fillAvailableWidth: true)`, those unchanged
original IDs have frames `{{12,485},{151.3,44}}` and
`{{162.3,485},{227.7,44}}`: the unequal original width bases each
gain about 80pt and the group fills exactly x12..390 (378pt).
First-then-second shared-seam taps invoked the correct retained C#
callbacks after the mounted selection changed, and there was one
accessible real Button for each ID. The same consumer displayed
`Group guards passed` after executing the managed default-`-1`,
finite/nonnegative, wrong-kind and disposed-group checks on the
installed C# binary. The earlier two-point selected seam, six-child
intrinsic wrap and Accessibility XL row reflow, clear-versus-opaque
two-point link border box, Brite disabled-alpha/shadow and Sketchy
elliptical-corner cases passed alongside it. The native Swift suite
passed 23/23, including finite-proposal placement and a wrapping
group with fill requested but no width expansion.

The current UI test screenshots and accessibility snapshots are in
`.build/style-v15-final-attachments/`; the xctest result is
`.build/style-v15-final-rc2-xcode27.xcresult`, with the matching
compiled-source/PDB/Mach-O freezes in `.build/style-v15-pretest-v2-*.json`.
The app's protected Documents/Preferences/Application Support files
remained unchanged. The macOS managed test executable did **not**
run: the selected RC2 test restore requires unavailable RC2 macOS
CoreCLR/ASP.NET runtime packs, and a bounded installed-RC1 fallback
also lacks matching macOS 27 Apple packs. The iOS checks exercise the
new managed API but do not substitute for the entire macOS suite.
No SentenceStudio head is rebuilt or accepted by this probe. Its
owner must map source-one-point versus Brite/Sketchy-two-point
groups in the actual Dashboard/Resources/Onboarding pages and
recapture its own protected data and source-style states; the
approved 177 required states, 56 open findings and zero exclusions
remain.

## Four-screen SwiftUI source bridge: local preview.16

The canonical source-built library package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.16.nupkg` (SHA-256
`b8115fcbac6c91808f0db3fc381d2d819bd2bf958d9fd6f76ed5603981cfbeaa`).
The existing C# `App.main()` microconsumer used its own bundle ID
`com.davidortinau.microsoftswiftui.appmainprobe20261003` on iOS 26.5
simulator `DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`. It restored from a
fresh `.build/style-v16k-consumer-nuget` cache and rebuilt the current
Debug executable. Installation was **in place**, after a content-hashed
backup of its existing data sandbox. Executable, PDB, managed DLL and
Swift framework hashes match the current installed bundle; the freeze is
`files/ios-four-screen-parity-20261004/privatebridge-preview16-probe-freeze-r12.json`
in the active rebuild session's private evidence.

`.build/p16-six-capabilities-and-baseline.xcresult` passed **6/6**
focused XCTest cases on this binary (four new bridge cases and prior
Light/Dark/viewport/progress and ButtonGroup regression cases).
Its retained screenshots and accessibility trees are exported under
`.build/p16-six-capabilities-and-baseline-attachments/`:

- Native `Divider()` draws a horizontal separator; actual
  `ProgressView()` is an indeterminate ActivityIndicator, not a 0% bar.
  The completed card's real Button remains tappable with a struck-through
  title and reduced opacity. The old Light/Dark and source ButtonGroup
  actions still work.
- The generated one-pixel PNG bytes decode through ImageIO/CoreGraphics
  into a real bounded image with generic alt text. Decode failure
  triggers `decodeFailed`, not an SF Symbol replacement. A 70%-detent
  Info sheet scrolls and dismisses; separate full-screen photo shows
  aspect-fit pixels before pinch/drag and closes by X or backdrop. Quiz
  Enter and Type Correct submit through the **same retained field**.
- The Quick Add option list is anchored below its focused field and
  floats over, not inline among, `Form` rows. It is a native scrolling
  list capped at 288pt (18rem); the current screenshot
  `p16-quick-add-selected-last-before-scroll` shows the selected Create
  option above the keyboard alongside the other candidates, with no
  blank margin. XCTest checked its accessible selected trait and the
  actual blue selected pixels. Tapping an option calls one C# handler;
  tapping an outside Form row dismisses.
- A full-root starter scrim visibly blocks underlying tabs/actions and
  shows a real spinner; it never dismisses itself. The independent
  centered resource Delete modal shows X, Cancel, red Delete and a
  backdrop. X, Cancel and backdrop invoke no destructive callback;
  only explicit confirm invokes a **dummy** C# callback. No real
  resource was deleted; the head owner must verify its draft separately.

For **genuine keyboard** validation, Mobile Canvas sent USB HID
41 (Escape), 81 (Down), 82 (Up) and 40 (Return) to the same installed
binary. Managed Quick Add reported `Key: Escape` and closed,
`Highlighted: 0` then `Highlighted: 2`, and exactly one
`Chosen: 2, count: 1` on Return. Typing `again` *without retapping*
the field reopened suggestions. The exact input/observed-value record
and binary hashes are in
`files/ios-four-screen-parity-20261004/privatebridge-preview16-hid-keyboard-final.json`
in private session evidence. **XCUITest's synthetic `typeKey(Return)`
did not invoke `onSubmit` even for an unrelated ordinary TextField**
and its synthetic Escape did not reach this focused field; do not use
those negative results as evidence that actual HID keys fail. Swift
native `NodeTests` passed 28/28 and the package verifier passed all
three architecture slices; the macOS managed executable remains
unrun because its matching RC2 runtime packs are unavailable.

This proof belongs to the isolated bridge, not the real SentenceStudio
native-head pages, owner-scoped media, Resource mutations or the
approved 177-state/86-gap human parity review. The iOS page owners must
consume the exact current package/API contract and recapture their own
head's source-backed journeys.

## Preview.17 isolated iOS consumer: source-blocking additions

The canonical local package is
`artifacts/Microsoft.SwiftUI.0.1.0-preview.17.nupkg`, SHA-256
`0dca7b0fd103697581c19bb85186ae2a813f270ac581c2c97dcb1f47e309df22`.
The exact previous preview.16 SHA-256
`b8115fcbac6c91808f0db3fc381d2d819bd2bf958d9fd6f76ed5603981cfbeaa`
remains unchanged. The package contains 13 verified entries and the
source-built iOS simulator XCFramework fat slice has SHA-256
`b6ff035ac531a34974348e4d71510159f198fb1e0aeb3ea5b37b0e5dbdeeb5fd`.
Only README.md changed between the final package and the last
unconsumed, tested preview.17 draft: all 12 binary/metadata entries
match byte-for-byte. **Use a fresh NuGet cache** when restoring this
canonical SHA; old private preview.17 drafts are not interchangeable.

The C# consumer uses `com.davidortinau.microsoftswiftui.appmainprobe20261003`
on dedicated iOS 26.5 simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7` only. It restored the
package into bridge-local `.build/p17-consumer-axrep-nuget` and built
in `.build/p17-app-artifacts-axrep` without touching SentenceStudio
projects or generated outputs. The built and installed executable
SHA-256 was
`7f06c5c5d3a8f5c07763433604a6ed01959784afb02dd29e5303006caa398944`;
PDB
`0c300401293f364bd1792985ab66fea49320d5b19095c65acc0abcee5773c26b`,
managed DLL
`e13b7e3ef3062e413cf692e5dc082734c991bc7c1f88fc105962554dae5a5a09`,
and installed thinned Swift framework
`7de9070df764af6786a12fdcbfae317e9e428763cbf8d7486cd7b9ef9b7bffdd`
also matched their corresponding built files byte-for-byte. The
simulator thins the packaged fat framework to arm64, so **do not**
expect its installed SHA-256 to equal the universal slice SHA-256.
In-place installs followed hashed sandbox backups. Four OS SplashBoard
snapshot caches were invalidated on install and two OS Saved Application
State files changed during UI tests; their earlier bytes remain in
the backup. All other 12 pre-existing persistent files still match.
Nothing was uninstalled, reset or deleted from app-owned data.

Native Swift `NodeTests` passed **30/30**. The following **separate**
current-binary XCTest results each passed **1/1**:

- `.build/p17-ui-placeholder-axrep.xcresult`: the same real SwiftUI
  TextEditor shows the source-like muted placeholder when empty,
  remains focusable, accepts `word`, and restores the placeholder
  after deleting those characters. The accessible hierarchy has
  exactly **one** editor (`probe.p17.sentence.input`) and **no**
  separate placeholder StaticText; empty, focused, typed and cleared
  screenshots/trees are under
  `.build/p17-ui-placeholder-axrep-attachments/`.
- `.build/p17-ui-back-axrep.xcresult`: closed Quick Add→native Back,
  reopen; focused suggestions→native Back, reopen; no stuck UI or
  stale delayed callback. Screenshot/tree under
  `.build/p17-ui-back-axrep-attachments/`.
- `.build/p17-ui-quickadd-axrep.xcresult`: preserved preview.16
  anchored selected candidate, arrow-key selection, one tap callback,
  follow-on input and outside dismissal. Screenshot/tree under
  `.build/p17-ui-quickadd-axrep-attachments/`.

An initial combined Xcode UI run stalled and was stopped; its isolated
app main thread sampled idle rather than at the previous Resource
Form trap. Two subsequent draft-package attempts exposed a duplicate
TextEditor accessibility element, then a separately accessible
placeholder; the final SwiftUI empty accessibility representation
removed both defects. The three scoped tests above passed against
the final unchanged runtime payload. This is **not** a whole-suite
pass. The macOS managed test executable was not run because matching
RC2 macOS runtime packs are unavailable; no pack was installed.

This microconsumer has synthetic state, not Kaylee's owner-bound
Resource data or the normal app's nested Alert/FileImporter/Menu
host. The normal SentenceStudio head must independently prove Back,
typing, and Delete-open/X/Cancel/backdrop with its own fresh native
output—**never** confirm a real delete just to test the dialog. The
.NET iOS native sidecar extraction uses stamps and `unzip -u`;
preview.16 previously left preview.15 framework bytes in a head's
generated `obj` despite a correct NuGet restore. Compare the
**universal extracted XCFramework binary** to the final package
before embedding, then check loaded selectors and source/PDB identity
in the actual head. Fresh project-separated output paths avoid
stale extraction without clearing user caches or app data. No
approved source-parity screen state or product trap is accepted from
this standalone proof.

## Preview.18 horizontal-grid C# consumer (October 5, 2026)

The distinct existing probe bundle
`com.davidortinau.microsoftswiftui.appmainprobe20261003` was updated
**in place**, without an uninstall, on the dedicated simulator
`DCE0A3B6-47A1-477E-AD65-ECB4F2AB0FD7`. Its display name is
`SSBridgeProbe`; its bundle ID and test-only account behavior are
unchanged. Before installation, all 18 persistent sandbox files were
backed up with hashes under
`.build/p18-preinstall-dce-20261005-persistent/`; no database or WAL
was present. Four OS-managed SplashBoard snapshots were invalidated by
the iOS install, while the other 14 backed-up files retained their
bytes at the immediate post-install check. After the UI tests, two
OS-owned Saved Application State files changed; the remaining 12
backed-up files were unchanged. No app-owned file was lost and no
database or WAL appeared.

The probe restored exactly
`Microsoft.SwiftUI.0.1.0-preview.18.nupkg`
(`5697e528d8f1114bd9d9cd0995c15eb8548e6613329e3bf92f058e37c6cabf26`)
into its own fresh NuGet cache, used fresh native-generated outputs,
and rebuilt on globally selected .NET
`11.0.100-rc.2.26478.115`/Xcode `27.1` with an
invocation-only `ValidateXcodeVersion=false`. The built and installed
probe executable, PDB and signed arm64 framework match byte-for-byte.
The packaged iOS simulator XCFramework, generated native XCFramework
and **fresh** consumer extraction also match byte-for-byte; app signing
changes the thinned arm64 framework's file hash but its UUID matches
the current package and differs from the preserved preview.17
framework.

The focused `.build/p18-grid-ui-final.xcresult` passed **2/2**
XCTest cases. The C#-declared five-cell header, two rows, real
TextField, native Type Picker, tags and Remove Buttons rendered as a
single SwiftUI horizontal ScrollView/Grid. On the 402-point phone,
the initially off-screen Remove column became tappable after one
horizontal swipe while column starts stayed aligned. In the
874-point-wide landscape viewport, the parent native Form scrolled
vertically to reveal the full grid; all five columns fit without
stacking, with the Type column at least 120 points. Selecting Phrase
invoked the C# callback. Removing the first row during an active
TextField edit retained the second field's keyboard focus and value;
`good afternoon!?` and the Phrase selection survived. Tapping both
actual Remove Buttons removed their respective rows, preserved the
header, and native Back→reopen rebuilt a responsive grid.
Screenshots and accessibility trees are in
`.build/p18-grid-ui-final-evidence/` (phone left, phone scrolled,
landscape, retained-focus state).

The two first-pass test failures were landscape test setup, not a
bridge layout defect: the Form's grid row began at y=393 of a
402-point-tall landscape viewport. Merely testing partial
`isHittable` did not scroll it into view. The final assertion
scrolls the native Form's CollectionView before inspecting the
wide grid. This standalone synthetic probe does **not** create or
modify a learning resource and cannot accept source parity for
the actual Resource Add screen; its native-head owner must wire the
five real source columns into this API and verify that journey.
The separate direct macOS managed test runner cannot build without
the known missing RC2 macOS CoreCLR runtime packages; the C# iOS
probe and package verifier provided the executable managed proof for
this iOS slice.

### Preview.18 Type Picker border hit limitation (October 5, 2026)

The actual Resource Add table uses `style.Input(Picker(...))` with
8-point vertical/12-point horizontal padding, a rounded border,
minimum height and flexible width inside the grid's 120-point Type
column. Its native menu opens at the center but not seven points
inside the left edge of the visible border. This is a **separate,
unresolved hit-region defect**, not a reversal of the horizontal-grid
layout result above.

The existing C# probe now mirrors that Type control's modifier values.
With the exact canonical preview.18 archive and current
executable/PDB/native UUID verified, its focused
`.build/picker-hit-p18-red.xcresult` reproduced **both** left and
right border taps failing while the center opened the real
Word/Phrase/Sentence Picker. The cell's native AX Button reports a
120-point frame; that frame is not evidence that the menu's internal
button responds throughout it. Three narrowly scoped SwiftUI-only
source candidates were tried **without creating a new package**:
flexible button sizing with an outer `contentShape` (neither edge
worked); a real Picker custom label containing the existing padding
(left worked, right failed); and a custom label with `HStack`/`Spacer`
(left worked, right still failed, including after horizontal panning
moved the control away from the viewport edge). The candidate UI logs
and source fingerprints are recorded in the current parity session's
`privatebridge-picker-hit-contract.json`. None of these three Picker
candidates is included in the separate composed-Menu preview.19
archive. Each candidate kept the
native Picker, bound options and callback; none proved the full hit
region, so none was published as a Picker fix.

The bridge native source, generated XCFramework/provenance and the
dedicated installed probe were returned to their verified preview.18
identities without uninstalling or resetting data. The focused
edge-hit XCTest remains a **known red regression case** until a
source-backed SwiftUI solution is found; do not treat the earlier
2/2 grid-layout result as full Resource Add parity. Apple's
[`PickerStyle.menu`](https://developer.apple.com/documentation/swiftui/pickerstyle/menu)
documents the native button and selection, while
[`frame(minWidth:)`](https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:))
positions a view in an invisible constrained frame and
[`contentShape`](https://developer.apple.com/documentation/swiftui/view/contentshape(_:_:eofill:))
sets that view's hit-test shape; neither promises that an internally
composed menu button will adopt a larger decorative border.

## Preview.19 composed native Menu consumer: device proof pending

The same C# `App.main()` probe has an additional test-only
Resource Edit-shaped surface declared by
`BuildComposedMenuProbe` in `tests/Microsoft.SwiftUI.AppMainProbe.iOS/Program.cs`.
Its two fields use the new
`Menu(SwiftView label, params SwiftView[] actions)` overload with
Button actions; their inner label is a C# `HStack` with selected text,
trailing chevron, source-like padding and an outline. The C# Button
callbacks set exact option indices, the retained label and
`Menu.Text` accessible value, visible checkmark opacity and selected
accessibility traits. They do not use an account, database, UIKit or
app-authored popup. The separate `Menu(string, buttons)` and
Resource Add Picker routes retain their old code paths.

The compiled probe consumed the exact distinct preview.19 archive in
an isolated NuGet cache with fresh native extraction; its built
executable/PDB SHA-256 values are
`1abfdf48ef9c7dec14c9dec1a49d173a41346c0f1ec6ae075d3e55e9227a4c17`
and `458006a175afc93f7ee3168efea8e3dcf16aeb84cdccced8fb2f3c41a4937025`.
Its current-binary signed native framework has arm64 UUID
`D4B8FFF9-4E65-3437-B328-17C4D952984D`.
The focused XCTest `testP19ComposedNativeMenuSelectOwnsBothEdgesAndSelection`
was authored but is **unrun**: the only authorized DCE simulator was
deleted between preview.18 and preview.19; the remaining sim977
belongs to Captain's normal app and was not touched. A generic
simulator destination could not build the XCTest runner. Do not
interpret compiled code, native structural tests or an AX label as
proof of a physical tap. Root owns a later approved device-bound
left/right border tap and visual/AX check on the actual mutable
Resource Edit MediaType and Language controls; preview.19 alone
does not accept either screen.

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
