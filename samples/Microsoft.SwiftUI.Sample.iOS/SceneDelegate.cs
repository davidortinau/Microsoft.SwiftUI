using Foundation;
using Microsoft.SwiftUI.Sample.Shared;
using UIKit;
#if AILOHA_DEBUG
using Microsoft.SwiftUI.Sample.AilohaDebugBinding;
#endif

namespace Microsoft.SwiftUI.Sample.iOS;

[Register("SceneDelegate")]
public sealed class SceneDelegate : UIResponder, IUIWindowSceneDelegate
{
    private FeatureScreen? _screen;
    private UIViewController? _hostController;

    [Export("window")]
    public UIWindow? Window { get; set; }

    [Export("scene:willConnectToSession:options:")]
    public void WillConnect(UIScene scene, UISceneSession session, UISceneConnectionOptions options)
    {
        if (scene is not UIWindowScene windowScene)
            throw new InvalidOperationException("The sample requires a window scene.");

        _screen = new FeatureScreen();
        _hostController = SwiftUIHost.CreateController(_screen.Root);
        Window = new UIWindow(windowScene) { RootViewController = _hostController };
        Window.MakeKeyAndVisible();
#if AILOHA_DEBUG
        DebugAgent.Start(() =>
        {
            if (Window is { } window)
            {
                DebugAgent.TagTextInput(window, "Name", "sample.name");
            }
            else
                Console.Error.WriteLine("Ailoha Debug agent started after the iOS sample window closed.");
        });
#endif
    }

    [Export("sceneDidDisconnect:")]
    public void DidDisconnect(UIScene scene)
    {
#if AILOHA_DEBUG
        DebugAgent.Stop();
#endif
        if (_screen is { } screen && _hostController is { } controller)
        {
            if (Window is { } window)
            {
                window.Hidden = true;
                window.RootViewController = null;
            }
            SwiftUIHost.DetachController(screen.Root, controller);
        }
        Window = null;
        _hostController = null;
        _screen?.Dispose();
        _screen = null;
    }
}
