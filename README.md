# Microsoft.SwiftUI

Standalone, MIT-licensed SwiftUI bindings and native hosting for pure .NET
applications on `net11.0-ios` and `net11.0-macos`. This library has no MAUI,
Comet, or Yoga project/package dependency. iOS uses `UIHostingController`;
native macOS uses `NSHostingView` or `NSHostingController`. The same C# feature
tree can be hosted by either platform shell.

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
var label = Views.Text("Count: 0").WithAccessibilityIdentifier("counter");
var root = Views.Navigation("Example", Views.VStack(
    label,
    Views.Button("Add", () => label.Text = $"Count: {++count}"),
    Views.Slider("Practice level", 0, 1, 0.5)));

// iOS UIWindow.RootViewController:
var controller = SwiftUIHost.CreateController(root);

// Native macOS NSWindow.ContentView instead:
// var view = SwiftUIHost.CreateView(root);
```

Keep the `SwiftView` root alive for the lifetime of its hosted controller or
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
explicitly. No backend layout engine or application lifecycle is bundled.

`samples/Microsoft.SwiftUI.Sample.Shared/FeatureScreen.cs` is the shared
feature declaration. The sibling `Sample.iOS` scene delegate and
`Sample.MacOS` AppKit delegate are deliberately separate shells. The managed
test executable exercises the native bridge, callbacks, host creation, and
shared feature tree. An optional
[Ailoha Debug sample integration](docs/ailoha-debug.md) uses an externally
verified official binary **only in the iOS and macOS sample hosts**; it is
not a reusable-library or Release dependency. Ailoha has its own non-MIT
binary distribution license. See the
[consumer verification handoff](docs/consumer-verification.md) for the
remaining SwiftUI button automation gap.

This work is derived from generic concepts at a pinned MIT `maui-labs`
revision. The upstream notice and extraction boundary are in
[`docs/ATTRIBUTION.md`](docs/ATTRIBUTION.md).
