namespace Microsoft.SwiftUI;

public static class SwiftUI
{
    public static SwiftView Text(string text) => Create("text", text);

    public static SwiftView Button(string title, Action action)
    {
        ArgumentNullException.ThrowIfNull(action);
        var node = Create("button", title);
        node.SetTapHandler(action);
        return node;
    }

    public static SwiftView TextField(string placeholder, string text = "", Action<string>? onChanged = null)
    {
        var node = Create("textField", text);
        node.Native.Placeholder = placeholder ?? throw new ArgumentNullException(nameof(placeholder));
        if (onChanged is not null)
            node.SetTextChangedHandler(onChanged);
        return node;
    }

    public static SwiftView TextEditor(string text = "", Action<string>? onChanged = null)
    {
        var node = Create("textEditor", text);
        if (onChanged is not null)
            node.SetTextChangedHandler(onChanged);
        return node;
    }

    public static SwiftView VStack(params SwiftView[] children) => Container("vstack", children);
    public static SwiftView HStack(params SwiftView[] children) => Container("hstack", children);
    public static SwiftView Scroll(params SwiftView[] children) => Container("scroll", children);
    public static SwiftView List(params SwiftView[] children) => Container("list", children);

    public static SwiftView Navigation(string title, SwiftView root)
    {
        SwiftView.ValidateChildren([root]);
        var node = Create("navigation", title);
        node.Attach(root);
        return node;
    }

    public static SwiftView NavigationLink(string title, SwiftView destination)
    {
        SwiftView.ValidateChildren([destination]);
        var node = Create("navigationLink", title);
        node.Attach(destination);
        return node;
    }

    public static SwiftView Sheet(SwiftView content, SwiftView modal, Action? onDismissed = null)
    {
        SwiftView.ValidateChildren([content, modal]);
        var node = new SwiftView("sheet");
        node.Attach(content);
        node.Attach(modal);
        if (onDismissed is not null)
            node.SetDismissedHandler(onDismissed);
        return node;
    }

    public static SwiftView Image(string systemName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(systemName);
        var node = new SwiftView("image");
        node.Native.ImageName = systemName;
        return node;
    }

    public static SwiftView Toggle(string title, bool isOn = false, Action<bool>? onChanged = null)
    {
        var node = Create("toggle", title);
        node.IsOn = isOn;
        if (onChanged is not null)
            node.SetBoolChangedHandler(onChanged);
        return node;
    }

    public static SwiftView Slider(string label, double minimum, double maximum, double value,
                                   Action<double>? onChanged = null)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(label);
        if (!double.IsFinite(minimum) || !double.IsFinite(maximum) || minimum >= maximum)
            throw new ArgumentOutOfRangeException(nameof(maximum), "The slider needs finite, increasing bounds.");
        var node = new SwiftView("slider");
        node.AccessibilityLabel = label;
        node.Native.Minimum = minimum;
        node.Native.Maximum = maximum;
        node.Value = value;
        if (onChanged is not null)
            node.SetValueChangedHandler(onChanged);
        return node;
    }

    public static SwiftView Picker(string title, IReadOnlyList<string> options, int selectedIndex = 0,
                                   Action<int>? onChanged = null)
    {
        ArgumentNullException.ThrowIfNull(options);
        if (options.Count == 0 || options.Any(string.IsNullOrWhiteSpace))
            throw new ArgumentException("Picker options must contain nonempty titles.", nameof(options));
        if (selectedIndex < 0 || selectedIndex >= options.Count)
            throw new ArgumentOutOfRangeException(nameof(selectedIndex));

        var node = Create("picker", title);
        foreach (var option in options)
            node.Attach(Text(option));
        node.SelectedIndex = selectedIndex;
        if (onChanged is not null)
            node.SetSelectionChangedHandler(index => onChanged(checked((int)index)));
        return node;
    }

    private static SwiftView Container(string kind, SwiftView[] children)
    {
        SwiftView.ValidateChildren(children);
        var node = new SwiftView(kind);
        foreach (var child in children)
            node.Add(child);
        return node;
    }

    private static SwiftView Create(string kind, string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        var node = new SwiftView(kind) { Text = text };
        return node;
    }
}
