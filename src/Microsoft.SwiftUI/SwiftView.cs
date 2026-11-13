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
    private Action? _doubleTapHandler;
    private Action<double>? _dragChangedHandler;
    private Action<double, double>? _dragEndedHandler;
    private Action? _dragCancelledHandler;
    private Action<NSData, string, string>? _photoPickedHandler;
    private Action<string>? _photoPickErrorHandler;
    private Action? _photoPickCancelledHandler;
    private Action<double, double, double, double, double>? _scrollGeometryChangedHandler;
    private Action<double>? _keyboardOverlapChangedHandler;
    private Action<nint>? _accessibilitySettingsChangedHandler;
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

    /// <summary>
    /// The label set by <see cref="WithAccessibilityLabel"/> on any view, or empty, so a host
    /// can compare a rebuilt view with the one on screen. Setting it here is for a slider (which
    /// needs a non-empty label); other views use <see cref="WithAccessibilityLabel"/>.
    /// </summary>
    public string AccessibilityLabel
    {
        get { RequireActive(); return _native.AccessibilityLabelText; }
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

    /// <summary>
    /// A searchable's tokens, shown inside its field in order; a token needs a non-empty id
    /// (unique) and title.
    /// </summary>
    public IReadOnlyList<SwiftSearchToken> SearchTokens
    {
        get
        {
            RequireKind("searchable");
            var ids = _native.SearchTokenIds ?? [];
            var titles = _native.SearchTokenTitles ?? [];
            return ids.Zip(titles, (id, title) => new SwiftSearchToken(id, title)).ToArray();
        }
        set
        {
            ArgumentNullException.ThrowIfNull(value);
            RequireKind("searchable");
            RequireActive();
            if (value.Any(token => token is null || string.IsNullOrEmpty(token.Id)
                    || string.IsNullOrEmpty(token.Title))
                || value.Select(token => token.Id).Distinct(StringComparer.Ordinal).Count() != value.Count)
                throw new ArgumentException("Search tokens need unique ids and titles.", nameof(value));
            var ids = value.Select(token => token.Id).ToArray();
            var titles = value.Select(token => token.Title).ToArray();
            if ((_native.SearchTokenIds ?? []).SequenceEqual(ids)
                && (_native.SearchTokenTitles ?? []).SequenceEqual(titles))
                return;
            _native.SearchTokenTitles = titles;
            _native.SearchTokenIds = ids;
        }
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

    /// <summary>Whether <see cref="WithAccessibilitySelected"/> marks this button selected.</summary>
    public bool AccessibilitySelected
    {
        get { RequireKind("button"); return _native.AccessibilitySelected; }
    }

    /// <summary>
    /// The SF Symbol an <see cref="SwiftUI.Image"/> or a <see cref="SwiftUI.Label"/> shows (a
    /// Label's title is <see cref="Text"/>). Settable in place, so a toolbar button can change
    /// its symbol (a filled filter icon once a filter is on) without being rebuilt.
    /// </summary>
    public string SystemImageName
    {
        get { RequireSymbolKind(); return _native.ImageName; }
        set
        {
            RequireSymbolKind();
            ArgumentException.ThrowIfNullOrWhiteSpace(value);
            _native.ImageName = value;
        }
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

    /// <summary>
    /// Sets the language VoiceOver speaks this Text or Button label in (the
    /// <c>accessibilitySpeechLanguage</c> attributed-string attribute), for
    /// example <c>"ko-KR"</c>, independent of the environment locale. On a
    /// Button it applies to its title or its accessibility label. Null or empty
    /// restores the system language. Unset by default.
    /// </summary>
    public SwiftView WithSpeechLanguage(string? languageTag)
    {
        RequireActive();
        if (Kind is not ("text" or "button"))
            throw new InvalidOperationException($"Expected a text or button node, not {Kind}.");
        _native.SpeechLanguage = string.IsNullOrEmpty(languageTag) ? "" : ValidateLanguageTag(languageTag);
        return this;
    }

    public string SpeechLanguage
    {
        get { RequireActive(); return _native.SpeechLanguage; }
    }

    /// <summary>
    /// Runs <paramref name="handler"/> on a double tap (SwiftUI
    /// <c>TapGesture(count: 2)</c> as a high-priority gesture). A Button keeps
    /// its single-tap action, which runs once a double tap is ruled out (so a
    /// first tap that presents a sheet cannot swallow the second). A non-empty
    /// <paramref name="accessibilityActionName"/> also exposes the handler as a
    /// named accessibility action, which VoiceOver and automation can invoke.
    /// A disabled view ignores the gesture.
    /// </summary>
    public SwiftView OnDoubleTap(Action handler, string? accessibilityActionName = null)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        if (accessibilityActionName is not null && string.IsNullOrWhiteSpace(accessibilityActionName))
            throw new ArgumentException("Use null for no accessibility action, or a visible action name.",
                                        nameof(accessibilityActionName));
        _native.DoubleTapActionName = accessibilityActionName ?? "";
        if (_nativeHandlersActive)
            _native.SetDoubleTapHandler(handler);
        _doubleTapHandler = handler;
        return this;
    }

    /// <summary>Runs the double-tap handler as the gesture would (for tests and automation).</summary>
    public void InvokeDoubleTap()
    {
        RequireActive();
        if (_doubleTapHandler is null)
            throw new InvalidOperationException("This view has no double-tap handler.");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached view cannot invoke its double tap until reparented.");
        _native.InvokeDoubleTap();
    }

    /// <summary>
    /// Follows a horizontal drag (SwiftUI <c>DragGesture</c> in the global
    /// coordinate space, as a high-priority gesture). <paramref name="onChanged"/>
    /// receives the horizontal translation in points from the touch-down point;
    /// <paramref name="onEnded"/> receives the final and the velocity-predicted
    /// end translation when the finger lifts; <paramref name="onCancelled"/> runs
    /// when the system cancels the drag instead. A touch that moves less than
    /// <paramref name="minimumDistance"/> points stays a tap, so a Button's action
    /// and <see cref="OnDoubleTap"/> keep working on the same view. Vertical
    /// movement is ignored. A disabled view does not begin a drag; a drag that
    /// began while enabled always ends or cancels. Unset by default.
    /// </summary>
    public SwiftView OnHorizontalDrag(Action<double> onChanged, Action<double, double> onEnded,
                                      Action? onCancelled = null, double minimumDistance = 10)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(onChanged);
        ArgumentNullException.ThrowIfNull(onEnded);
        if (!double.IsFinite(minimumDistance) || minimumDistance < 0)
            throw new ArgumentOutOfRangeException(nameof(minimumDistance));
        _native.HorizontalDragMinimumDistance = minimumDistance;
        if (_nativeHandlersActive)
            _native.SetHorizontalDragHandlers(onChanged, onEnded, onCancelled);
        _dragChangedHandler = onChanged;
        _dragEndedHandler = onEnded;
        _dragCancelledHandler = onCancelled;
        return this;
    }

    /// <summary>The drag's minimum distance in points (10 unless set).</summary>
    public double HorizontalDragMinimumDistance
    {
        get { RequireActive(); return _native.HorizontalDragMinimumDistance; }
    }

    /// <summary>True between a drag's first change and its end or cancellation.</summary>
    public bool IsHorizontalDragActive
    {
        get { RequireActive(); return _native.HorizontalDragActive; }
    }

    /// <summary>
    /// Reports a drag as the gesture would (for tests and automation): each
    /// value in <paramref name="translations"/> as a change, then an end at the
    /// last one (predicted end <paramref name="predictedEnd"/>, or the last value).
    /// </summary>
    public void InvokeHorizontalDrag(double[] translations, double? predictedEnd = null)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(translations);
        if (translations.Length == 0)
            throw new ArgumentException("A drag needs at least one translation.", nameof(translations));
        if (_dragEndedHandler is null)
            throw new InvalidOperationException("This view has no horizontal drag handler.");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached view cannot invoke its drag until reparented.");
        foreach (var translation in translations)
            _native.ReportHorizontalDragChanged(translation);
        var last = translations[^1];
        _native.ReportHorizontalDragEnded(last, predictedEnd ?? last);
    }

    /// <summary>
    /// Offsets this view by (<paramref name="offsetX"/>, <paramref name="offsetY"/>)
    /// points and rotates it <paramref name="rotationDegrees"/> degrees about its
    /// center (SwiftUI <c>offset</c> and <c>rotationEffect</c>, which do not
    /// change layout). With <paramref name="animated"/> the change animates with
    /// a spring, for example a card springing back to zero; otherwise it applies
    /// immediately, as a card following the finger does. Views that never call
    /// this are unchanged.
    /// </summary>
    public SwiftView WithTransform(double offsetX, double offsetY = 0, double rotationDegrees = 0,
                                   bool animated = false)
    {
        RequireActive();
        if (!double.IsFinite(offsetX)) throw new ArgumentOutOfRangeException(nameof(offsetX));
        if (!double.IsFinite(offsetY)) throw new ArgumentOutOfRangeException(nameof(offsetY));
        if (!double.IsFinite(rotationDegrees)) throw new ArgumentOutOfRangeException(nameof(rotationDegrees));
        _native.SetTransform(offsetX, offsetY, rotationDegrees, animated);
        return this;
    }

    /// <summary>
    /// Hides this view in place, as SwiftUI <c>hidden()</c> does: it keeps its
    /// layout space (nothing around it moves), cannot be tapped, and is hidden
    /// from accessibility. The change animates over <paramref name="durationSeconds"/>
    /// (ease in-out): <see cref="SwiftHideTransition.Fade"/> fades the view;
    /// <see cref="SwiftHideTransition.SlideDown"/> also moves it down by its own
    /// height, and only fades when Reduce Motion is on. Call it before the view is
    /// first shown and then as often as needed. Views that never call this are unchanged.
    /// </summary>
    public SwiftView WithHidden(bool hidden, SwiftHideTransition transition = SwiftHideTransition.Fade,
                                double durationSeconds = 0.2)
    {
        RequireActive();
        if (!double.IsFinite(durationSeconds) || durationSeconds < 0 || durationSeconds > 10)
            throw new ArgumentOutOfRangeException(nameof(durationSeconds));
        _native.SetHidden(hidden, transition switch
        {
            SwiftHideTransition.Fade => "fade",
            SwiftHideTransition.SlideDown => "slideDown",
            _ => throw new ArgumentOutOfRangeException(nameof(transition))
        }, durationSeconds);
        return this;
    }

    /// <summary>Whether the latest <see cref="WithHidden"/> hid this view (false unless set).</summary>
    public bool IsHidden { get { RequireActive(); return _native.HiddenInPlace; } }

    /// <summary>The latest <see cref="WithHidden"/> transition (<see cref="SwiftHideTransition.Fade"/> unless set).</summary>
    public SwiftHideTransition HideTransition
    {
        get
        {
            RequireActive();
            return _native.HiddenTransition == "slideDown"
                ? SwiftHideTransition.SlideDown : SwiftHideTransition.Fade;
        }
    }

    /// <summary>
    /// Reports this Scroll's vertical geometry (SwiftUI <c>onScrollGeometryChange</c>)
    /// whenever its content offset, content height, container height or content
    /// insets move by one point or more, for example to slide a floating button
    /// away while the person scrolls down. Needs iOS 18 or macOS 15; earlier
    /// systems report nothing. Attach it before the scroll is first shown:
    /// attaching it to a shown scroll recreates the scroll at its start. Scrolls
    /// that never call this are unchanged.
    /// </summary>
    public SwiftView OnScrollGeometryChanged(Action<SwiftScrollGeometry> handler)
    {
        RequireKind("scroll");
        ArgumentNullException.ThrowIfNull(handler);
        _scrollGeometryChangedHandler = (offset, content, container, top, bottom) =>
            handler(new SwiftScrollGeometry(offset, content, container, top, bottom));
        if (_nativeHandlersActive)
            _native.SetScrollGeometryChangedHandler(_scrollGeometryChangedHandler);
        return this;
    }

    /// <summary>Reports a scroll geometry as SwiftUI would (for tests and automation).</summary>
    public void InvokeScrollGeometryChanged(SwiftScrollGeometry geometry)
    {
        RequireKind("scroll");
        if (_scrollGeometryChangedHandler is null)
            throw new InvalidOperationException("This scroll has no scroll geometry handler.");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached view cannot report until reparented.");
        _native.ReportScrollGeometry(geometry.ContentOffsetY, geometry.ContentHeight,
            geometry.ContainerHeight, geometry.ContentInsetTop, geometry.ContentInsetBottom);
    }

    /// <summary>
    /// Reports how many points of this view's bottom the on-screen keyboard covers
    /// (SwiftUI's keyboard safe-area region, read from the view's own geometry):
    /// once when the view appears and again on each change of a point or more.
    /// It is 0 with no keyboard, a hardware keyboard or a floating keyboard.
    /// Attach it before the view is first shown. Views that never call this are unchanged.
    /// </summary>
    public SwiftView OnKeyboardOverlapChanged(Action<double> handler)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        _keyboardOverlapChangedHandler = handler;
        if (_nativeHandlersActive)
            _native.SetKeyboardOverlapChangedHandler(handler);
        return this;
    }

    /// <summary>Reports a keyboard overlap as SwiftUI would (for tests and automation).</summary>
    public void InvokeKeyboardOverlapChanged(double points)
    {
        RequireActive();
        if (_keyboardOverlapChangedHandler is null)
            throw new InvalidOperationException("This view has no keyboard overlap handler.");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached view cannot report until reparented.");
        _native.ReportKeyboardOverlap(points);
    }

    /// <summary>
    /// Reports whether VoiceOver runs and Reduce Motion is on (SwiftUI
    /// <c>accessibilityVoiceOverEnabled</c> and <c>accessibilityReduceMotion</c>):
    /// once when the view appears and again whenever either changes. Attach it
    /// before the view is first shown. Views that never call this are unchanged.
    /// </summary>
    public SwiftView OnAccessibilitySettingsChanged(Action<SwiftAccessibilitySettings> handler)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(handler);
        _accessibilitySettingsChangedHandler = flags =>
            handler((SwiftAccessibilitySettings)(int)flags
                & (SwiftAccessibilitySettings.VoiceOver | SwiftAccessibilitySettings.ReduceMotion));
        if (_nativeHandlersActive)
            _native.SetAccessibilitySettingsChangedHandler(_accessibilitySettingsChangedHandler);
        return this;
    }

    /// <summary>Reports the assistive settings as SwiftUI would (for tests and automation).</summary>
    public void InvokeAccessibilitySettingsChanged(SwiftAccessibilitySettings settings)
    {
        RequireActive();
        if (_accessibilitySettingsChangedHandler is null)
            throw new InvalidOperationException("This view has no accessibility settings handler.");
        if (!_nativeHandlersActive)
            throw new InvalidOperationException("A detached view cannot report until reparented.");
        _native.ReportAccessibilitySettings(settings.HasFlag(SwiftAccessibilitySettings.VoiceOver),
            settings.HasFlag(SwiftAccessibilitySettings.ReduceMotion));
    }

    /// <summary>The latest <see cref="WithTransform"/> horizontal offset in points (0 unless set).</summary>
    public double OffsetX { get { RequireActive(); return _native.OffsetX; } }

    /// <summary>The latest <see cref="WithTransform"/> vertical offset in points (0 unless set).</summary>
    public double OffsetY { get { RequireActive(); return _native.OffsetY; } }

    /// <summary>The latest <see cref="WithTransform"/> rotation in degrees (0 unless set).</summary>
    public double RotationDegrees { get { RequireActive(); return _native.RotationDegrees; } }

    /// <summary>Whether the latest <see cref="WithTransform"/> change animates.</summary>
    public bool IsTransformAnimated { get { RequireActive(); return _native.TransformAnimated; } }

    /// <summary>
    /// Scrolls this Scroll or List so the descendant with accessibility identifier
    /// <paramref name="accessibilityIdentifier"/> is at <paramref name="anchor"/>
    /// (SwiftUI <c>ScrollViewReader</c> and <c>ScrollViewProxy.scrollTo(_:anchor:)</c>).
    /// Once requested, descendant identifiers in this scroll also become SwiftUI
    /// identities. A scroll mounted with a request applies it without animation;
    /// later requests animate when <paramref name="animated"/> is true. Scrolls
    /// that never call this are unchanged.
    /// </summary>
    public SwiftView ScrollTo(string accessibilityIdentifier,
                              SwiftScrollAnchor anchor = SwiftScrollAnchor.Center,
                              bool animated = true)
    {
        RequireActive();
        if (Kind is not ("scroll" or "list"))
            throw new InvalidOperationException($"Expected a scroll or list node, not {Kind}.");
        ArgumentException.ThrowIfNullOrWhiteSpace(accessibilityIdentifier);
        if (!Enum.IsDefined(anchor))
            throw new ArgumentOutOfRangeException(nameof(anchor));
        _native.RequestScrollTo(accessibilityIdentifier, anchor switch
        {
            SwiftScrollAnchor.Top => "top",
            SwiftScrollAnchor.Bottom => "bottom",
            _ => "center"
        }, animated);
        return this;
    }

    /// <summary>The identifier of the latest <see cref="ScrollTo"/> request, or empty.</summary>
    public string ScrollTargetIdentifier
    {
        get { RequireActive(); return _native.ScrollTargetId; }
    }

    /// <summary>The 11-character YouTube video id a YouTube player shows.</summary>
    public string VideoId
    {
        get { RequireKind("youTubePlayer"); return _native.VideoId; }
        set
        {
            RequireKind("youTubePlayer");
            _native.VideoId = ValidateYouTubeVideoId(value);
        }
    }

    public SwiftView WithNavigationTitle(string title)
    {
        RequireActive();
        _native.NavigationTitle = title ?? throw new ArgumentNullException(nameof(title));
        return this;
    }

    /// <summary>
    /// A subtitle under the navigation title (SwiftUI <c>navigationSubtitle</c>, iOS 26), e.g.
    /// a count as in Notes; empty removes it.
    /// </summary>
    public SwiftView WithNavigationSubtitle(string subtitle)
    {
        RequireActive();
        ArgumentNullException.ThrowIfNull(subtitle);
        if (_native.NavigationSubtitle != subtitle)
            _native.NavigationSubtitle = subtitle;
        return this;
    }

    /// <summary>The subtitle set by <see cref="WithNavigationSubtitle"/>.</summary>
    public string NavigationSubtitle
    {
        get { RequireActive(); return _native.NavigationSubtitle; }
    }

    /// <summary>
    /// While searching, keep the toolbar's other items (filters, add) instead of letting the
    /// system hide them (SwiftUI <c>searchPresentationToolbarBehavior(.avoidHidingContent)</c>).
    /// </summary>
    public SwiftView WithSearchKeepingToolbar(bool keep = true)
    {
        RequireKind("searchable");
        if (_native.SearchKeepsToolbar != keep)
            _native.SearchKeepsToolbar = keep;
        return this;
    }

    /// <summary>Where this searchable's field goes (default: the system's choice).</summary>
    public SwiftView WithSearchPlacement(SwiftSearchPlacement placement)
    {
        RequireKind("searchable");
        _native.SearchPlacement = placement switch
        {
            SwiftSearchPlacement.Automatic => "",
            SwiftSearchPlacement.BottomBar => "bottomBar",
            _ => throw new ArgumentOutOfRangeException(nameof(placement)),
        };
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

    /// <summary>
    /// Hides the tab bar while this view shows, but only in a compact horizontal size class
    /// (iPhone, the folded iPhone Duo): a page in a regular-width split view keeps the tabs.
    /// </summary>
    public SwiftView WithTabBarHiddenInCompactWidth(bool hidden = true)
    {
        RequireActive();
        _native.HidesTabBar = hidden;
        _native.HidesTabBarOnlyInCompactWidth = hidden;
        return this;
    }

    /// <summary>
    /// Leaves this view out in a compact horizontal size class (iPhone, the folded iPhone Duo):
    /// for a control that only makes sense beside other columns, such as a split view's
    /// full-screen button. Off by default.
    /// </summary>
    public SwiftView WithHiddenInCompactWidth(bool hidden = true)
    {
        RequireActive();
        _native.HiddenInCompactWidth = hidden;
        return this;
    }

    /// <summary>Whether <see cref="WithHiddenInCompactWidth"/> is on.</summary>
    public bool HiddenInCompactWidth { get { RequireActive(); return _native.HiddenInCompactWidth; } }

    /// <summary>Whether this view hides the tab bar (<see cref="WithTabBarHidden"/>).</summary>
    public bool TabBarHidden { get { RequireActive(); return _native.HidesTabBar; } }

    /// <summary>Whether <see cref="TabBarHidden"/> applies only in a compact width.</summary>
    public bool TabBarHiddenOnlyInCompactWidth
    {
        get { RequireActive(); return _native.HidesTabBarOnlyInCompactWidth; }
    }

    /// <summary>
    /// Gives a <see cref="SwiftUI.Tab"/> a role. A tab view with a role, a hidden tab or a
    /// style is drawn with the SwiftUI <c>Tab</c> API (iOS 18 / macOS 15); set it before
    /// the tab view is mounted.
    /// </summary>
    public SwiftView WithTabRole(SwiftTabRole role)
    {
        RequireKind("tab");
        if (!Enum.IsDefined(role))
            throw new ArgumentOutOfRangeException(nameof(role));
        _native.TabRole = role == SwiftTabRole.Search ? "search" : "";
        return this;
    }

    /// <summary>The role set by <see cref="WithTabRole"/> (<see cref="SwiftTabRole.None"/> unless set).</summary>
    public SwiftTabRole TabRole
    {
        get
        {
            RequireKind("tab");
            return _native.TabRole == "search" ? SwiftTabRole.Search : SwiftTabRole.None;
        }
    }

    /// <summary>
    /// Leaves a <see cref="SwiftUI.Tab"/> out of the tab bar and sidebar while keeping its
    /// index. Call it once before the tab view is mounted (with false to start visible);
    /// later calls show or hide the tab in place.
    /// </summary>
    public SwiftView WithTabHidden(bool hidden = true)
    {
        RequireKind("tab");
        _native.TabHidden = hidden;
        return this;
    }

    /// <summary>Whether <see cref="WithTabHidden"/> hid this tab (false unless set).</summary>
    public bool IsTabHidden
    {
        get
        {
            RequireKind("tab");
            return _native.TabHidden;
        }
    }

    /// <summary>Sets a <see cref="SwiftUI.TabView(int, Action{int}?, SwiftView[])"/> style; set it before the tab view is mounted.</summary>
    public SwiftView WithTabViewStyle(SwiftTabViewStyle style)
    {
        RequireKind("tabView");
        if (!Enum.IsDefined(style))
            throw new ArgumentOutOfRangeException(nameof(style));
        _native.TabViewStyle = style switch
        {
            SwiftTabViewStyle.SidebarAdaptable => "sidebarAdaptable",
            SwiftTabViewStyle.TabBarOnly => "tabBarOnly",
            _ => "",
        };
        return this;
    }

    /// <summary>
    /// Sets when an iOS 26 tab bar minimizes (SwiftUI <c>tabBarMinimizeBehavior</c>); earlier
    /// iOS and other platforms ignore it. Set it before the tab view is mounted.
    /// </summary>
    public SwiftView WithTabBarMinimizeBehavior(SwiftTabBarMinimizeBehavior behavior)
    {
        RequireKind("tabView");
        _native.TabBarMinimizeBehavior = behavior switch
        {
            SwiftTabBarMinimizeBehavior.Automatic => "",
            SwiftTabBarMinimizeBehavior.OnScrollDown => "onScrollDown",
            SwiftTabBarMinimizeBehavior.OnScrollUp => "onScrollUp",
            SwiftTabBarMinimizeBehavior.Never => "never",
            _ => throw new ArgumentOutOfRangeException(nameof(behavior))
        };
        return this;
    }

    /// <summary>The behavior set by <see cref="WithTabBarMinimizeBehavior"/>.</summary>
    public SwiftTabBarMinimizeBehavior TabBarMinimizeBehavior
    {
        get
        {
            RequireKind("tabView");
            return _native.TabBarMinimizeBehavior switch
            {
                "onScrollDown" => SwiftTabBarMinimizeBehavior.OnScrollDown,
                "onScrollUp" => SwiftTabBarMinimizeBehavior.OnScrollUp,
                "never" => SwiftTabBarMinimizeBehavior.Never,
                _ => SwiftTabBarMinimizeBehavior.Automatic
            };
        }
    }

    /// <summary>The style set by <see cref="WithTabViewStyle"/> (<see cref="SwiftTabViewStyle.Automatic"/> unless set).</summary>
    public SwiftTabViewStyle TabViewStyle
    {
        get
        {
            RequireKind("tabView");
            return _native.TabViewStyle switch
            {
                "sidebarAdaptable" => SwiftTabViewStyle.SidebarAdaptable,
                "tabBarOnly" => SwiftTabViewStyle.TabBarOnly,
                _ => SwiftTabViewStyle.Automatic,
            };
        }
    }

    public SwiftView WithAccessibilityLabel(string label)
    {
        RequireActive();
        _native.AccessibilityLabelText = label ?? throw new ArgumentNullException(nameof(label));
        return this;
    }

    /// <summary>The announcement set by <see cref="WithAccessibilityAnnouncement"/>, or empty.</summary>
    public string AccessibilityAnnouncement => _native.AccessibilityAnnouncement;

    /// <summary>
    /// Asks VoiceOver to announce <paramref name="text"/> when this view appears
    /// and whenever the text changes (SwiftUI
    /// <c>AccessibilityNotification.Announcement</c>), for a status message that
    /// does not take focus, such as a toast. Empty (the default) announces nothing.
    /// </summary>
    public SwiftView WithAccessibilityAnnouncement(string text)
    {
        RequireActive();
        _native.AccessibilityAnnouncement = text ?? throw new ArgumentNullException(nameof(text));
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

    /// <summary>Sets the button's role (SwiftUI <c>Button(role:)</c>); default none.</summary>
    public SwiftView WithButtonRole(SwiftButtonRole role)
    {
        RequireKind("button");
        _native.ButtonRole = role switch
        {
            SwiftButtonRole.None => "",
            SwiftButtonRole.Destructive => "destructive",
            SwiftButtonRole.Cancel => "cancel",
            _ => throw new ArgumentOutOfRangeException(nameof(role)),
        };
        return this;
    }

    /// <summary>The role set by <see cref="WithButtonRole"/>.</summary>
    public SwiftButtonRole ButtonRole
    {
        get
        {
            RequireKind("button");
            return _native.ButtonRole switch
            {
                "destructive" => SwiftButtonRole.Destructive,
                "cancel" => SwiftButtonRole.Cancel,
                _ => SwiftButtonRole.None,
            };
        }
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

    /// <summary>
    /// Sets the sheet height as a fraction of the screen. On an Inspector it applies
    /// only when SwiftUI presents the inspector as a sheet (compact width).
    /// </summary>
    public SwiftView WithSheetDetentFraction(double fraction)
    {
        RequireActive();
        if (Kind is not ("sheet" or "inspector"))
            throw new InvalidOperationException($"Expected a sheet or inspector node, not {Kind}.");
        if (!double.IsFinite(fraction) || fraction <= 0 || fraction > 1)
            throw new ArgumentOutOfRangeException(nameof(fraction));
        _native.SheetDetentFraction = fraction;
        return this;
    }

    /// <summary>
    /// Sets the inspector column width (SwiftUI <c>inspectorColumnWidth(min:ideal:max:)</c>)
    /// used in a regular horizontal size class. Omitted bounds stay system-defined;
    /// equal bounds fix the width. Unset by default.
    /// </summary>
    public SwiftView WithInspectorColumnWidth(double ideal, double? min = null, double? max = null)
    {
        RequireKind("inspector");
        if (!double.IsFinite(ideal) || ideal <= 0)
            throw new ArgumentOutOfRangeException(nameof(ideal));
        if (min is { } low && (!double.IsFinite(low) || low <= 0 || low > ideal))
            throw new ArgumentOutOfRangeException(nameof(min));
        if (max is { } high && (!double.IsFinite(high) || high < ideal))
            throw new ArgumentOutOfRangeException(nameof(max));
        _native.InspectorMinWidth = min ?? 0;
        _native.InspectorMaxWidth = max ?? 0;
        _native.InspectorIdealWidth = ideal;
        return this;
    }

    /// <summary>
    /// Which columns a <see cref="SwiftUI.NavigationSplitView(SwiftView, SwiftView, SwiftView, Action{SwiftSplitViewVisibility}?, Action{SwiftSplitViewColumn}?)"/>
    /// shows in a regular width. Setting it does not report a change; the person showing or
    /// hiding the sidebar does.
    /// </summary>
    public SwiftSplitViewVisibility SplitColumnVisibility
    {
        get { RequireKind("splitView"); return ParseSplitVisibility(_native.SplitColumnVisibility); }
        set
        {
            RequireKind("splitView");
            _native.SplitColumnVisibility = value switch
            {
                SwiftSplitViewVisibility.Automatic => "automatic",
                SwiftSplitViewVisibility.All => "all",
                SwiftSplitViewVisibility.DoubleColumn => "doubleColumn",
                SwiftSplitViewVisibility.DetailOnly => "detailOnly",
                _ => throw new ArgumentOutOfRangeException(nameof(value)),
            };
        }
    }

    /// <summary>
    /// The split view column shown when it collapses to one column (a compact width). Setting
    /// it navigates the collapsed stack and does not report a change; the person going back does.
    /// </summary>
    public SwiftSplitViewColumn PreferredCompactColumn
    {
        get
        {
            RequireKind("splitView");
            return _native.SplitCompactColumn switch
            {
                "content" => SwiftSplitViewColumn.Content,
                "detail" => SwiftSplitViewColumn.Detail,
                _ => SwiftSplitViewColumn.Sidebar,
            };
        }
        set
        {
            RequireKind("splitView");
            _native.SplitCompactColumn = value switch
            {
                SwiftSplitViewColumn.Sidebar => "sidebar",
                SwiftSplitViewColumn.Content => "content",
                SwiftSplitViewColumn.Detail => "detail",
                _ => throw new ArgumentOutOfRangeException(nameof(value)),
            };
        }
    }

    /// <summary>Sets how the split view's columns share the width (default automatic).</summary>
    public SwiftView WithSplitViewStyle(SwiftSplitViewStyle style)
    {
        RequireKind("splitView");
        _native.SplitViewStyle = style switch
        {
            SwiftSplitViewStyle.Automatic => "",
            SwiftSplitViewStyle.Balanced => "balanced",
            SwiftSplitViewStyle.ProminentDetail => "prominentDetail",
            _ => throw new ArgumentOutOfRangeException(nameof(style)),
        };
        return this;
    }

    /// <summary>The style set by <see cref="WithSplitViewStyle"/>.</summary>
    public SwiftSplitViewStyle SplitViewStyle
    {
        get
        {
            RequireKind("splitView");
            return _native.SplitViewStyle switch
            {
                "balanced" => SwiftSplitViewStyle.Balanced,
                "prominentDetail" => SwiftSplitViewStyle.ProminentDetail,
                _ => SwiftSplitViewStyle.Automatic,
            };
        }
    }

    /// <summary>
    /// Whether the split view leaves out its sidebar toggle (SwiftUI
    /// <c>toolbar(removing: .sidebarToggle)</c> on the sidebar column); default false, so the
    /// toggle shows. Without its toggle the system keeps the sidebar shown beside the other
    /// columns (observed on iPadOS 27.1), since nothing else could bring it back.
    /// </summary>
    public bool SidebarToggleHidden
    {
        get
        {
            RequireKind("splitView");
            return _native.SplitSidebarToggleHidden;
        }
        set
        {
            RequireKind("splitView");
            RequireActive();
            if (_native.SplitSidebarToggleHidden != value)
                _native.SplitSidebarToggleHidden = value;
        }
    }

    /// <summary>
    /// Sets this split view column's width (SwiftUI <c>navigationSplitViewColumnWidth(min:ideal:max:)</c>);
    /// call it on the column passed to <c>NavigationSplitView</c>. Omitted bounds stay
    /// system-defined. It has no effect outside a split view.
    /// </summary>
    public SwiftView WithSplitColumnWidth(double ideal, double? min = null, double? max = null)
    {
        RequireActive();
        if (!double.IsFinite(ideal) || ideal <= 0)
            throw new ArgumentOutOfRangeException(nameof(ideal));
        if (min is { } low && (!double.IsFinite(low) || low <= 0 || low > ideal))
            throw new ArgumentOutOfRangeException(nameof(min));
        if (max is { } high && (!double.IsFinite(high) || high < ideal))
            throw new ArgumentOutOfRangeException(nameof(max));
        _native.SplitColumnMinWidth = min ?? 0;
        _native.SplitColumnMaxWidth = max ?? 0;
        _native.SplitColumnIdealWidth = ideal;
        return this;
    }

    internal static SwiftSplitViewVisibility ParseSplitVisibility(string name) => name switch
    {
        "all" => SwiftSplitViewVisibility.All,
        "doubleColumn" => SwiftSplitViewVisibility.DoubleColumn,
        "detailOnly" => SwiftSplitViewVisibility.DetailOnly,
        _ => SwiftSplitViewVisibility.Automatic,
    };

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
        if (_native.FixedHorizontalSize)
            throw new InvalidOperationException("A view that keeps its ideal width cannot be flexible.");
        if (_native.FixedWidth > 0)
            throw new InvalidOperationException("A view with a fixed width cannot be flexible.");
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

    /// <summary>
    /// Lets this view take the full height its container proposes (SwiftUI
    /// <c>frame(maxHeight: .infinity)</c>), so equal flexible siblings share a
    /// bounded stack's height evenly. Content keeps the horizontal alignment set by
    /// <see cref="WithFlexibleWidth"/> and is centered vertically. Off by default;
    /// inside a Scroll the proposed height is the content's own.
    /// </summary>
    /// <summary>Whether <see cref="WithFlexibleHeight"/> is on.</summary>
    /// <summary>
    /// Lays the view out under the safe areas too (SwiftUI <c>ignoresSafeArea()</c>), for
    /// example a full-screen launch surface centred on the whole screen. Off by default.
    /// </summary>
    public SwiftView WithIgnoresSafeArea(bool enabled = true)
    {
        RequireActive();
        _native.IgnoresSafeArea = enabled;
        return this;
    }

    /// <summary>Whether <see cref="WithIgnoresSafeArea"/> is on.</summary>
    public bool IgnoresSafeArea => _native.IgnoresSafeArea;

    /// <summary>
    /// Keeps the view at its ideal width and/or height whatever its container proposes
    /// (SwiftUI <c>fixedSize(horizontal:vertical:)</c>). In a row with a flexible title, a
    /// badge or a short button keeps its text on one line instead of taking an equal share of
    /// the row and wrapping. Off by default. A flexible axis (<see cref="WithFlexibleWidth"/>,
    /// <see cref="WithFlexibleHeight"/>) cannot also be fixed.
    /// </summary>
    public SwiftView WithFixedSize(bool horizontal = true, bool vertical = false)
    {
        RequireActive();
        if (horizontal && _native.FillsWidth)
            throw new InvalidOperationException("A flexible-width view cannot keep its ideal width.");
        if (horizontal && _native.FixedWidth > 0)
            throw new InvalidOperationException("A view with a fixed width cannot keep its ideal width.");
        if (vertical && _native.FillsHeight)
            throw new InvalidOperationException("A flexible-height view cannot keep its ideal height.");
        _native.FixedHorizontalSize = horizontal;
        _native.FixedVerticalSize = vertical;
        return this;
    }

    /// <summary>
    /// Makes the view exactly <paramref name="width"/> points wide whatever its container
    /// proposes (SwiftUI <c>frame(width:)</c>), for example a fixed sidebar column beside a
    /// flexible one. Content narrower than the width sits at its leading edge. Null removes it.
    /// Off by default. A
    /// flexible-width view (<see cref="WithFlexibleWidth"/>) or one that keeps its ideal width
    /// (<see cref="WithFixedSize"/>) cannot also have a fixed width; a flexible height can.
    /// </summary>
    public SwiftView WithFixedWidth(double? width)
    {
        RequireActive();
        if (width is { } value)
        {
            if (!double.IsFinite(value) || value <= 0)
                throw new ArgumentOutOfRangeException(nameof(width));
            if (_native.FillsWidth)
                throw new InvalidOperationException("A flexible-width view cannot have a fixed width.");
            if (_native.FixedHorizontalSize)
                throw new InvalidOperationException("A view that keeps its ideal width cannot have a fixed width.");
        }
        _native.FixedWidth = width ?? 0;
        return this;
    }

    /// <summary>The width <see cref="WithFixedWidth"/> set, or null.</summary>
    public double? FixedWidth => _native.FixedWidth > 0 ? _native.FixedWidth : null;

    /// <summary>Whether <see cref="WithFixedSize"/> keeps this view's ideal width.</summary>
    public bool FixedHorizontalSize => _native.FixedHorizontalSize;

    /// <summary>Whether <see cref="WithFixedSize"/> keeps this view's ideal height.</summary>
    public bool FixedVerticalSize => _native.FixedVerticalSize;

    public bool FillsHeight => _native.FillsHeight;

    public SwiftView WithFlexibleHeight(bool enabled = true)
    {
        RequireActive();
        if (enabled && _native.FixedVerticalSize)
            throw new InvalidOperationException("A view that keeps its ideal height cannot be flexible.");
        _native.FillsHeight = enabled;
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

    /// <summary>
    /// Opens a Scroll at its end and keeps the end visible when its content or
    /// container grows, as a chat transcript does (SwiftUI
    /// <c>defaultScrollAnchor(.bottom)</c> for the initial-offset and size-change roles).
    /// Short content keeps its alignment. Off by default.
    /// </summary>
    public SwiftView WithScrollAnchoredToBottom(bool enabled = true)
    {
        RequireKind("scroll");
        _native.AnchorsToBottom = enabled;
        return this;
    }

    /// <summary>
    /// Sets how dragging this Scroll dismisses the software keyboard (SwiftUI
    /// <c>scrollDismissesKeyboard</c>), for example so a page with a multiline editor can put
    /// the keyboard away. <see cref="SwiftScrollDismissesKeyboard.Automatic"/> (the default)
    /// keeps the system's behavior; scrollable views inside the content (a TextEditor, a nested
    /// Scroll) keep their own default. Set it before the Scroll is mounted.
    /// </summary>
    public SwiftView WithScrollDismissesKeyboard(SwiftScrollDismissesKeyboard mode)
    {
        RequireKind("scroll");
        _native.ScrollDismissesKeyboard = mode switch
        {
            SwiftScrollDismissesKeyboard.Automatic => "",
            SwiftScrollDismissesKeyboard.Immediately => "immediately",
            SwiftScrollDismissesKeyboard.Interactively => "interactively",
            SwiftScrollDismissesKeyboard.Never => "never",
            _ => throw new ArgumentOutOfRangeException(nameof(mode))
        };
        return this;
    }

    /// <summary>The mode set by <see cref="WithScrollDismissesKeyboard"/>.</summary>
    public SwiftScrollDismissesKeyboard ScrollDismissesKeyboard
    {
        get
        {
            RequireKind("scroll");
            return _native.ScrollDismissesKeyboard switch
            {
                "immediately" => SwiftScrollDismissesKeyboard.Immediately,
                "interactively" => SwiftScrollDismissesKeyboard.Interactively,
                "never" => SwiftScrollDismissesKeyboard.Never,
                _ => SwiftScrollDismissesKeyboard.Automatic
            };
        }
    }

    /// <summary>
    /// Draws only this Toggle's switch (SwiftUI <c>labelsHidden</c>); its text stays the
    /// accessible name. Lets a row put the switch beside other content without the label
    /// taking the width. Off by default.
    /// </summary>
    public SwiftView WithLabelsHidden(bool hidden = true)
    {
        RequireKind("toggle");
        _native.LabelsHidden = hidden;
        return this;
    }

    /// <summary>Whether <see cref="WithLabelsHidden"/> hides this Toggle's label.</summary>
    public bool LabelsHidden
    {
        get
        {
            RequireKind("toggle");
            return _native.LabelsHidden;
        }
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
        RequireActive();
        // A searchable reports its remaining search tokens through it.
        if (Kind is not ("valuePicker" or "splitView" or "searchable"))
            throw new InvalidOperationException($"Expected a value picker, split view or searchable node, not {Kind}.");
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

    internal void SetPhotoPickerHandlers(Action<SwiftPickedPhoto> picked, Action? cancelled,
                                         Action<string>? error)
    {
        RequireKind("photoPicker");
        ArgumentNullException.ThrowIfNull(picked);
        _photoPickedHandler = (data, mimeType, typeIdentifier) =>
            picked(new SwiftPickedPhoto(data.ToArray(), mimeType, typeIdentifier));
        _photoPickCancelledHandler = cancelled;
        _photoPickErrorHandler = error;
        if (_nativeHandlersActive)
        {
            _native.SetPhotoPickedHandler(_photoPickedHandler);
            if (cancelled is not null)
                _native.SetPhotoPickCancelledHandler(cancelled);
            if (error is not null)
                _native.SetPhotoPickErrorHandler(error);
        }
    }

    /// <summary>A BCP 47 tag such as <c>ko</c>, <c>ko-KR</c> or <c>zh-Hant-TW</c>.</summary>
    internal static string ValidateLanguageTag(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        var parts = value.Split('-');
        var valid = value.Length <= 35 && parts[0].Length is >= 2 and <= 3
            && parts[0].All(char.IsAsciiLetter)
            && parts.Skip(1).All(part => part.Length is >= 1 and <= 8 && part.All(char.IsAsciiLetterOrDigit));
        if (!valid)
            throw new ArgumentException("Expected a BCP 47 language tag such as ko-KR.", nameof(value));
        return value;
    }

    /// <summary>A YouTube video id: exactly 11 characters of A-Z, a-z, 0-9, '-' or '_'. URLs are refused.</summary>
    internal static string ValidateYouTubeVideoId(string value)
    {
        ArgumentNullException.ThrowIfNull(value);
        if (value.Length != 11 || !value.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_'))
            throw new ArgumentException("Expected an 11-character YouTube video id, not a URL.", nameof(value));
        return value;
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
        _doubleTapHandler = null;
        _dragChangedHandler = null;
        _dragEndedHandler = null;
        _dragCancelledHandler = null;
        _photoPickedHandler = null;
        _photoPickErrorHandler = null;
        _photoPickCancelledHandler = null;
        _scrollGeometryChangedHandler = null;
        _keyboardOverlapChangedHandler = null;
        _accessibilitySettingsChangedHandler = null;
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
            if (_doubleTapHandler is not null) _native.SetDoubleTapHandler(_doubleTapHandler);
            if (_dragChangedHandler is not null && _dragEndedHandler is not null)
                _native.SetHorizontalDragHandlers(_dragChangedHandler, _dragEndedHandler, _dragCancelledHandler);
            if (_photoPickedHandler is not null) _native.SetPhotoPickedHandler(_photoPickedHandler);
            if (_photoPickErrorHandler is not null) _native.SetPhotoPickErrorHandler(_photoPickErrorHandler);
            if (_photoPickCancelledHandler is not null) _native.SetPhotoPickCancelledHandler(_photoPickCancelledHandler);
            if (_scrollGeometryChangedHandler is not null) _native.SetScrollGeometryChangedHandler(_scrollGeometryChangedHandler);
            if (_keyboardOverlapChangedHandler is not null) _native.SetKeyboardOverlapChangedHandler(_keyboardOverlapChangedHandler);
            if (_accessibilitySettingsChangedHandler is not null) _native.SetAccessibilitySettingsChangedHandler(_accessibilitySettingsChangedHandler);
            _nativeHandlersActive = true;
        }
        foreach (var child in _children)
            child.RestoreNativeHandlers();
    }

    private void RequireSymbolKind()
    {
        RequireActive();
        if (Kind is not ("image" or "label"))
            throw new InvalidOperationException($"Expected an image or label node, not {Kind}.");
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
        if (Kind is not ("textField" or "textEditor" or "secureField" or "searchable"))
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
        if (Kind is not ("sheet" or "inspector" or "alert" or "confirmationDialog" or "fileImporter"
            or "photoPicker" or "photoCover" or "quickSuggestions" or "starterOverlay" or "deleteConfirmation"))
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
