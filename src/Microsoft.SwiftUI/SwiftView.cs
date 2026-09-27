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
        get { RequireKind("sheet"); return _native.IsPresented; }
        set { RequireKind("sheet"); _native.IsPresented = value; }
    }

    public bool IsOn
    {
        get { RequireKind("toggle"); return _native.IsOn; }
        set { RequireKind("toggle"); _native.IsOn = value; }
    }

    public bool FocusRequested
    {
        get { RequireInput(); return _native.FocusRequested; }
        set { RequireInput(); _native.FocusRequested = value; }
    }

    public double Value
    {
        get { RequireKind("slider"); return _native.Value; }
        set
        {
            RequireKind("slider");
            if (!double.IsFinite(value) || value < _native.Minimum || value > _native.Maximum)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.Value = value;
        }
    }

    public int SelectedIndex
    {
        get { RequireKind("picker"); return checked((int)_native.SelectedIndex); }
        set
        {
            RequireKind("picker");
            if (value < 0 || value >= _children.Count)
                throw new ArgumentOutOfRangeException(nameof(value));
            _native.SelectedIndex = value;
        }
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

    public SwiftView OnFocusChanged(Action<bool> handler)
    {
        RequireInput();
        ArgumentNullException.ThrowIfNull(handler);
        if (_nativeHandlersActive)
            _native.SetFocusChangedHandler(handler);
        _focusChangedHandler = handler;
        return this;
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
        Attach(child);
        return this;
    }

    public void RemoveAt(int index)
    {
        RequireContainer();
        ArgumentOutOfRangeException.ThrowIfNegative(index);
        if (index >= _children.Count)
            throw new ArgumentOutOfRangeException(nameof(index));
        var child = _children[index];
        child.SuspendNativeHandlers();
        _native.RemoveChild(index);
        child._parent = null;
        _children.RemoveAt(index);
    }

    public void Clear()
    {
        RequireContainer();
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
        _nativeHandlersActive = false;
        _native.ClearChildren();
        _tapHandler = null;
        _textChangedHandler = null;
        _boolChangedHandler = null;
        _valueChangedHandler = null;
        _selectionChangedHandler = null;
        _focusChangedHandler = null;
        _dismissedHandler = null;
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
        if (Kind is not ("textField" or "textEditor"))
            throw new InvalidOperationException($"Expected a text input node, not {Kind}.");
    }

    private void RequireContainer()
    {
        RequireActive();
        if (Kind is not ("vstack" or "hstack" or "scroll" or "list"))
            throw new InvalidOperationException($"Expected a stack, scroll, or list node, not {Kind}.");
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
