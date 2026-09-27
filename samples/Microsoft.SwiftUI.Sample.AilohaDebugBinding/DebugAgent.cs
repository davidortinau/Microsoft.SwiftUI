#if DEBUG
#if IOS
using NativeView = UIKit.UIView;
#elif MACOS
using NativeView = AppKit.NSView;
#endif

namespace Microsoft.SwiftUI.Sample.AilohaDebugBinding;

public static class DebugAgent
{
    private static Action<bool, string>? _startResult;

    public static void Start(Action onStarted)
    {
        ArgumentNullException.ThrowIfNull(onStarted);
        _startResult = (started, error) =>
        {
            if (started)
            {
                Console.WriteLine("Ailoha Debug agent started.");
                onStarted();
            }
            else
            {
                Console.Error.WriteLine($"Ailoha Debug agent failed to start: {error}");
            }
            _startResult = null;
        };
        MicrosoftSwiftUIAilohaDebug.Start(_startResult);
    }

    public static void TagTextInput(NativeView root, string placeholder, string identifier)
    {
        ArgumentNullException.ThrowIfNull(root);
        ArgumentException.ThrowIfNullOrWhiteSpace(placeholder);
        ArgumentException.ThrowIfNullOrWhiteSpace(identifier);
        if (!MicrosoftSwiftUIAilohaDebug.TagTextInput(root, placeholder, identifier))
            Console.Error.WriteLine($"Ailoha Debug agent could not tag input {identifier}.");
        else
            Console.WriteLine($"Ailoha Debug agent tagged input {identifier}.");
    }

    public static void Stop() => MicrosoftSwiftUIAilohaDebug.Stop();
}
#endif
