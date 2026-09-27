#if MACOS
using AppKit;
using Microsoft.SwiftUI.Native;

namespace Microsoft.SwiftUI;

public static partial class SwiftUIHost
{
    public static NSView CreateView(SwiftView root)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        root.RequireHostRoot();
        var view = MSUBridge.HostView(root.Native);
        root.ClaimHost(view);
        return view;
    }

    public static void DetachView(SwiftView root, NSView view)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        ArgumentNullException.ThrowIfNull(view);
        root.RequireHostOwner(view);
        if (view.Window is not null)
            throw new InvalidOperationException("Remove the view from its window before detaching the SwiftUI root.");
        if (!MSUBridge.DeactivateHost(view))
            throw new InvalidOperationException("The view is not a SwiftUI bridge host.");
        root.ReleaseHost(view);
        view.Dispose();
    }

    public static NSViewController CreateController(SwiftView root)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        root.RequireHostRoot();
        var controller = MSUBridge.HostController(root.Native);
        root.ClaimHost(controller);
        return controller;
    }

    public static void DetachController(SwiftView root, NSViewController controller)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        ArgumentNullException.ThrowIfNull(controller);
        root.RequireHostOwner(controller);
        if (controller.View.Window is not null)
            throw new InvalidOperationException("Remove the controller from its window before detaching the SwiftUI root.");
        if (!MSUBridge.DeactivateHost(controller))
            throw new InvalidOperationException("The controller is not a SwiftUI bridge host.");
        root.ReleaseHost(controller);
        controller.Dispose();
    }
}
#endif
