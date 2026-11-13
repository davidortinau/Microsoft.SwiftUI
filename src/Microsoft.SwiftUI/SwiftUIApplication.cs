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

/// <summary>A tab's role (SwiftUI <c>TabRole</c>).</summary>
public enum SwiftTabRole
{
    /// <summary>An ordinary tab.</summary>
    None,
    /// <summary>
    /// SwiftUI <c>TabRole.search</c>: the tab sits apart from the others (iOS 26:
    /// the trailing slot of the tab bar) and keeps its own title and symbol.
    /// </summary>
    Search
}

/// <summary>When an iOS 26 tab bar minimizes (SwiftUI <c>TabBarMinimizeBehavior</c>); other platforms ignore it.</summary>
public enum SwiftTabBarMinimizeBehavior
{
    Automatic,
    /// <summary>The tab bar shrinks while content scrolls down and returns on scroll up.</summary>
    OnScrollDown,
    OnScrollUp,
    Never
}

/// <summary>How dragging a Scroll dismisses the software keyboard (SwiftUI <c>ScrollDismissesKeyboardMode</c>).</summary>
public enum SwiftScrollDismissesKeyboard
{
    /// <summary>The system's behavior for the context.</summary>
    Automatic,
    /// <summary>The keyboard goes as soon as the content is dragged.</summary>
    Immediately,
    /// <summary>The keyboard follows a drag that reaches it and can be pulled away (as in Messages).</summary>
    Interactively,
    /// <summary>Dragging never dismisses the keyboard.</summary>
    Never
}

/// <summary>A tab view's style (SwiftUI <c>TabViewStyle</c>).</summary>
public enum SwiftTabViewStyle
{
    Automatic,
    /// <summary>SwiftUI <c>.sidebarAdaptable</c>: a tab bar on iPhone, a tab bar that becomes a sidebar on iPad and Mac.</summary>
    SidebarAdaptable,
    /// <summary>SwiftUI <c>.tabBarOnly</c>: a tab bar wherever possible, never the sidebar form.</summary>
    TabBarOnly
}

/// <summary>Which split view columns show (SwiftUI <c>NavigationSplitViewVisibility</c>).</summary>
public enum SwiftSplitViewVisibility
{
    Automatic,
    /// <summary>Every column.</summary>
    All,
    /// <summary>The content and detail columns of three; the sidebar and detail of two.</summary>
    DoubleColumn,
    /// <summary>Only the detail column.</summary>
    DetailOnly
}

/// <summary>A split view column (SwiftUI <c>NavigationSplitViewColumn</c>).</summary>
public enum SwiftSplitViewColumn
{
    Sidebar,
    Content,
    Detail
}

/// <summary>How split view columns share the width (SwiftUI <c>NavigationSplitViewStyle</c>).</summary>
public enum SwiftSplitViewStyle
{
    Automatic,
    /// <summary>The detail column narrows to make room for the leading columns.</summary>
    Balanced,
    /// <summary>The detail column keeps its size; the leading columns show over it.</summary>
    ProminentDetail
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

/// <summary>A button's role (SwiftUI <c>ButtonRole</c>): destructive actions are red and,
/// in swipe actions, remove their row.</summary>
public enum SwiftButtonRole
{
    None,
    Destructive,
    Cancel,
}

/// <summary>A search token shown inside a searchable's field (SwiftUI <c>searchable(text:tokens:)</c>).</summary>
public sealed record SwiftSearchToken(string Id, string Title);

public sealed record SwiftImportedFile(byte[] Data, string Name, string MimeType);

/// <summary>The edge an <see cref="SwiftUI.Overlay"/> layer is aligned to.</summary>
public enum SwiftOverlayEdge
{
    Bottom = 0,
    Top = 1
}

/// <summary>Where a scrolled-to view lands in the visible area (SwiftUI <c>UnitPoint</c>).</summary>
public enum SwiftScrollAnchor
{
    Center = 0,
    Top = 1,
    Bottom = 2
}

/// <summary>How <see cref="SwiftView.WithHidden"/> moves a view as it hides or returns.</summary>
public enum SwiftHideTransition
{
    /// <summary>The view fades in place.</summary>
    Fade = 0,

    /// <summary>
    /// The view slides down by its own height while it fades; with Reduce Motion
    /// it only fades.
    /// </summary>
    SlideDown = 1
}

/// <summary>
/// Assistive settings a view reports through
/// <see cref="SwiftView.OnAccessibilitySettingsChanged"/> (SwiftUI accessibility environment).
/// </summary>
[Flags]
public enum SwiftAccessibilitySettings
{
    None = 0,

    /// <summary>VoiceOver is running (SwiftUI <c>accessibilityVoiceOverEnabled</c>).</summary>
    VoiceOver = 1,

    /// <summary>Reduce Motion is on (SwiftUI <c>accessibilityReduceMotion</c>).</summary>
    ReduceMotion = 2
}

/// <summary>
/// A Scroll's vertical geometry in points (SwiftUI <c>ScrollGeometry</c>):
/// <paramref name="ContentOffsetY"/> is the raw content offset, which is
/// <c>-ContentInsetTop</c> at the start and can pass either end while the content
/// bounces; <paramref name="ContainerHeight"/> is the height inside the content
/// insets (SwiftUI <c>containerSize</c>), and the insets include the safe area
/// and any bottom inset.
/// </summary>
public readonly record struct SwiftScrollGeometry(
    double ContentOffsetY, double ContentHeight, double ContainerHeight,
    double ContentInsetTop, double ContentInsetBottom)
{
    /// <summary>How close to an end, in points, still counts as at that end.</summary>
    public const double EdgeTolerance = 1;

    /// <summary>The offset at the start of the content.</summary>
    public double MinimumOffsetY => -ContentInsetTop;

    /// <summary>
    /// The offset at the end of the content: the last point of content sits at the
    /// bottom of the area inside the insets (the start when the content fits).
    /// </summary>
    public double MaximumOffsetY =>
        Math.Max(MinimumOffsetY, ContentHeight - ContainerHeight - ContentInsetTop);

    /// <summary>True when the content is taller than the space it scrolls in.</summary>
    public bool CanScroll => MaximumOffsetY - MinimumOffsetY > EdgeTolerance;

    /// <summary>True at (or above) the start; content that cannot scroll is at both ends.</summary>
    public bool IsAtTop => ContentOffsetY <= MinimumOffsetY + EdgeTolerance;

    /// <summary>True at (or past) the end; content that cannot scroll is at both ends.</summary>
    public bool IsAtBottom => ContentOffsetY >= MaximumOffsetY - EdgeTolerance;
}

/// <summary>
/// One image chosen in the system photo picker: its bytes, MIME type (for
/// example <c>image/jpeg</c>) and uniform type identifier (for example
/// <c>public.jpeg</c>).
/// </summary>
public sealed record SwiftPickedPhoto(byte[] Data, string MimeType, string TypeIdentifier);

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
