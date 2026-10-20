# Microsoft.SwiftUI

Standalone, MIT-licensed SwiftUI bindings and native lifecycle for pure .NET
applications on `net11.0-ios` and `net11.0-macos`. This library has no MAUI,
Comet, or Yoga project/package dependency. The new `SwiftUIApplication.Run`
starts a real SwiftUI `App.main()`/`WindowGroup` with a managed `SwiftView` tree;
it needs no app-authored UIKit controller, app delegate, or window. Earlier
`SwiftUIHost` APIs remain for compatibility with apps that explicitly embed a
SwiftUI tree into UIKit (`UIHostingController`) or AppKit (`NSHostingView`).

The Swift package targets iOS 17+ and macOS 14+. The build produces iOS device
(arm64), iOS simulator (arm64/x86_64), and universal macOS (arm64/x86_64)
XCFramework variants. Native sources and Objective-C binding definitions are
in `native/` and `src/`; generated binaries are ignored and must be built
before using or packing the binding. See
[`docs/build-and-provenance.md`](docs/build-and-provenance.md) for the exact
build, tests, generated artifact hashes, and the local .NET 11 RC binding-tool
runtime mismatch.

## Use the C# facade

```csharp
using Microsoft.SwiftUI;
using Views = Microsoft.SwiftUI.SwiftUI;

var count = 0;
SwiftView? navigation = null;
var label = Views.Text("Count: 0");
navigation = Views.NavigationStack(Views.Form(
    Views.Section("Practice",
        label,
        Views.Button("Add", () => label.Text = $"Count: {++count}"),
        Views.Button("Detail", () => navigation!.Push("detail",
            Views.List(Views.Text("Detail")))))));
var root = Views.TabView(Views.Tab("Practice", "book", navigation));
SwiftUIApplication.Run(root, phase => Console.WriteLine($"Scene: {phase}"));
```

Call `Run` once from the Apple main thread; it blocks in native `App.main()`.
The bridge retains the managed root and scene callback for that lifetime.
`NavigationStack` owns a real bound SwiftUI path; `Push(route, destination)`
changes that path and native interactive Back updates `NavigationPath` and
calls the optional `onPathChanged` handler. Each `Tab` can contain its own
`NavigationStack`, preserving its own path across tab selection. `Form`,
`Section`, `SecureField`, string-valued `Picker`, `List`, `LazyVGrid`,
`Searchable`, `Toolbar`, `Menu`, `Alert`, `ConfirmationDialog` and `Sheet`
render with the corresponding SwiftUI controls, not translated UIKit widgets.
`FileImporter` accepts plain text or CSV and returns at most 1 MiB of bytes
from a coordinated security-scoped URL; its error callback receives
`accessDenied`, `tooLarge`, or `readFailed`, never a file path.

## Horizontal native grid (preview.18)

`SwiftUI.HorizontalGrid(IReadOnlyList<double> columnMinWidths,
SwiftView headerRow, params SwiftView[] rows)` renders one SwiftUI
`ScrollView(.horizontal)` containing a native `Grid` of `GridRow`s. Pass
`HStack` nodes with the same number of cells for the header and each data
row. The `HStack` is a structural row, not a nested horizontal layout;
give it an accessibility identifier before attaching it. The native grid
shares each column's measured width across its header and data cells.
Zero means natural width; a positive value sets that column's minimum in
SwiftUI points (for example, 120 for a type picker). `Spacing` on the
returned grid sets visual inter-column and inter-row spacing, not an
extra inset. The containing screen owns its normal safe-area and visual
padding; the header and rows pan together on a narrow viewport.

```csharp
var grid = Views.HorizontalGrid([0, 0, 120, 0, 0],
    Views.HStack(Views.Text("Target"), Views.Text("Native"),
                 Views.Text("Type"), Views.Text("Tags"), Views.Text("Remove"))
        .WithAccessibilityIdentifier("terms.header"),
    Views.HStack(targetField, nativeTerm, typePicker, tags, removeButton)
        .WithAccessibilityIdentifier("terms.row.123"));
grid.Spacing = 8;
```

The caller owns the cell controls, labels, source widths, callbacks and
row order. A retained cell keeps its SwiftUI identity when a different row
is removed. To remove a data row, call `grid.RemoveAt(index)` with
`index >= 1`, then dispose or reparent the detached row; the header
cannot be removed. To change a row's cells, detach it first. Invalid
column counts, non-finite/negative minimums and mismatched row sizes
throw on the C# side rather than showing a malformed grid. Existing
vertical `Scroll` and flexible `LazyVGrid` are unchanged.

## Composed native Menu label (preview.19)

`SwiftUI.Menu(SwiftView label, params SwiftView[] actions)` keeps the
existing `Menu(string title, params SwiftView[] actions)` unchanged.
The new overload accepts a caller-authored `SwiftView` as the **first
structural child**, followed by one or more real Button actions. It
renders SwiftUI's `Menu(content:label:)`, not a substitute popup or an
app-authored Button. A composed menu's label is framed to fill the
available width, leading-aligned, and uses a rectangular interaction
shape **inside** the native Menu label. Attach a styled `HStack` with a
leading selected-value `Text` and a trailing chevron `Image`; put the
control's visual padding and outline on that label, not outside the
Menu. The native Menu decides the adaptive options presentation.

```csharp
var label = Views.HStack(selectedText.WithFlexibleWidth(),
        Views.Image("chevron.down"))
    .WithFlexibleWidth()
    .WithPadding(8, 12, 8, 12)
    .WithRoundedSurface(lightFill, darkFill, radius,
                        lightBorder, darkBorder, borderWidth);
var menu = Views.Menu(label, optionButtons)
    .WithAccessibilityLabel(fieldLabel)
    .WithAccessibilityIdentifier(identifier)
    .WithFlexibleWidth();
menu.Text = selectedValue;
```

The caller owns selection and localized options: each Button calls
its exact option-index callback; set the selected Button's
`WithAccessibilitySelected(true)` and include a native checkmark
image in that option's label. After a choice, update the retained
`selectedText.Text` and `menu.Text` (the Menu's accessible value), and
refresh the option-selection marks. A composed label cannot itself
be a Button; neither overload accepts an empty or non-Button action
list. An unrelated `Menu("More", buttons)` still renders its original
title and actions. This bridge capability does not change Resource
Add, any existing Picker, or an application's stored data.

## Inline literal text (preview.21)

`SwiftUI.InlineText(leading, trailing)` takes exactly two `SwiftUI.Text`
nodes and renders them as **one** native SwiftUI `Text` using literal
`AttributedString` runs. Style each run with the existing `WithTypography`
and paired `WithForegroundColor` methods; updates to either mounted run,
including its font and colors, update the combined text. Text and newlines
are used verbatim, not interpreted as Markdown. The caller supplies any
separating whitespace in the trailing text, only when that text is present.
The combined text wraps at its available width and grows vertically without
truncation; place a separate action after it in a horizontal stack to keep
that action trailing and independent of wrapping.

```csharp
var term = Views.Text(target).WithTypography(17, 700, 1.29);
var translation = Views.Text(native.Length == 0 ? "" : "  " + native)
    .WithTypography(17, 400, 1.29);
var row = Views.HStack(
    Views.InlineText(term, translation).WithFlexibleWidth(),
    removeButton);
```

Non-text children, reused/hosted children, and disposed children are rejected
before attaching; the two styled runs remain caller-owned children of the
one native text node. This opt-in primitive does not alter ordinary `Text`,
`HStack`, the iOS app lifecycle, or stored content.

## Source-scale SwiftUI styling

Preview.7 adds only the primitives needed by a source-styled C# SwiftUI
screen. The consumer owns its fonts, appearance preference, and color
tokens; the bridge neither bundles font files nor selects a brand or theme.
Use `WithTypography(pointSize, weight, lineHeightMultiple, postScriptName)`
with a **null** name for SwiftUI's system font, or a registered exact
PostScript name when the source actually uses a custom face. Numeric
weights are CSS-style 100–900 in steps of 100. System-font sizes scale
relative to Dynamic Type's body style; custom faces use
`Font.custom(_:size:relativeTo:)`. Pass a persisted application font-scale
factor in the source point size *once* where its rules call for it.
`WithFont(SwiftFontStyle)` is still available, but semantic `LargeTitle`
is not a replacement for a specified 24-point source title. Exact
`.lineHeight(.multiple(factor:))` is used on iOS/macOS 26 and later;
older supported OS versions use `.lineSpacing` as an approximation.

`PreferredColorScheme` updates a mounted presentation; set the source
default before `SwiftUIApplication.Run` and update it when the preference
changes. `WithForegroundColor`, `WithBackgroundColor`, and `WithTintColor`
accept a light/dark `#RRGGBB` pair, resolved from SwiftUI's environment.
`WithPadding(top, right, bottom, left)` applies internal visual padding.
`WithFlexibleWidth(maxWidth, alignment)` fills the available width and
centers or aligns a capped surface. `WithRoundedSurface` adds a filled
SwiftUI rounded rectangle with an optional paired stroke;
`WithShadow` applies a paired-color shadow to that surface, not to its
text; it also accepts a real Button already configured with
`WithButtonAppearance` (see below). If a composed-label `Button` itself is the card, use its native
`.Plain` button style; the whole padded label remains the hit region.

`SwiftUI.Progress(value, total, thickness, accessibilityLabel)` is a
determinate SwiftUI `ProgressView` with a source-height
`ProgressViewStyle`; `WithTintColor` and `WithProgressTrackColor` select
its paired colors. Zero total resolves to 0% without division. Mutate
`Value`/`ProgressTotal` on the retained node instead of replacing it.
`SwiftUI.BottomInset(scrollContent, footer)` uses SwiftUI
`safeAreaInset(edge: .bottom, spacing: 0)` so the OS owns keyboard and
home-indicator spacing once; apply only *visual* per-edge footer padding.
`OnViewportChanged` reports the mounted container's width and
`SwiftDynamicTypeSize` to C#; a retained grid's `GridColumns` can then
change without replacing child controls. `WithAdaptiveStack(width)` on
an `HStack` switches to an identity-preserving vertical `AnyLayout` when
the container is narrower or Dynamic Type reaches XL. These APIs do
not reconcile application-owned nodes that the consumer removes.

Preview.8 adds four opt-in corrections for native source-styled pages.
`WithNativeListColors(lightCanvas, darkCanvas, lightRow, darkRow)` on a
`Form` or `List` hides its system scroll-content background and sets a
paired native `listRowBackground` for its rows and sections. The controls
remain a real SwiftUI `Form`/`List`, including their native virtualization.
`WithNavigationTitle(title).WithInlineNavigationTitle()` selects SwiftUI's
inline iOS title without changing native Back or the navigation path;
macOS retains its normal window title. `WithCenterWhenShort()` on a
`Scroll` vertically centers content only while it fits the available
viewport, and leaves taller content scrollable when the keyboard or
Dynamic Type reduces that viewport. `WithPlaceholderColor(light, dark)`
uses a native SwiftUI `Text` prompt on `TextField` and `SecureField`; the
secure field remains secure and focused input keeps the same node.
`WithMinimumHeight(points)` on a `Button` now sizes its actual native
label and hit region before the outer accessibility identifier is applied,
instead of enlarging only the frame outside its tappable content. Without
these opt-in modifiers, existing presentation defaults stay unchanged.

Preview.9 adds three more opt-in SwiftUI primitives. Use
`WithButtonAppearance(lightFillHex, darkFillHex, lightBorderHex, darkBorderHex,
cornerRadius, disabledOpacity: 0.65)` on a real `Button` for a one-point
rounded border and paired fills. Pass **both fills as null** for an actual
`Color.clear` interior that shows any parent background; an empty string
is not a clear-color value. The radius must be finite and positive, and
disabled opacity must be finite and within 0...1. A custom native
`ButtonStyle` owns the shape, entire label hit region, and a single
enabled/disabled opacity. It takes precedence over `WithButtonStyle` in
either call order; an unconfigured button keeps its prior native style.
Put typography, foreground, padding and any source role colors on the
C# label. Do not also use `WithRoundedSurface` on that label, which would
draw a second shape. SwiftUI `.disabled` and the native action guard
still reject disabled actions, including an inherited disabled parent.

`SwiftUI.Circle(diameter, lightFillHex, darkFillHex)` renders a native
filled `Circle` inside an exact square frame; its size does not track
Dynamic Type. A circle with `WithAccessibilityLabel` is one labeled
accessibility element; unlabeled circles are decorative. For an onboarding
step row, the consumer supplies its own source colors, an `HStack` spacing
of 4, and a label on only the current dot. `WithUnderline(underlined: true)`
works only on `Text` and renders native `Text.underline`. It can style a
text child of an existing icon-and-text `Button` without changing that
button's action, minimum hit height, or accessibility role. These
primitives do not choose an application theme or change existing controls.

An icon-only `Button` with `WithButtonAppearance` may opt into
`WithButtonCircle(diameter)` (local preview.23). This Button-only modifier
requires a positive finite diameter and a custom appearance; a minimum
height greater than the diameter is rejected. It frames the real SwiftUI
Button label square **before** its custom style paints a native Circle fill,
stroke and hit shape, so intrinsic SF Symbol widths and bordered-button
padding cannot stretch the painted shape. Existing buttons retain their
previous styling when the modifier is omitted. The caller supplies its own
source-derived diameter, colors, symbol and accessible name.

For a decorative SF Symbol inside a fixed-size button, opt the `Image` into
`WithFixedSymbolSize(points)` (local preview.24). The positive finite point
size uses SwiftUI's system symbol font without `@ScaledMetric`; otherwise
images retain the existing `.imageScale(.large)` behavior. This Image-only
modifier does not change Dynamic Type for text, button hit bounds, actions,
accessibility labels, or other image callers. The app chooses the symbol
size from its source style and appearance preference.

Preview.10 keeps the existing six-argument `WithButtonAppearance` signature
and adds `WithButtonBorderWidth(double points)` for a source rule requiring
more than the default **1-point** inner stroke. The value must be finite and
strictly positive; only a `Button` accepts it. The setter alone does not
activate a custom appearance or change the old `.Plain`, `.Bordered`, or
`.BorderedProminent` styles. It affects the real SwiftUI `Button` only after
`WithButtonAppearance` opts in, regardless of whether width, appearance,
or `WithButtonStyle` was called first. Changes on a mounted button publish
and redraw its border without replacing the button or its action; other
buttons retain their own widths. For the pinned Vapor Light stylesheet's
2px `.btn-outline-success` border, a C# caller can write:

```csharp
Views.Button(label, onOverride)
    .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8)
    .WithButtonBorderWidth(2)
    .WithMinimumHeight(44);
```

The null fill pair preserves transparency. Widths are SwiftUI points, so
the 2-point stroke spans about six physical pixels on a 3x iPhone.

Preview.11 adds one optional `Button` setter for distinct horizontal and
vertical axes at each corner, in CSS order:
`WithButtonEllipticalCornerRadii(topLeftX, topLeftY, topRightX, topRightY,
bottomRightX, bottomRightY, bottomLeftX, bottomLeftY)`. All eight point values
must be finite and nonnegative. Zero is allowed; a corner with either axis
zero is square. The setter does not activate a custom style on its own, and
may precede or follow `WithButtonAppearance` or update an already-mounted
button. Without it, the original scalar `RoundedRectangle` stays unchanged.

The opt-in SwiftUI shape uses the **actual button border box**: one CSS
corner-overlap factor, the minimum of `1`, `width/(topLeftX+topRightX)`,
`height/(topRightY+bottomRightY)`, `width/(bottomLeftX+bottomRightX)`, and
`height/(topLeftY+bottomLeftY)`, scales all eight axes together. A side whose
axis sum is zero imposes no constraint. Its `InsettableShape` keeps that
original factor when `strokeBorder` insets the path, reducing each normalized
axis by the inset instead of recalculating against an inner box. The same
closed shape draws the fill, inner stroke, and `contentShape` of **one real
SwiftUI Button**. For the Sketchy `.btn-sm` eight-axis rule and 2px stroke,
an opted-in C# caller can write:

```csharp
Views.Button(label, onOverride)
    .WithButtonAppearance(null, null, "#28A745", "#12B886", 15)
    .WithButtonBorderWidth(2)
    .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
    .WithMinimumHeight(44);
```

`WithButtonAppearance` still requires its original positive scalar radius;
the ellipse replaces that radius only for the opted-in button. The generic
custom button style now composites its label, fill, and stroke **before** its
disabled opacity. For equal fill and border colors this fades the entire
button once, rather than drawing a separately faded border over an already
faded fill. Disabled actions and inherited `.disabled` still use SwiftUI and
the existing native action guard. A source `.btn-sm` may use a 36px visual
minimum; the 44pt native hit target is an explicit platform choice, not a
claim of pixel-identical source layout.
Existing callers that omit `WithButtonBorderWidth` still draw one point.
The existing minimum hit region, disabled 0.65 opacity/action guard,
corner shape, and accessibility identifier remain owned by the same Button.

Preview.12 adds one opt-in horizontal shadow offset on a real Button:
`WithButtonShadowOffsetX(double points)`. Call `WithButtonAppearance` first,
then `WithShadow(lightHex, darkHex, radius, opacity, offsetY)` and the new
setter in either order. A configured Button can use `WithShadow` without
adding a rounded surface to its label. The X offset defaults to zero;
the existing five-parameter `WithShadow` signature and rounded-surface
callers keep their behavior. X must be finite, but may be negative. Only
Buttons with an active custom appearance accept this setter.

The Button's existing fill/stroke shape—not a second Button or its text
glyphs—casts the shadow. A clear fill still has a box shadow outside its
border while remaining transparent inside. For the frozen Brite `.btn`
resting rule (`3px 3px 0 0`), apply only to caller classes that retain the
rule; Brite `.btn-outline-secondary` and `.btn-outline-success` reset it:

```csharp
Views.Button(label, onSubmit)
    .WithButtonAppearance("#A2E436", "#A2E436", "#000000", "#000000", 4)
    .WithButtonBorderWidth(2)
    .WithShadow("#000000", "#000000", 0, 1, 3)
    .WithButtonShadowOffsetX(3)
    .WithMinimumHeight(44);
```

The source's resting margin and inverse transform cancel; do not shift
the Button or its hit region. Disabled opacity still composites the
label, fill, stroke, and shadow once.

Preview.14 permits **both** border arguments of the existing
`WithButtonAppearance` to be `null` for a matched `Color.clear` stroke.
One null and one color, empty strings, and malformed colors are rejected;
the original six-parameter CLR signature and 0.65 disabled default remain.
Use it with the existing `WithButtonBorderWidth(2)` and eight-axis shape
when the source declares a transparent two-point elliptical border:

```csharp
var label = Views.HStack(Views.Image("arrow.left.square"),
    Views.Text("Logout").WithUnderline(false))
    .WithPadding(6, 16, 6, 16).WithMinimumHeight(44);
label.Spacing = 4;
var link = Views.Button(label, onLogout)
    .WithButtonStyle(SwiftButtonStyle.Plain)
    .WithButtonAppearance(null, null, null, null, 25)
    .WithButtonBorderWidth(2)
    .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
    .WithMinimumHeight(44);
```

Only a matched clear border reserves its invisible stroke in the
intrinsic box: two points on **each** side, inside the native Button's
ellipse-shaped fill and interaction area. Existing colored-border
callers, their label padding, the one-point default, IDs, actions, and
disabled behavior are unchanged. The app supplies source typography,
colors, padding, and the appropriate light/dark mode; this bridge does
not choose a theme.

For source `.btn-group` controls, use
`SwiftUI.ButtonGroup(SwiftView[] buttons, bool wraps = false,
int? selectedIndex = null)`. It accepts one or more existing real Button
nodes, owns them without changing their UUIDs or handlers, and rejects
non-Buttons, duplicate/parented/disposed children, and invalid selection
indices. `Spacing` on other stacks still rejects negatives; the group's
default two-point overlap is not a general layout-offset API.

```csharp
var pair = Views.ButtonGroup([firstButton, lastButton], selectedIndex: 0);
pair.SelectedIndex = 1; // Also accepts -1 for no selected child.
var choices = Views.ButtonGroup(orderedSixButtons, wraps: true, selectedIndex: 2)
    .WithFlexibleWidth();
```

The narrow SwiftUI `Layout` measures each Button's intrinsic size,
uses the finite proposed width to choose rows, and by default places subsequent
original children two points left of the preceding border box. The
negative left margin still applies to the first **original** child
that happens to wrap onto another row, matching the source selector;
reflow never restarts first/last corner semantics. Selected, hovered,
focused, and pressed children rise above ordinary neighbors at a shared
seam; equal priorities retain source order. Keep source colors, corner
radii, border width, shadows, and group selection in the caller.
Group membership is fixed after construction; you can change
`SelectedIndex` and child content/style without replacing their
identities. An unbreakable label can exceed a narrow viewport just as
its CSS min-content box can.

The source-only follow-up `WithButtonGroupLayout(double overlapPoints,
bool fillAvailableWidth = false)` is **not in the archived preview.14
package**. After a source-matching framework and binding package are
built and independently verified, callers can set one point for ordinary
Bootstrap borders or two for Brite/Sketchy without changing HStack spacing.
The modifier accepts only a live group and finite nonnegative overlap. For
the nonwrapping Dashboard pair, pass `fillAvailableWidth: true` and
`WithFlexibleWidth()` so a finite 378-point proposal distributes only the
positive surplus equally **on top of** each original Button's intrinsic
width. It does not equalize unequal label widths or shrink below their
intrinsic sizes. Wrapping preference groups always retain their intrinsic
flow, even if this flag is set; existing callers without the modifier
retain preview.14's intrinsic two-point behavior. This is not a general
CSS flexbox implementation or an additional painted button.

## Four-screen iOS source capabilities (local preview.16)

Preview.15 remains immutable. Preview.16 is a local source-built package,
not a claim of product parity or a published NuGet release. These eight
narrow additions unblock the
approved Dashboard, Vocabulary Quiz and Learning Resources iOS journeys
without providing app storage, media authorization, a UIKit renderer, or
other activity screens:

- `SwiftUI.Divider()` is a genuine adaptive SwiftUI separator. Put it
  directly above an existing `BottomInset` footer.
- `SwiftUI.ImageFromBytes(byte[], genericAccessibilityLabel, maxHeight: 160,
  onRendered, onFailed)` and `SwiftUI.ZoomablePhoto(byte[],
  genericAccessibilityLabel, onRendered, onFailed)` decode at most 8 MiB
  with ImageIO/CoreGraphics to a bounded CGImage, then render a native
  SwiftUI `Image(decorative:scale:)` with explicit generic accessibility
  metadata. `PhotoLoadState` is `Loading`, `Displayed` or `Failed`. A malformed
  image calls `onFailed("decodeFailed")`; no symbol or empty-data success is
  substituted. `onRendered` fires once on actual appearance, not at decode.
  The caller owns URI authentication, owner validation, cache, photo/text
  learning-value policy and the already-validated bytes.
- The existing `Sheet` accepts optional
  `.WithSheetDetentFraction(0.7)` on iOS, retaining its existing dismiss
  callback. `SwiftUI.FullScreenPhotoCover(content, ZoomablePhoto(...),
  closeButton, onDismissed)` uses a separate SwiftUI full-screen cover.
  Its caller-authored close Button retains its identifier/action; backdrop
  and Escape also close it. Zoom stays in `1...4` with bounded pan.
  macOS builds use a native SwiftUI sheet for these new iOS-only modal
  contracts because `fullScreenCover` is unavailable there; no macOS
  product-parity claim is implied.
- `.OnSubmit(Action)` on an existing `TextField` submits the same focused
  node used for the quiz answer and correction. It does not change
  `TextEditor`, secure input or other fields.
- `.OnKeyPress(Func<SwiftTextKey,bool>)` supports Quick Add arrows, Enter
  and Escape on its existing `TextField`, consuming only a handled key.
  Hardware Return routes through `.onKeyPress`, while the software Return
  reaches SwiftUI `.onSubmit`; a handled Enter does not submit twice.
  `SwiftUI.QuickAddSuggestions(completedForm, fieldAutomationId,
  suggestions, onDismissed)` anchors one independent maximum-288pt
  scrolling list below that field above form rows. Candidate Buttons keep
  their IDs and can mark the active option with
  `.WithAccessibilitySelected()`. While the popup is open in a `Form`,
  SwiftUI reserves the same 288pt of scroll space above the keyboard so
  the focused field and highlighted option remain visible; it releases
  that space on dismissal. The caller retains candidate/owner identity
  and restores `FocusRequested` after attaching.
- `SwiftUI.StarterBlockingOverlay(rootTabView, localizedStatus)` has an
  `IsPresented` state that draws a full-root opacity-0.6 scrim with a native
  indeterminate progress indicator and disables background hit-testing.
  It never runs or dismisses the starter command.
- `SwiftUI.ResourceDeleteConfirmation(content, title, message, closeLabel,
  cancelLabel, deleteLabel, onCancelled, onDelete)` provides a separate
  centered modal, X, Cancel, backdrop and explicit destructive action.
  `IsPresented` and `DeletePending` are state-driven; the latter blocks
  repeated confirmation until the caller's owner-safe write finishes.
  Cancellation does not delete or discard the caller's draft. This does not
  replace conflict alerts or file importers. On iOS,
  `.WithTransparentDeleteBackdrop()` opts this confirmation into a clear
  full-screen presentation background so its existing dimming scrim reveals
  the page beneath; the default and other presentations remain unchanged.
- `.WithStrikethrough()` on `Text`, `.WithOpacity(0.75)` on a completed
  Button and `SwiftUI.IndeterminateProgress(localizedLabel)` retain real
  SwiftUI controls; indeterminate progress never reuses a zero-valued
  determinate bar.

All new view creation, callbacks and mutation follow the existing main-thread,
single-parent and `Dispose` rules. The native photo path uses no
app-authored UIKit or `UIImage`, even inside the bridge.

### Multiline placeholder (local preview.17)

`SwiftUI.TextEditor(text, onChanged)` keeps its original signature and
behavior. Opt in on that same editable node with
`.WithTextEditorPlaceholder(localizedText)`; an empty string removes the
placeholder. `.WithPlaceholderColor(lightHex, darkHex)` now accepts a
`TextEditor` as well as text and secure fields, so the caller can provide
its source tertiary-text palette. SwiftUI keeps one real multiline
`TextEditor` bound to the original text. A non-interactive,
accessibility-hidden `Text` overlay with an empty accessibility
representation appears only when that binding is empty,
including while focused and again after clearing. It inherits the
editor's font and outer form styling. On iOS, its placement follows
the documented 8-point top text-container inset and 5-point line
fragment padding rather than a page-specific offset. No UIKit control
or replacement input is authored; macOS visual parity is not claimed.

At the pinned `59c72262` source, the applicable placeholders are the
Quiz sentence editor (`VocabQuiz.razor:168–173`), the Resource Add
description, transcript, translation and bulk-vocabulary editors
(`ResourceAdd.razor:36,78,83,93`), and Resource Edit bulk vocabulary
(`ResourceEdit.razor:216–217`). The Resource Edit description,
transcript and translation editors have **no** source placeholders and
should keep the unmodified `TextEditor` behavior. Native-head callers
own localization and target-word formatting; the library supplies no
English UI text.

### Opt-in TextEditor scroll background (local preview.20)

Use `.WithTextEditorScrollBackgroundHidden()` on a real `TextEditor` when
placing it over a caller-styled input surface outside a native `Form`.
The underlying SwiftUI editor uses `.scrollContentBackground(.hidden)` so
the caller's background shows through; its text binding, placeholder,
accessibility and focus stay on the same control. The default remains
the system TextEditor background, and passing `false` restores it.
The modifier rejects other view kinds.

The local package and native unit tests have been built; its isolated
C# iOS consumer rendered the placeholder, typed and cleared the same
focused editor, and exposed only that editor in the accessibility tree.
This is not a published release or proof of actual SentenceStudio
screen parity. The canonical preview.16 archive remains immutable.

### Retained Quick Add during Resource Form removal (local preview.17)

An eligible Resource Form mounts the Quick Add wrapper even when its
suggestion list is closed. A native navigation pop or replacement can
clear that wrapper's children while SwiftUI still retains its view for
an update. The retained view now snapshots exactly its content and
suggestion nodes on each body evaluation; if either has been removed,
it renders no stale content. Overlay, scroll, outside-tap and focus
callbacks use captured nodes and check that the wrapper still owns
those same nodes before acting. The mounted field, candidate order,
selected-state scrolling and existing dismissal callbacks are
unchanged. A passing native regression covers mounted, selected and
removed-node states. The isolated C# iOS consumer also passed native
Back both before and after opening suggestions, then reopened normally.
This does not certify that the observed iOS Resource Form trap is fixed:
the real app must run its own source-attested journey.

For the legacy explicit-host APIs, keep the `SwiftView` root alive for the lifetime of its hosted controller or
view: it owns child nodes and managed callbacks. Each root has exactly one
active host and cannot be reparented, rehosted, or disposed while hosted.
After removing the host from its `UIWindow` or `NSWindow`, call
`SwiftUIHost.DetachController(root, controller)` on iOS or
`SwiftUIHost.DetachView(root, view)` / `DetachController(root, controller)` on
macOS, then dispose or reparent the root. These operations must run on the
Apple main thread. Detach suspends native callbacks across the root and
replaces the old host's SwiftUI root with empty content before disposing it:
even a native-retained host cannot redisplay the detached node. A later
attachment or newly created host restores callbacks. Explicit teardown breaks
native-block/managed-callback retention cycles. `RemoveAt`
and `Clear` detach children without disposing them: native callbacks are
suspended across the detached subtree. Adding children to a detached container
keeps their callbacks suspended; attaching it to an active tree or hosting it
as a root restores them. Keep a detached node only if you will reparent or
host it; otherwise dispose it on the main thread. Factories reject duplicate,
already-parented, actively hosted, disposed, and null children before
attaching any of them.

Construct and update views on the Apple main thread. The facade includes
text, button actions, single- and multiline input, horizontal and vertical
stacks, scrolling and lists, navigation links, sheets, SF Symbol images,
toggles, sliders with a required semantic accessibility label, pickers, focus,
accessibility identifiers, and observable text/selection/child-tree state
updates. Invalid kinds, ranges, parenting, and off-main-thread access fail
explicitly. No backend layout engine is bundled.

`samples/Microsoft.SwiftUI.Sample.Shared/FeatureScreen.cs` is the shared
feature declaration. The sibling `Sample.iOS` scene delegate and
`Sample.MacOS` AppKit delegate are deliberately separate shells. The managed
test executable exercises the native bridge, callbacks, host creation, and
shared feature tree. The isolated `tests/Microsoft.SwiftUI.AppMainProbe.iOS`
exercises `SwiftUIApplication.Run` with managed tabs, a form, secure input,
a bound picker, a list, navigation, and native Back in its own bundle.
An optional
[Ailoha Debug sample integration](docs/ailoha-debug.md) uses an externally
verified official binary **only in the iOS and macOS sample hosts**; it is
not a reusable-library or Release dependency. Ailoha has its own non-MIT
binary distribution license. See the
[consumer verification handoff](docs/consumer-verification.md) for the
remaining SwiftUI button automation gap.

This work is derived from generic concepts at a pinned MIT `maui-labs`
revision. The upstream notice and extraction boundary are in
[`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md).
