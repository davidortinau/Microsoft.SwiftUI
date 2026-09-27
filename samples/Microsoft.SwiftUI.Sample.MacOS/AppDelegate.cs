using AppKit;
using CoreGraphics;
using Foundation;
using Microsoft.SwiftUI.Sample.Shared;
#if AILOHA_DEBUG
using Microsoft.SwiftUI.Sample.AilohaDebugBinding;
#endif

namespace Microsoft.SwiftUI.Sample.MacOS;

[Register("AppDelegate")]
public sealed class AppDelegate : NSApplicationDelegate
{
    private FeatureScreen? _screen;
    private NSView? _hostView;
    private NSWindow? _window;

    public override void DidFinishLaunching(NSNotification notification)
    {
        _screen = new FeatureScreen();
        _hostView = SwiftUIHost.CreateView(_screen.Root);
        _window = new NSWindow(
            new CGRect(0, 0, 700, 560),
            NSWindowStyle.Titled | NSWindowStyle.Closable | NSWindowStyle.Resizable,
            NSBackingStore.Buffered,
            false)
        {
            Title = "SwiftUI Bridge Sample",
            ContentView = _hostView
        };
        _window.Center();
        _window.MakeKeyAndOrderFront(null);
        NSApplication.SharedApplication.Activate();
#if AILOHA_DEBUG
        DebugAgent.Start(() =>
        {
            if (_window?.ContentView is { } view)
                DebugAgent.TagTextInput(view, "Name", "sample.name");
            else
                Console.Error.WriteLine("Ailoha Debug agent started after the macOS sample window closed.");
        });
#endif
    }

    public override bool ApplicationShouldTerminateAfterLastWindowClosed(NSApplication sender) => true;

    public override void WillTerminate(NSNotification notification)
    {
#if AILOHA_DEBUG
        DebugAgent.Stop();
#endif
        if (_screen is { } screen && _hostView is { } view)
        {
            if (_window is not null)
                _window.ContentView = new NSView();
            SwiftUIHost.DetachView(screen.Root, view);
        }
        _window = null;
        _hostView = null;
        _screen?.Dispose();
        _screen = null;
    }
}
