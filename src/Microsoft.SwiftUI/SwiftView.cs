using System.Collections.ObjectModel;
using Foundation;
using Microsoft.SwiftUI.Native;

namespace Microsoft.SwiftUI;

public sealed class SwiftView : IDisposable
{
    private readonly MSUNode _native;
    private readonly List<SwiftView> _children = [];
    private readonly ReadOnlyCollection<SwiftView> _readOnlyChildren;
    private Action? _tapHandler;
    private Action<string>? _textChangedHandler;
    private Action<bool>? _boolChangedHandler;
    private Action<double>? _valueChangedHandler;
    private Action<nint>? _selectionChangedHandler;
    private Action<bool>? _focusChangedHandler;
    private Action? _dismissedHandler;
    private Action<string>? _selectedValueChangedHandler;
    private Action<nint>? _navigationChangedHandler;
    private Action? _appearedHandler;
    private Action? _escapeHandler;
    private Action? _submitHandler;
    private Func<string, bool>? _keyHandler;
    private Action? _photoRenderedHandler;
    private Action<string>? _photoFailedHandler;
    private Action? _cancelledHandler;
    private Action? _deleteHandler;
    private Action<NSData, string, string>? _fileImportedHandler;
    private Action<string>? _fileImportErrorHandler;
    private Action? _fileImportCancelledHandler;
    private Action<double, nint>? _viewportChangedHandler;
    private readonly List<string> _navigationRoutes = [];
    private SwiftView? _parent;
    private NSObject? _activeHost;
    private bool _nativeHandlersActive = true;
    private bool _disposed;

    internal SwiftView(string kind)
    {
        RequireMainThread();
        Kind = kind;
        _native = MSUBridge.MakeNode(kind);
        _readOnlyChildren = _children.AsReadOnly();
    }

    internal MSUNode Native { get { RequireActive(); return _native; } }
    public string Kind { get; }
    public IReadOnlyList<SwiftView> Children => _readOnlyChildren;

    public string Text
    {
        get { RequireActive(); return _native.Text; }
        set { RequireActive(); _native.Text = value ?? throw new ArgumentNullException(nameof(value)); }
    }

    public string AccessibilityIdentifier
    {
        get { RequireActive(); return _native.AutomationId; }
        set { RequireActive(); _native.AutomationId = value ?? throw new ArgumentNullException(nameof(value)); }
    }

    public string AccessibilityLabel
    {
        get { RequireKind("slider"); return _native.AccessibilityLabelText; }
        set
        {
            RequireKind("slider");
            ArgumentException.ThrowIfNullOrWhiteSpace(value);
            _native.AccessibilityLabelText = value;
        }
    }

    public bool IsPresented
    {
        get { RequirePresentation(); return _native.IsPresented; }
        set { RequirePresentation(); _native.IsPresented = value; }
    }

    public bool DeletePending
    {
        get { RequireKind("deleteConfirmation"); return _native.DeletePending; }
        set { RequireKind("deleteConfirmation"); _native.DeletePending = value; }
    }

    public SwiftView WithTransparentDeleteBackdrop(bool enabled = true)
    {
        RequireKind("deleteConfirmation");
        _native.TransparentDeleteBackdrop = enabled;
        return this;
    }

    public SwiftPhotoLoadState PhotoLoadState
    {
        get
        {
            RequirePhoto();
            return _native.PhotoStatus switch
            {
                "displayed" => SwiftPhotoLoadState.Displayed,
                "failed" => SwiftPhotoLoadState.Failed,
                _ => SwiftPhotoLoadState.Loading
            };
        }
    }

    public bool IsOn
    {
        get { RequireKind("toggle"); return _native.IsOn; }
        set { RequireKind("toggle"); _native.IsOn = value; }
    }

    public bool IsEnabled
    {
        get { RequireActive(); return _native.IsEnabled; }
        set { RequireActive(); _native.IsEnabled = value; }
    }

    public SwiftColorScheme PreferredColorScheme
    {
        get
        {
            RequireActive();
            return _native.PreferredScheme switch
            {
                "light" => SwiftColorScheme.Light,
                "dark" => SwiftColorScheme.Dark,
                _ => SwiftColorScheme.System
            };
        }
        set
        {
            RequireActive();
            if (!Enum.IsDefined(value))
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.PreferredScheme = value switch
            {
                SwiftColorScheme.Light => "light",
                SwiftColorScheme.Dark => "dark",
                _ => ""
            };
        }
    }

    public bool CanNavigateBack
    {
        get { RequireKind("navigationStack"); return _native.CanNavigateBack; }
        set { RequireKind("navigationStack"); _native.CanNavigateBack = value; }
    }

    public bool FocusRequested
    {
        get { RequireInput(); return _native.FocusRequested; }
        set { RequireInput(); _native.FocusRequested = value; }
    }

    public double Value
    {
        get { RequireValue(); return _native.Value; }
        set
        {
            RequireValue();
            if (!double.IsFinite(value) || value < _native.Minimum || value > _native.Maximum)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.Value = value;
        }
    }

    public double ProgressTotal
    {
        get { RequireKind("progress"); return _native.Maximum; }
        set
        {
            RequireKind("progress");
            if (!double.IsFinite(value) || value < 0 || value < _native.Value)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.Maximum = value;
        }
    }

    public int GridColumns
    {
        get { RequireKind("grid"); return checked((int)_native.GridColumns); }
        set
        {
            RequireKind("grid");
            if (value is < 1 or > 8)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.GridColumns = value;
        }
    }

    public int SelectedIndex
    {
        get { RequireIndexSelection(); return checked((int)_native.SelectedIndex); }
        set
        {
            RequireIndexSelection();
            if (value < (Kind == "buttonGroup" ? -1 : 0) || value >= _children.Count)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.SelectedIndex = value;
        }
    }

    public string SelectedValue
    {
        get { RequireKind("valuePicker"); return _native.SelectedValue; }
        set
        {
            RequireKind("valuePicker");
            ArgumentNullException.ThrowIfNull(value);
            if (!_children.Any(option => option._native.Route == value))
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.SelectedValue = value;
        }
    }

    public IReadOnlyList<string> NavigationPath
    {
        get { RequireKind("navigationStack"); return _navigationRoutes.AsReadOnly(); }
    }

    public double Spacing
    {
        get { RequireContainer(); return _native.Spacing; }
        set
        {
            RequireContainer();
            if (!double.IsFinite(value) || value < 0)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.Spacing = value;
        }
    }

    public SwiftView WithAccessibilityIdentifier(string identifier)
    {
        AccessibilityIdentifier = identifier;
        return this;
    }

    public SwiftView WithAccessibilitySelected(bool selected = true)
    {
        RequireKind("button");
        _native.AccessibilitySelected = selected;
        return this;
    }

    public SwiftView OnFocusChanged(Action<bool> handler)
    {
        RequireInput();
        ArgumentNullException.ThrowIfNull(handler);
        if (_nativeHandlersActive)
            _native.SetFocusChangedHandler(handler);
        _focusChangedHandler = handler;
        return this;
    }

    public SwiftView OnAppear(Action handler)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        if (_nativeHandlersActive)
            _native.SetAppearedHandler(handler);
        _appearedHandler = handler;
        return this;
    }

    public SwiftView OnEscape(Action handler)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        if (_nativeHandlersActive)
            _native.SetEscapeHandler(handler);
        _escapeHandler = handler;
        return this;
    }

    public SwiftView OnSubmit(Action handler)
    {
        RequireKind("textField");
        ArgumentNullException.ThrowIfNull(handler);
        if (_nativeHandlersActive)
            _native.SetSubmitHandler(handler);
        _submitHandler = handler;
        return this;
    }

    public SwiftView OnKeyPress(Func<SwiftTextKey, bool> handler)
    {
        RequireKind("textField");
        ArgumentNullException.ThrowIfNull(handler);
        _keyHandler = key => key switch
        {
            "up" => handler(SwiftTextKey.ArrowUp),
            "down" => handler(SwiftTextKey.ArrowDown),
            "enter" => handler(SwiftTextKey.Enter),
            "escape" => handler(SwiftTextKey.Escape),
            _ => false
        };
        if (_nativeHandlersActive)
            _native.SetKeyHandler(_keyHandler);
        return this;
    }

    public SwiftView OnViewportChanged(Action<double, SwiftDynamicTypeSize> handler)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        _viewportChangedHandler = (width, rawSize) =>
        {
            var size = checked((SwiftDynamicTypeSize)(int)rawSize);
            handler(width, Enum.IsDefined(size) ? size : SwiftDynamicTypeSize.Large);
        };
        if (_nativeHandlersActive)
            _native.SetViewportChangedHandler(_viewportChangedHandler);
        return this;
    }

    public SwiftView WithNavigationTitle(string title)
    {
        RequireActive();
        _native.NavigationTitle = title ?? throw new ArgumentNullException(nameof(title));
        return this;
    }

    public SwiftView WithInlineNavigationTitle(bool inline = true)
    {
        RequireActive();
        if (string.IsNullOrEmpty(_native.NavigationTitle))
            throw new InvalidOperationException("Set the navigation title before its display mode.");
        _native.InlineNavigationTitle = inline;
        return this;
    }

    public SwiftView WithTabBarHidden(bool hidden = true)
    {
        RequireActive();
        _native.HidesTabBar = hidden;
        return this;
    }

    public SwiftView WithAccessibilityLabel(string label)
    {
        RequireActive();
        _native.AccessibilityLabelText = label ?? throw new ArgumentNullException(nameof(label));
        return this;
    }

    public SwiftView WithPadding(double points)
    {
        RequireActive();
        _native.PaddingPoints = Nonnegative(points, nameof(points));
        _native.PaddingTop = 0;
        _native.PaddingRight = 0;
        _native.PaddingBottom = 0;
        _native.PaddingLeft = 0;
        return this;
    }

    public SwiftView WithPadding(double top, double right, double bottom, double left)
    {
        RequireActive();
        top = Nonnegative(top, nameof(top));
        right = Nonnegative(right, nameof(right));
        bottom = Nonnegative(bottom, nameof(bottom));
        left = Nonnegative(left, nameof(left));
        _native.PaddingPoints = 0;
        _native.PaddingTop = top;
        _native.PaddingRight = right;
        _native.PaddingBottom = bottom;
        _native.PaddingLeft = left;
        return this;
    }

    public SwiftView WithLineLimit(int maxLines)
    {
        RequireKind("text");
        if (maxLines < 1)
            throw new ArgumentOutOfRangeException(nameof(maxLines));
        _native.LineLimit = maxLines;
        return this;
    }

    public SwiftView WithTypography(double pointSize, int weight, double lineHeightMultiple,
                                    string? postScriptName = null)
    {
        RequireActive();
        if (!double.IsFinite(pointSize) || pointSize <= 0)
            throw new ArgumentOutOfRangeException(nameof(pointSize));
        if (weight is < 100 or > 900 || weight % 100 != 0)
            throw new ArgumentOutOfRangeException(nameof(weight));
        if (!double.IsFinite(lineHeightMultiple) || lineHeightMultiple <= 0)
            throw new ArgumentOutOfRangeException(nameof(lineHeightMultiple));
        if (postScriptName is not null && string.IsNullOrWhiteSpace(postScriptName))
            throw new ArgumentException("Use null for the system font or an exact PostScript name.",
                                        nameof(postScriptName));
        _native.FontStyle = "";
        _native.FontPostScriptName = postScriptName ?? "";
        _native.FontWeight = weight;
        _native.LineHeightMultiple = lineHeightMultiple;
        _native.FontSize = pointSize;
        return this;
    }

    public SwiftView WithFont(SwiftFontStyle style)
    {
        RequireActive();
        if (!Enum.IsDefined(style))
            throw new ArgumentOutOfRangeException(nameof(style));
        _native.FontStyle = style switch
        {
            SwiftFontStyle.LargeTitle => "largeTitle",
            SwiftFontStyle.Title => "title",
            SwiftFontStyle.Title2 => "title2",
            SwiftFontStyle.Headline => "headline",
            SwiftFontStyle.Subheadline => "subheadline",
            SwiftFontStyle.Caption => "caption",
            _ => "body"
        };
        _native.FontSize = 0;
        return this;
    }

    public SwiftView WithFixedSymbolSize(double points)
    {
        RequireKind("image");
        if (!double.IsFinite(points) || points <= 0)
            throw new ArgumentOutOfRangeException(nameof(points));
        _native.FixedSymbolSize = points;
        return this;
    }

    public SwiftView WithPreferredColorScheme(SwiftColorScheme scheme)
    {
        PreferredColorScheme = scheme;
        return this;
    }

    public SwiftView WithButtonStyle(SwiftButtonStyle style)
    {
        RequireKind("button");
        if (!Enum.IsDefined(style))
            throw new ArgumentOutOfRangeException(nameof(style));
        _native.ButtonStyle = style switch
        {
            SwiftButtonStyle.Bordered => "bordered",
            SwiftButtonStyle.BorderedProminent => "prominent",
            SwiftButtonStyle.Plain => "plain",
            _ => ""
        };
        return this;
    }

    public SwiftView WithButtonAppearance(string? lightFillHex, string? darkFillHex,
        string? lightBorderHex, string? darkBorderHex, double cornerRadius,
        double disabledOpacity = 0.65)
    {
        RequireKind("button");
        if ((lightFillHex is null) != (darkFillHex is null))
            throw new ArgumentException("Both fill colors must be set, or both must be null.");
        if ((lightBorderHex is null) != (darkBorderHex is null))
            throw new ArgumentException("Both border colors must be set, or both must be null.");
        var fillLight = lightFillHex is null ? "" : ValidateHex(lightFillHex);
        var fillDark = darkFillHex is null ? "" : ValidateHex(darkFillHex!);
        var borderLight = lightBorderHex is null ? "" : ValidateHex(lightBorderHex);
        var borderDark = darkBorderHex is null ? "" : ValidateHex(darkBorderHex!);
        if (!double.IsFinite(cornerRadius) || cornerRadius <= 0)
            throw new ArgumentOutOfRangeException(nameof(cornerRadius));
        if (!double.IsFinite(disabledOpacity) || disabledOpacity < 0 || disabledOpacity > 1)
            throw new ArgumentOutOfRangeException(nameof(disabledOpacity));
        _native.ButtonFillHex = fillLight;
        _native.ButtonFillDarkHex = fillDark;
        _native.ButtonBorderHex = borderLight;
        _native.ButtonBorderDarkHex = borderDark;
        _native.ButtonCornerRadius = cornerRadius;
        _native.ButtonDisabledOpacity = disabledOpacity;
        _native.HasButtonAppearance = true;
        return this;
    }

    public SwiftView WithButtonCircle(double diameter)
    {
        RequireKind("button");
        if (!double.IsFinite(diameter) || diameter <= 0)
            throw new ArgumentOutOfRangeException(nameof(diameter));
        if (!_native.HasButtonAppearance)
            throw new InvalidOperationException("A circular button needs a custom appearance.");
        if (_native.MinimumHeight > diameter)
            throw new InvalidOperationException("The button minimum height exceeds its circle diameter.");
        _native.ButtonCircleDiameter = diameter;
        return this;
    }

    public SwiftView WithButtonBorderWidth(double points)
    {
        RequireKind("button");
        if (!double.IsFinite(points) || points <= 0)
            throw new ArgumentOutOfRangeException(nameof(points));
        _native.ButtonBorderWidth = points;
        return this;
    }

    public SwiftView WithButtonGroupLayout(double overlapPoints, bool fillAvailableWidth = false)
    {
        RequireKind("buttonGroup");
        _native.ButtonGroupOverlap = Nonnegative(overlapPoints, nameof(overlapPoints));
        _native.ButtonGroupFillAvailableWidth = fillAvailableWidth;
        return this;
    }

    public SwiftView WithButtonEllipticalCornerRadii(
        double topLeftX, double topLeftY, double topRightX, double topRightY,
        double bottomRightX, double bottomRightY, double bottomLeftX, double bottomLeftY)
    {
        RequireKind("button");
        Nonnegative(topLeftX, nameof(topLeftX));
        Nonnegative(topLeftY, nameof(topLeftY));
        Nonnegative(topRightX, nameof(topRightX));
        Nonnegative(topRightY, nameof(topRightY));
        Nonnegative(bottomRightX, nameof(bottomRightX));
        Nonnegative(bottomRightY, nameof(bottomRightY));
        Nonnegative(bottomLeftX, nameof(bottomLeftX));
        Nonnegative(bottomLeftY, nameof(bottomLeftY));
        _native.ButtonCornerTopLeftX = topLeftX;
        _native.ButtonCornerTopLeftY = topLeftY;
        _native.ButtonCornerTopRightX = topRightX;
        _native.ButtonCornerTopRightY = topRightY;
        _native.ButtonCornerBottomRightX = bottomRightX;
        _native.ButtonCornerBottomRightY = bottomRightY;
        _native.ButtonCornerBottomLeftX = bottomLeftX;
        _native.ButtonCornerBottomLeftY = bottomLeftY;
        _native.HasButtonEllipticalCornerRadii = true;
        return this;
    }

    public SwiftView WithUnderline(bool underlined = true)
    {
        RequireKind("text");
        _native.IsUnderlined = underlined;
        return this;
    }

    public SwiftView WithStrikethrough(bool enabled = true)
    {
        RequireKind("text");
        _native.IsStrikethrough = enabled;
        return this;
    }

    public SwiftView WithOpacity(double opacity)
    {
        RequireActive();
        if (!double.IsFinite(opacity) || opacity < 0 || opacity > 1)
            throw new ArgumentOutOfRangeException(nameof(opacity));
        _native.Opacity = opacity;
        return this;
    }

    public SwiftView WithSheetDetentFraction(double fraction)
    {
        RequireKind("sheet");
        if (!double.IsFinite(fraction) || fraction <= 0 || fraction > 1)
            throw new ArgumentOutOfRangeException(nameof(fraction));
        _native.SheetDetentFraction = fraction;
        return this;
    }

    public SwiftView WithPickerStyle(SwiftPickerStyle style)
    {
        RequireActive();
        if (Kind is not ("picker" or "valuePicker"))
            throw new InvalidOperationException($"Expected a picker node, not {Kind}.");
        if (!Enum.IsDefined(style))
            throw new ArgumentOutOfRangeException(nameof(style));
        _native.PickerStyle = style switch
        {
            SwiftPickerStyle.Menu => "menu",
            SwiftPickerStyle.Segmented => "segmented",
            _ => ""
        };
        return this;
    }

    public SwiftView WithForegroundColor(string hex)
    {
        RequireActive();
        _native.ForegroundHex = ValidateHex(hex);
        _native.ForegroundDarkHex = "";
        return this;
    }

    public SwiftView WithForegroundColor(string lightHex, string darkHex)
    {
        RequireActive();
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        _native.ForegroundHex = light;
        _native.ForegroundDarkHex = dark;
        return this;
    }

    public SwiftView WithBackgroundColor(string hex)
    {
        RequireActive();
        _native.BackgroundHex = ValidateHex(hex);
        _native.BackgroundDarkHex = "";
        return this;
    }

    public SwiftView WithBackgroundColor(string lightHex, string darkHex)
    {
        RequireActive();
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        _native.BackgroundHex = light;
        _native.BackgroundDarkHex = dark;
        return this;
    }

    public SwiftView WithNativeListColors(string lightCanvasHex, string darkCanvasHex,
                                          string lightRowHex, string darkRowHex)
    {
        RequireActive();
        if (Kind is not ("list" or "form"))
            throw new InvalidOperationException($"Expected a Form or List node, not {Kind}.");
        var lightCanvas = ValidateHex(lightCanvasHex);
        var darkCanvas = ValidateHex(darkCanvasHex);
        var lightRow = ValidateHex(lightRowHex);
        var darkRow = ValidateHex(darkRowHex);
        _native.NativeListCanvasHex = lightCanvas;
        _native.NativeListCanvasDarkHex = darkCanvas;
        _native.NativeListRowHex = lightRow;
        _native.NativeListRowDarkHex = darkRow;
        return this;
    }

    public SwiftView WithPlaceholderColor(string lightHex, string darkHex)
    {
        RequireActive();
        if (Kind is not ("textField" or "textEditor" or "secureField"))
            throw new InvalidOperationException($"Expected a text input, not {Kind}.");
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        _native.PlaceholderColorHex = light;
        _native.PlaceholderColorDarkHex = dark;
        return this;
    }

    public SwiftView WithTextEditorPlaceholder(string placeholder)
    {
        RequireKind("textEditor");
        _native.Placeholder = placeholder ?? throw new ArgumentNullException(nameof(placeholder));
        return this;
    }

    public SwiftView WithTextEditorScrollBackgroundHidden(bool hidden = true)
    {
        RequireKind("textEditor");
        _native.HidesTextEditorScrollBackground = hidden;
        return this;
    }

    public SwiftView WithTintColor(string lightHex, string darkHex)
    {
        RequireActive();
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        _native.TintHex = light;
        _native.TintDarkHex = dark;
        return this;
    }

    public SwiftView WithProgressTrackColor(string lightHex, string darkHex)
    {
        RequireKind("progress");
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        _native.ProgressTrackHex = light;
        _native.ProgressTrackDarkHex = dark;
        return this;
    }

    public SwiftView WithFlexibleWidth(
        double? maxWidth = null,
        SwiftHorizontalAlignment alignment = SwiftHorizontalAlignment.Leading)
    {
        RequireActive();
        if (maxWidth is { } width && (!double.IsFinite(width) || width <= 0))
            throw new ArgumentOutOfRangeException(nameof(maxWidth));
        if (!Enum.IsDefined(alignment))
            throw new ArgumentOutOfRangeException(nameof(alignment));
        _native.MaxWidth = maxWidth ?? 0;
        _native.HorizontalAlignment = alignment switch
        {
            SwiftHorizontalAlignment.Center => "center",
            SwiftHorizontalAlignment.Trailing => "trailing",
            _ => "leading"
        };
        _native.FillsWidth = true;
        return this;
    }

    public SwiftView WithRoundedSurface(string lightFillHex, string darkFillHex,
                                        double cornerRadius, string? lightBorderHex = null,
                                        string? darkBorderHex = null, double borderWidth = 0)
    {
        RequireActive();
        var light = ValidateHex(lightFillHex);
        var dark = ValidateHex(darkFillHex);
        if (!double.IsFinite(cornerRadius) || cornerRadius <= 0)
            throw new ArgumentOutOfRangeException(nameof(cornerRadius));
        borderWidth = Nonnegative(borderWidth, nameof(borderWidth));
        if ((lightBorderHex is null) != (darkBorderHex is null) ||
            (borderWidth == 0) != (lightBorderHex is null))
            throw new ArgumentException("A nonzero stroke needs both light and dark border colors.");
        var borderLight = lightBorderHex is null ? "" : ValidateHex(lightBorderHex);
        var borderDark = darkBorderHex is null ? "" : ValidateHex(darkBorderHex!);
        _native.BackgroundHex = light;
        _native.BackgroundDarkHex = dark;
        _native.CornerRadius = cornerRadius;
        _native.BorderHex = borderLight;
        _native.BorderDarkHex = borderDark;
        _native.BorderWidth = borderWidth;
        return this;
    }

    public SwiftView WithShadow(string lightHex, string darkHex, double radius,
                                double opacity, double offsetY = 0)
    {
        RequireActive();
        if (_native.CornerRadius <= 0 && !(Kind == "button" && _native.HasButtonAppearance))
            throw new InvalidOperationException("A shadow needs a rounded surface or a button appearance.");
        var light = ValidateHex(lightHex);
        var dark = ValidateHex(darkHex);
        radius = Nonnegative(radius, nameof(radius));
        if (!double.IsFinite(opacity) || opacity < 0 || opacity > 1)
            throw new ArgumentOutOfRangeException(nameof(opacity));
        if (!double.IsFinite(offsetY))
            throw new ArgumentOutOfRangeException(nameof(offsetY));
        _native.ShadowHex = light;
        _native.ShadowDarkHex = dark;
        _native.ShadowRadius = radius;
        _native.ShadowOpacity = opacity;
        _native.ShadowOffsetY = offsetY;
        return this;
    }

    public SwiftView WithButtonShadowOffsetX(double points)
    {
        RequireKind("button");
        if (!_native.HasButtonAppearance)
            throw new InvalidOperationException("A button shadow offset needs a button appearance.");
        if (!double.IsFinite(points))
            throw new ArgumentOutOfRangeException(nameof(points));
        _native.ShadowOffsetX = points;
        return this;
    }

    public SwiftView WithAdaptiveStack(double verticalBelowWidth)
    {
        RequireKind("hstack");
        if (!double.IsFinite(verticalBelowWidth) || verticalBelowWidth <= 0)
            throw new ArgumentOutOfRangeException(nameof(verticalBelowWidth));
        _native.AdaptiveStackBelowWidth = verticalBelowWidth;
        return this;
    }

    public SwiftView WithCenterWhenShort(bool enabled = true)
    {
        RequireKind("scroll");
        _native.CenterWhenShort = enabled;
        return this;
    }

    public SwiftView WithMinimumHeight(double points)
    {
        RequireActive();
        if (!double.IsFinite(points) || points < 0)
            throw new ArgumentOutOfRangeException(nameof(points));
        if (Kind == "button" && _native.ButtonCircleDiameter > 0
            && points > _native.ButtonCircleDiameter)
            throw new InvalidOperationException("The button minimum height exceeds its circle diameter.");
        _native.MinimumHeight = points;
        return this;
    }

    public void Push(string route, SwiftView destination)
    {
        RequireKind("navigationStack");
        ArgumentException.ThrowIfNullOrWhiteSpace(route);
        ArgumentNullException.ThrowIfNull(destination);
        if (_navigationRoutes.Contains(route, StringComparer.Ordinal))
            throw new ArgumentException("A route may appear only once in a navigation path.", nameof(route));
        destination.RequireActive();
        if (destination._parent is not null || destination._activeHost is not null)
            throw new InvalidOperationException("The destination must be unparented.");
        destination._native.Route = route;
        Attach(destination);
        _navigationRoutes.Add(route);
        _native.AppendRoute(route);
    }

    public void Pop()
    {
        RequireKind("navigationStack");
        if (_navigationRoutes.Count == 0)
            throw new InvalidOperationException("The navigation stack is at its root.");
        if (!CanNavigateBack)
            throw new InvalidOperationException("Back navigation is disabled while this operation is in progress.");
        _native.PopRoute();
        PruneNavigation(_navigationRoutes.Count - 1);
    }

    public void InvokeAction()
    {
        RequireKind("button");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached button cannot invoke its action until reparented.");
        _native.InvokeAction();
    }

    public SwiftView Add(SwiftView child)
    {
        RequireContainer();
        if (Kind == "tabView" && child?.Kind != "tab")
            throw new ArgumentException("A tab view only accepts Tab nodes.", nameof(child));
        if (Kind == "horizontalGrid" &&
            (child?.Kind != "hstack" || child.Children.Count != _native.GridColumnMinimumWidths.Length))
            throw new ArgumentException("A grid row must be an HStack with one cell per column.",
                                        nameof(child));
        if (_parent?.Kind == "horizontalGrid")
            throw new InvalidOperationException("Detach a grid row before changing its cells.");
        Attach(child);
        return this;
    }

    public void RemoveAt(int index)
    {
        RequireContainer();
        if (_parent?.Kind == "horizontalGrid")
            throw new InvalidOperationException("Detach a grid row before changing its cells.");
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        if (index >= _children.Count)
            throw new ArgumentOutOfRangeException(nameof(index));
        if (Kind == "horizontalGrid" && index == 0)
            throw new InvalidOperationException("The grid header cannot be removed.");
        var child = _children[index];
        child.SuspendNativeHandlers();
        _native.RemoveChild(index);
        child._parent = null;
        _children.RemoveAt(index);
    }

    public void Clear()
    {
        RequireContainer();
        if (Kind == "horizontalGrid" || _parent?.Kind == "horizontalGrid")
            throw new InvalidOperationException("Remove grid data rows individually.");
        foreach (var child in _children)
            child.SuspendNativeHandlers();
        _native.ClearChildren();
        foreach (var child in _children)
            child._parent = null;
        _children.Clear();
    }

    internal void Attach(SwiftView child)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(child);
        child.RequireActive();
        if (child._parent is not null || child._activeHost is not null || ReferenceEquals(child, this))
            throw new InvalidOperationException("A SwiftUI node can have only one parent or native host.");
        for (SwiftView? ancestor = this; ancestor is not null; ancestor = ancestor._parent)
        {
            if (ReferenceEquals(ancestor, child))
                throw new InvalidOperationException("A SwiftUI node cannot contain an ancestor.");
        }
        if (!_nativeHandlersActive)
            child.SuspendNativeHandlers();
        _native.InsertChild(child._native, _children.Count);
        _children.Add(child);
        child._parent = this;
        if (_nativeHandlersActive)
            child.RestoreNativeHandlers();
    }

    internal void SetTapHandler(Action handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetTapHandler(handler);
        _tapHandler = handler;
    }

    internal void SetTextChangedHandler(Action<string> handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetTextChangedHandler(handler);
        _textChangedHandler = handler;
    }

    internal void SetBoolChangedHandler(Action<bool> handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetBoolChangedHandler(handler);
        _boolChangedHandler = handler;
    }

    internal void SetValueChangedHandler(Action<double> handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetValueChangedHandler(handler);
        _valueChangedHandler = handler;
    }

    internal void SetSelectionChangedHandler(Action<nint> handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetSelectionChangedHandler(handler);
        _selectionChangedHandler = handler;
    }

    internal void SetDismissedHandler(Action handler)
    {
        RequireActive();
        if (_nativeHandlersActive)
            _native.SetDismissedHandler(handler);
        _dismissedHandler = handler;
    }

    internal void SetPhotoHandlers(Action? onRendered, Action<string>? onFailed)
    {
        RequirePhoto();
        _photoRenderedHandler = onRendered;
        _photoFailedHandler = onFailed;
        if (_nativeHandlersActive)
        {
            if (onRendered is not null)
                _native.SetPhotoRenderedHandler(onRendered);
            if (onFailed is not null)
                _native.SetPhotoFailedHandler(onFailed);
        }
    }

    internal void SetDeleteHandlers(Action onCancelled, Action onDelete)
    {
        RequireKind("deleteConfirmation");
        if (_nativeHandlersActive)
        {
            _native.SetDeleteCancelledHandler(onCancelled);
            _native.SetDeleteConfirmedHandler(onDelete);
        }
        _cancelledHandler = onCancelled;
        _deleteHandler = onDelete;
    }

    internal void SetSelectedValueChangedHandler(Action<string> handler)
    {
        RequireKind("valuePicker");
        if (_nativeHandlersActive)
            _native.SetSelectedValueChangedHandler(handler);
        _selectedValueChangedHandler = handler;
    }

    internal void SetNavigationChangedHandler(Action<IReadOnlyList<string>> handler)
    {
        RequireKind("navigationStack");
        ArgumentNullException.ThrowIfNull(handler);
        _navigationChangedHandler = depth =>
        {
            RequireKind("navigationStack");
            var count = checked((int)depth);
            if (count < 0 || count > _navigationRoutes.Count)
                throw new InvalidOperationException("The native navigation path is not a prefix of its managed path.");
            PruneNavigation(count);
            handler(_navigationRoutes.ToArray());
        };
        if (_nativeHandlersActive)
            _native.SetNavigationChangedHandler(_navigationChangedHandler);
    }

    internal void SetFileHandlers(Action<SwiftImportedFile> imported, Action<string>? error,
                                  Action? cancelled)
    {
        RequireKind("fileImporter");
        ArgumentNullException.ThrowIfNull(imported);
        _fileImportedHandler = (data, name, mimeType) =>
            imported(new SwiftImportedFile(data.ToArray(), name, mimeType));
        _fileImportErrorHandler = error;
        _fileImportCancelledHandler = cancelled;
        if (_nativeHandlersActive)
        {
            _native.SetFileImportedHandler(_fileImportedHandler);
            if (error is not null)
                _native.SetFileImportErrorHandler(error);
            if (cancelled is not null)
                _native.SetFileImportCancelledHandler(cancelled);
        }
    }

    internal static void ValidateChildren(IReadOnlyList<SwiftView> children)
    {
        RequireMainThread();
        ArgumentNullException.ThrowIfNull(children);
        var seen = new HashSet<SwiftView>(ReferenceEqualityComparer.Instance);
        foreach (var child in children)
        {
            ArgumentNullException.ThrowIfNull(child);
            child.RequireActive();
            if (child._parent is not null || child._activeHost is not null)
                throw new InvalidOperationException("A SwiftUI node can have only one parent or native host.");
            if (!seen.Add(child))
                throw new InvalidOperationException("A SwiftUI node cannot appear twice in the same parent.");
        }
    }

    internal void RequireHostRoot()
    {
        RequireActive();
        if (_parent is not null)
            throw new InvalidOperationException("Detach a SwiftUI node before hosting it as a root.");
        if (_activeHost is not null)
            throw new InvalidOperationException("Detach the existing native host before hosting a SwiftUI root again.");
    }

    internal void ClaimHost(NSObject host)
    {
        ArgumentNullException.ThrowIfNull(host);
        RequireHostRoot();
        RestoreNativeHandlers();
        _activeHost = host;
    }

    internal void ReleaseHost(NSObject host)
    {
        RequireHostOwner(host);
        SuspendNativeHandlers();
        _activeHost = null;
    }

    internal void RequireHostOwner(NSObject host)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(host);
        if (!ReferenceEquals(_activeHost, host))
            throw new InvalidOperationException("The native host does not own this SwiftUI root.");
    }

    public void Dispose()
    {
        RequireMainThread();
        if (_disposed)
            return;
        if (_parent is not null)
            throw new InvalidOperationException("Detach a child before disposing it.");
        if (_activeHost is not null)
            throw new InvalidOperationException("Remove the native host from its window and detach it before disposing the root.");

        foreach (var child in _children)
        {
            child._parent = null;
            child.Dispose();
        }
        _native.ClearHandlers();
        if (Kind is "photo" or "zoomPhoto")
            _native.PhotoData = null;
        _nativeHandlersActive = false;
        _native.ClearChildren();
        _tapHandler = null;
        _textChangedHandler = null;
        _boolChangedHandler = null;
        _valueChangedHandler = null;
        _selectionChangedHandler = null;
        _focusChangedHandler = null;
        _dismissedHandler = null;
        _selectedValueChangedHandler = null;
        _navigationChangedHandler = null;
        _appearedHandler = null;
        _escapeHandler = null;
        _submitHandler = null;
        _keyHandler = null;
        _photoRenderedHandler = null;
        _photoFailedHandler = null;
        _cancelledHandler = null;
        _deleteHandler = null;
        _fileImportedHandler = null;
        _fileImportErrorHandler = null;
        _fileImportCancelledHandler = null;
        _viewportChangedHandler = null;
        _navigationRoutes.Clear();
        _children.Clear();
        _disposed = true;
        _native.Dispose();
    }

    private void SuspendNativeHandlers()
    {
        if (_nativeHandlersActive)
        {
            _native.ClearHandlers();
            _nativeHandlersActive = false;
        }
        foreach (var child in _children)
            child.SuspendNativeHandlers();
    }

    internal void RestoreNativeHandlers()
    {
        if (!_nativeHandlersActive)
        {
            if (_tapHandler is not null) _native.SetTapHandler(_tapHandler);
            if (_textChangedHandler is not null) _native.SetTextChangedHandler(_textChangedHandler);
            if (_boolChangedHandler is not null) _native.SetBoolChangedHandler(_boolChangedHandler);
            if (_valueChangedHandler is not null) _native.SetValueChangedHandler(_valueChangedHandler);
            if (_selectionChangedHandler is not null) _native.SetSelectionChangedHandler(_selectionChangedHandler);
            if (_focusChangedHandler is not null) _native.SetFocusChangedHandler(_focusChangedHandler);
            if (_dismissedHandler is not null) _native.SetDismissedHandler(_dismissedHandler);
            if (_selectedValueChangedHandler is not null) _native.SetSelectedValueChangedHandler(_selectedValueChangedHandler);
            if (_navigationChangedHandler is not null) _native.SetNavigationChangedHandler(_navigationChangedHandler);
            if (_appearedHandler is not null) _native.SetAppearedHandler(_appearedHandler);
            if (_escapeHandler is not null) _native.SetEscapeHandler(_escapeHandler);
            if (_submitHandler is not null) _native.SetSubmitHandler(_submitHandler);
            if (_keyHandler is not null) _native.SetKeyHandler(_keyHandler);
            if (_photoRenderedHandler is not null) _native.SetPhotoRenderedHandler(_photoRenderedHandler);
            if (_photoFailedHandler is not null) _native.SetPhotoFailedHandler(_photoFailedHandler);
            if (_cancelledHandler is not null) _native.SetDeleteCancelledHandler(_cancelledHandler);
            if (_deleteHandler is not null) _native.SetDeleteConfirmedHandler(_deleteHandler);
            if (_fileImportedHandler is not null) _native.SetFileImportedHandler(_fileImportedHandler);
            if (_fileImportErrorHandler is not null) _native.SetFileImportErrorHandler(_fileImportErrorHandler);
            if (_fileImportCancelledHandler is not null) _native.SetFileImportCancelledHandler(_fileImportCancelledHandler);
            if (_viewportChangedHandler is not null) _native.SetViewportChangedHandler(_viewportChangedHandler);
            _nativeHandlersActive = true;
        }
        foreach (var child in _children)
            child.RestoreNativeHandlers();
    }

    private void RequireKind(string kind)
    {
        RequireActive();
        if (Kind != kind)
            throw new InvalidOperationException($"Expected a {kind} node, not {Kind}.");
    }

    private void RequireInput()
    {
        RequireActive();
        if (Kind is not ("textField" or "textEditor" or "secureField"))
            throw new InvalidOperationException($"Expected a text input node, not {Kind}.");
    }

    private void RequireIndexSelection()
    {
        RequireActive();
        if (Kind is not ("picker" or "tabView" or "buttonGroup"))
            throw new InvalidOperationException($"Expected a picker, tab view or button group, not {Kind}.");
    }

    private void RequireValue()
    {
        RequireActive();
        if (Kind is not ("slider" or "progress"))
            throw new InvalidOperationException($"Expected a slider or progress node, not {Kind}.");
    }

    private void RequirePresentation()
    {
        RequireActive();
        if (Kind is not ("sheet" or "alert" or "confirmationDialog" or "fileImporter"
            or "photoCover" or "quickSuggestions" or "starterOverlay" or "deleteConfirmation"))
            throw new InvalidOperationException($"Expected a presented view, not {Kind}.");
    }

    private void RequirePhoto()
    {
        RequireActive();
        if (Kind is not ("photo" or "zoomPhoto"))
            throw new InvalidOperationException($"Expected a photo node, not {Kind}.");
    }

    private void RequireContainer()
    {
        RequireActive();
        if (Kind is not ("vstack" or "hstack" or "scroll" or "list" or "form" or
                         "section" or "grid" or "horizontalGrid" or "tabView"))
            throw new InvalidOperationException($"Expected a container node, not {Kind}.");
    }

    private void PruneNavigation(int count)
    {
        while (_navigationRoutes.Count > count)
        {
            _navigationRoutes.RemoveAt(_navigationRoutes.Count - 1);
            var child = _children[^1];
            child.SuspendNativeHandlers();
            _native.RemoveChild(_children.Count - 1);
            child._parent = null;
            _children.RemoveAt(_children.Count - 1);
            child.Dispose();
        }
    }

    internal static string ValidateHex(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (value.Length != 7 || value[0] != '#' ||
            !value.AsSpan(1).ToString().All(Uri.IsHexDigit))
            throw new ArgumentException("Expected a six-digit #RRGGBB color.", nameof(value));
        return value;
    }

    private static double Nonnegative(double value, string name)
    {
        if (!double.IsFinite(value) || value < 0)
            throw new ArgumentOutOfRangeException(name);
        return value;
    }

    private void RequireActive()
    {
        RequireMainThread();
        ObjectDisposedException.ThrowIf(_disposed, this);
    }

    internal static void RequireMainThread()
    {
        if (!NSThread.IsMain)
            throw new InvalidOperationException("SwiftUI views must be created and updated on the Apple main thread.");
    }
}
