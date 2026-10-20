using Microsoft.SwiftUI.Native;

namespace Microsoft.SwiftUI;

public enum SwiftUIScenePhase
{
    Unknown = 0,
    Active = 2,
    Inactive = 3,
    Background = 4
}

public enum SwiftFontStyle
{
    Body,
    LargeTitle,
    Title,
    Title2,
    Headline,
    Subheadline,
    Caption
}

public enum SwiftButtonStyle
{
    Automatic,
    Bordered,
    BorderedProminent,
    Plain
}

public enum SwiftPickerStyle
{
    Automatic,
    Menu,
    Segmented
}

public enum SwiftColorScheme
{
    System = 0,
    Light = 1,
    Dark = 2
}

public enum SwiftHorizontalAlignment
{
    Leading = 0,
    Center = 1,
    Trailing = 2
}

public enum SwiftDynamicTypeSize
{
    XSmall = 0,
    Small = 1,
    Medium = 2,
    Large = 3,
    XLarge = 4,
    XXLarge = 5,
    XXXLarge = 6,
    Accessibility1 = 7,
    Accessibility2 = 8,
    Accessibility3 = 9,
    Accessibility4 = 10,
    Accessibility5 = 11
}

public enum SwiftTextKey
{
    ArrowUp,
    ArrowDown,
    Enter,
    Escape
}

public enum SwiftPhotoLoadState
{
    Loading,
    Displayed,
    Failed
}

public sealed record SwiftPickerOption(string Value, string Title);

public sealed record SwiftImportedFile(byte[] Data, string Name, string MimeType);

public static class SwiftUIApplication
{
    private static SwiftView? _runningRoot;
    private static Action<nint>? _sceneCallback;

    public static void Run(SwiftView root, Action<SwiftUIScenePhase>? onScenePhaseChanged = null)
    {
        SwiftView.RequireMainThread();
        ArgumentNullException.ThrowIfNull(root);
        if (_runningRoot is not null)
            throw new InvalidOperationException("A SwiftUI application is already running.");
        root.RequireHostRoot();
        var native = root.Native;
        root.ClaimHost(native);
        _runningRoot = root;
        _sceneCallback = value => onScenePhaseChanged?.Invoke((SwiftUIScenePhase)value);
        try
        {
            MSUBridge.RunApplication(native, _sceneCallback);
        }
        finally
        {
            root.ReleaseHost(native);
            _sceneCallback = null;
            _runningRoot = null;
        }
    }
}
