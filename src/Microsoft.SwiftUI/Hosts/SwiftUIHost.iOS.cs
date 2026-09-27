#if IOS
using Microsoft.SwiftUI.Native;
using UIKit;

namespace Microsoft.SwiftUI;

public static partial class SwiftUIHost
{
    public static UIViewController CreateController(SwiftView root)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        root.RequireHostRoot();
        var controller = MSUBridge.HostController(root.Native);
        root.ClaimHost(controller);
        return controller;
    }

    public static void DetachController(SwiftView root, UIViewController controller)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        ArgumentNullException.ThrowIfNull(controller);
        root.RequireHostOwner(controller);
        if (controller.ViewIfLoaded?.Window is not null)
            throw new InvalidOperationException("Remove the controller from its window before detaching the SwiftUI root.");
        if (!MSUBridge.DeactivateHost(controller))
            throw new InvalidOperationException("The controller is not a SwiftUI bridge host.");
        root.ReleaseHost(controller);
        controller.Dispose();
    }
}
#endif
