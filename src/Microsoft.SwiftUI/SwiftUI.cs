using Foundation;

namespace Microsoft.SwiftUI;

public static class SwiftUI
{
    public static SwiftView Text(string text) => Create("text", text);

    public static SwiftView InlineText(SwiftView leading, SwiftView trailing)
    {
        SwiftView.ValidateChildren([leading, trailing]);
        if (leading.Kind != "text" || trailing.Kind != "text")
            throw new ArgumentException("Inline text accepts only two Text nodes.");
        var node = new SwiftView("inlineText");
        node.Attach(leading);
        node.Attach(trailing);
        return node;
    }

    public static SwiftView Button(string title, Action action)
    {
        ArgumentNullException.ThrowIfNull(action);
        var node = Create("button", title);
        node.SetTapHandler(action);
        return node;
    }

    public static SwiftView Button(SwiftView label, Action action)
    {
        ArgumentNullException.ThrowIfNull(action);
        SwiftView.ValidateChildren([label]);
        var node = new SwiftView("button");
        node.Attach(label);
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

    public static SwiftView SecureField(string placeholder, string text = "", Action<string>? onChanged = null)
    {
        var node = Create("secureField", text);
        node.Native.Placeholder = placeholder ?? throw new ArgumentNullException(nameof(placeholder));
        if (onChanged is not null)
            node.SetTextChangedHandler(onChanged);
        return node;
    }

    public static SwiftView VStack(params SwiftView[] children) => Container("vstack", children);
    public static SwiftView HStack(params SwiftView[] children) => Container("hstack", children);
    public static SwiftView ButtonGroup(SwiftView[] buttons, bool wraps = false,
                                        int? selectedIndex = null)
    {
        SwiftView.ValidateChildren(buttons);
        if (buttons.Length == 0 || buttons.Any(button => button.Kind != "button"))
            throw new ArgumentException("A button group needs one or more Button nodes.", nameof(buttons));
        if (selectedIndex is < 0 || selectedIndex >= buttons.Length)
            throw new ArgumentOutOfRangeException(nameof(selectedIndex));
        var group = new SwiftView("buttonGroup");
        group.Native.ButtonGroupWraps = wraps;
        foreach (var button in buttons)
            group.Attach(button);
        if (selectedIndex is int index)
            group.SelectedIndex = index;
        return group;
    }
    public static SwiftView Scroll(params SwiftView[] children) => Container("scroll", children);
    public static SwiftView List(params SwiftView[] children) => Container("list", children);
    public static SwiftView Form(params SwiftView[] children) => Container("form", children);
    public static SwiftView Divider() => new("divider");

    public static SwiftView HorizontalGrid(IReadOnlyList<double> columnMinWidths,
                                           SwiftView headerRow, params SwiftView[] rows)
    {
        ArgumentNullException.ThrowIfNull(columnMinWidths);
        ArgumentNullException.ThrowIfNull(rows);
        var minimums = columnMinWidths.ToArray();
        if (minimums.Length == 0)
            throw new ArgumentException("A grid needs at least one column.", nameof(columnMinWidths));
        if (minimums.Any(width => !double.IsFinite(width) || width < 0))
            throw new ArgumentOutOfRangeException(nameof(columnMinWidths));
        SwiftView.ValidateChildren([headerRow, .. rows]);
        if (headerRow.Kind != "hstack" || headerRow.Children.Count != minimums.Length)
            throw new ArgumentException("The header must be an HStack with one cell per column.",
                                        nameof(headerRow));
        if (rows.Any(row => row.Kind != "hstack" || row.Children.Count != minimums.Length))
            throw new ArgumentException("Every row must be an HStack with one cell per column.",
                                        nameof(rows));

        var grid = new SwiftView("horizontalGrid");
        grid.Native.GridColumnMinimumWidths = minimums.Select(NSNumber.FromDouble).ToArray();
        grid.Add(headerRow);
        foreach (var row in rows)
            grid.Add(row);
        return grid;
    }

    public static SwiftView BottomInset(SwiftView scrollContent, SwiftView footer)
    {
        SwiftView.ValidateChildren([scrollContent, footer]);
        if (scrollContent.Kind != "scroll")
            throw new ArgumentException("The inset content must be a Scroll node.", nameof(scrollContent));
        var inset = new SwiftView("bottomInset");
        inset.Attach(scrollContent);
        inset.Attach(footer);
        return inset;
    }

    public static SwiftView Progress(double value, double total, double thickness,
                                     string accessibilityLabel)
    {
        if (!double.IsFinite(total) || total < 0)
            throw new ArgumentOutOfRangeException(nameof(total));
        if (!double.IsFinite(thickness) || thickness <= 0)
            throw new ArgumentOutOfRangeException(nameof(thickness));
        ArgumentException.ThrowIfNullOrWhiteSpace(accessibilityLabel);

        var progress = new SwiftView("progress");
        progress.Native.Maximum = total;
        progress.Native.ProgressThickness = thickness;
        progress.Value = value;
        progress.WithAccessibilityLabel(accessibilityLabel);
        return progress;
    }

    public static SwiftView IndeterminateProgress(string accessibilityLabel)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(accessibilityLabel);
        return new SwiftView("indeterminateProgress")
            .WithAccessibilityLabel(accessibilityLabel);
    }

    public static SwiftView LazyVGrid(int columns, params SwiftView[] children)
    {
        if (columns is < 1 or > 8)
            throw new ArgumentOutOfRangeException(nameof(columns));
        var grid = Container("grid", children);
        grid.GridColumns = columns;
        return grid;
    }

    public static SwiftView Section(string title, params SwiftView[] children)
    {
        SwiftView.ValidateChildren(children);
        var section = Create("section", title);
        foreach (var child in children)
            section.Attach(child);
        return section;
    }

    public static SwiftView NavigationStack(SwiftView root,
        Action<IReadOnlyList<string>>? onPathChanged = null)
    {
        SwiftView.ValidateChildren([root]);
        var stack = new SwiftView("navigationStack");
        stack.Attach(root);
        stack.SetNavigationChangedHandler(onPathChanged ?? (_ => { }));
        return stack;
    }

    public static SwiftView Tab(string title, string systemImage, SwiftView content)
    {
        SwiftView.ValidateChildren([content]);
        ArgumentException.ThrowIfNullOrWhiteSpace(systemImage);
        var tab = Create("tab", title);
        tab.Native.ImageName = systemImage;
        tab.Attach(content);
        return tab;
    }

    public static SwiftView TabView(params SwiftView[] tabs) =>
        TabView(0, null, tabs);

    public static SwiftView TabView(int selectedIndex, Action<int>? onChanged,
                                    params SwiftView[] tabs)
    {
        SwiftView.ValidateChildren(tabs);
        if (tabs.Length == 0 || tabs.Any(tab => tab.Kind != "tab"))
            throw new ArgumentException("A tab view needs one or more Tab nodes.", nameof(tabs));
        var view = new SwiftView("tabView");
        foreach (var tab in tabs)
            view.Add(tab);
        view.SelectedIndex = selectedIndex;
        if (onChanged is not null)
            view.SetSelectionChangedHandler(index => onChanged(checked((int)index)));
        return view;
    }


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

    /// <summary>
    /// Presents <paramref name="inspector"/> beside <paramref name="content"/> with SwiftUI
    /// <c>inspector(isPresented:content:)</c>: a trailing column that leaves the content
    /// usable in a regular horizontal size class, a sheet in a compact one. Set
    /// <see cref="SwiftView.IsPresented"/> to show or hide it. <paramref name="onDismissed"/>
    /// runs only when the person closes it (for example, swipes the compact sheet away).
    /// </summary>
    public static SwiftView Inspector(SwiftView content, SwiftView inspector, Action? onDismissed = null)
    {
        SwiftView.ValidateChildren([content, inspector]);
        var node = new SwiftView("inspector");
        node.Attach(content);
        node.Attach(inspector);
        if (onDismissed is not null)
            node.SetDismissedHandler(onDismissed);
        return node;
    }

    public static SwiftView FullScreenPhotoCover(
        SwiftView content, SwiftView zoomablePhoto, SwiftView closeButton, Action onDismissed)
    {
        SwiftView.ValidateChildren([content, zoomablePhoto, closeButton]);
        if (zoomablePhoto.Kind != "zoomPhoto" || closeButton.Kind != "button")
            throw new ArgumentException("A photo cover needs a ZoomablePhoto and a Button.");
        ArgumentNullException.ThrowIfNull(onDismissed);
        var cover = new SwiftView("photoCover");
        cover.Attach(content);
        cover.Attach(zoomablePhoto);
        cover.Attach(closeButton);
        cover.SetDismissedHandler(onDismissed);
        return cover;
    }

    public static SwiftView Image(string systemName)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(systemName);
        var node = new SwiftView("image");
        node.Native.ImageName = systemName;
        return node;
    }

    public static SwiftView ImageFromBytes(byte[] imageBytes, string accessibilityLabel,
                                           double maxHeight = 160,
                                           Action? onRendered = null,
                                           Action<string>? onFailed = null)
    {
        if (!double.IsFinite(maxHeight) || maxHeight <= 0)
            throw new ArgumentOutOfRangeException(nameof(maxHeight));
        return Photo(imageBytes, accessibilityLabel, "photo", maxHeight, onRendered, onFailed);
    }

    public static SwiftView ZoomablePhoto(byte[] imageBytes, string accessibilityLabel,
                                           Action? onRendered = null,
                                           Action<string>? onFailed = null) =>
        Photo(imageBytes, accessibilityLabel, "zoomPhoto", 0, onRendered, onFailed);

    private static SwiftView Photo(byte[] imageBytes, string accessibilityLabel, string kind,
                                   double maxHeight, Action? onRendered,
                                   Action<string>? onFailed)
    {
        ArgumentNullException.ThrowIfNull(imageBytes);
        if (imageBytes.Length is 0 or > 8 * 1024 * 1024)
            throw new ArgumentOutOfRangeException(nameof(imageBytes));
        ArgumentException.ThrowIfNullOrWhiteSpace(accessibilityLabel);
        var photo = new SwiftView(kind).WithAccessibilityLabel(accessibilityLabel);
        photo.SetPhotoHandlers(onRendered, onFailed);
        photo.Native.PhotoMaxHeight = maxHeight;
        using var data = NSData.FromArray(imageBytes);
        photo.Native.PhotoData = data;
        return photo;
    }

    public static SwiftView QuickAddSuggestions(
        SwiftView content, string fieldAutomationId, SwiftView suggestions,
        Action? onDismissed = null)
    {
        SwiftView.ValidateChildren([content, suggestions]);
        ArgumentException.ThrowIfNullOrWhiteSpace(fieldAutomationId);
        if (CountTextFields(content, fieldAutomationId) != 1)
            throw new ArgumentException("Exactly one anchored TextField must be within the content.",
                                        nameof(fieldAutomationId));
        var popup = new SwiftView("quickSuggestions");
        popup.Native.QuickAddAnchorId = fieldAutomationId;
        popup.Attach(content);
        popup.Attach(suggestions);
        if (onDismissed is not null)
            popup.SetDismissedHandler(onDismissed);
        return popup;
    }

    private static int CountTextFields(SwiftView view, string automationId) =>
        (view.Kind == "textField" && view.AccessibilityIdentifier == automationId ? 1 : 0)
        + view.Children.Sum(child => CountTextFields(child, automationId));

    public static SwiftView StarterBlockingOverlay(SwiftView content, string status)
    {
        SwiftView.ValidateChildren([content]);
        ArgumentException.ThrowIfNullOrWhiteSpace(status);
        var overlay = Create("starterOverlay", status);
        overlay.Attach(content);
        return overlay;
    }

    public static SwiftView ResourceDeleteConfirmation(
        SwiftView content, string title, string message,
        string closeLabel, string cancelLabel, string deleteLabel,
        Action onCancelled, Action onDelete)
    {
        SwiftView.ValidateChildren([content]);
        ArgumentException.ThrowIfNullOrWhiteSpace(title);
        ArgumentException.ThrowIfNullOrWhiteSpace(message);
        ArgumentException.ThrowIfNullOrWhiteSpace(closeLabel);
        ArgumentException.ThrowIfNullOrWhiteSpace(cancelLabel);
        ArgumentException.ThrowIfNullOrWhiteSpace(deleteLabel);
        ArgumentNullException.ThrowIfNull(onCancelled);
        ArgumentNullException.ThrowIfNull(onDelete);
        var dialog = Create("deleteConfirmation", title);
        dialog.Native.Placeholder = message;
        dialog.Native.DeleteCloseLabel = closeLabel;
        dialog.Native.DeleteCancelLabel = cancelLabel;
        dialog.Native.DeleteConfirmLabel = deleteLabel;
        dialog.SetDeleteHandlers(onCancelled, onDelete);
        dialog.Attach(content);
        return dialog;
    }

    public static SwiftView Circle(double diameter, string lightFillHex, string darkFillHex)
    {
        if (!double.IsFinite(diameter) || diameter <= 0)
            throw new ArgumentOutOfRangeException(nameof(diameter));
        var light = SwiftView.ValidateHex(lightFillHex);
        var dark = SwiftView.ValidateHex(darkFillHex);
        var circle = new SwiftView("circle");
        circle.Native.Diameter = diameter;
        return circle.WithForegroundColor(light, dark);
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

    public static SwiftView Picker(string title, IReadOnlyList<SwiftPickerOption> options,
                                   string selectedValue, Action<string>? onChanged = null)
    {
        ArgumentNullException.ThrowIfNull(options);
        if (options.Count == 0 || options.Any(option => option is null ||
                string.IsNullOrWhiteSpace(option.Value) || string.IsNullOrWhiteSpace(option.Title)) ||
            options.Select(option => option.Value).Distinct(StringComparer.Ordinal).Count() != options.Count)
            throw new ArgumentException("Picker options need unique nonempty values and titles.", nameof(options));
        var node = Create("valuePicker", title);
        foreach (var option in options)
        {
            var child = Text(option.Title);
            child.Native.Route = option.Value;
            node.Attach(child);
        }
        node.SelectedValue = selectedValue;
        if (onChanged is not null)
            node.SetSelectedValueChangedHandler(onChanged);
        return node;
    }

    public static SwiftView Searchable(SwiftView content, string placeholder, string text = "",
                                      Action<string>? onChanged = null)
    {
        SwiftView.ValidateChildren([content]);
        var node = Create("searchable", text);
        node.Native.Placeholder = placeholder ?? throw new ArgumentNullException(nameof(placeholder));
        node.Attach(content);
        if (onChanged is not null)
            node.SetTextChangedHandler(onChanged);
        return node;
    }

    public static SwiftView Menu(string title, params SwiftView[] actions)
    {
        SwiftView.ValidateChildren(actions);
        if (actions.Length == 0 || actions.Any(action => action.Kind != "button"))
            throw new ArgumentException("A menu needs one or more Button actions.", nameof(actions));
        var node = Create("menu", title);
        foreach (var action in actions)
            node.Attach(action);
        return node;
    }

    public static SwiftView Menu(SwiftView label, params SwiftView[] actions)
    {
        ArgumentNullException.ThrowIfNull(label);
        ArgumentNullException.ThrowIfNull(actions);
        SwiftView.ValidateChildren([label, .. actions]);
        if (label.Kind == "button")
            throw new ArgumentException("A menu label cannot be a Button.", nameof(label));
        if (actions.Length == 0 || actions.Any(action => action.Kind != "button"))
            throw new ArgumentException("A menu needs one or more Button actions.", nameof(actions));
        var node = new SwiftView("menu");
        node.Attach(label);
        foreach (var action in actions)
            node.Attach(action);
        return node;
    }

    public static SwiftView Toolbar(SwiftView content, params SwiftView[] actions)
    {
        SwiftView.ValidateChildren([content, .. actions]);
        if (actions.Any(action => action.Kind is not ("button" or "menu")))
            throw new ArgumentException("A toolbar needs Button or Menu actions.", nameof(actions));
        var node = new SwiftView("toolbar");
        node.Attach(content);
        foreach (var action in actions)
            node.Attach(action);
        return node;
    }

    public static SwiftView FileImporter(SwiftView content,
                                        Action<SwiftImportedFile> onImported,
                                        Action<string>? onError = null) =>
        FileImporter(content, onImported, onError, null);

    public static SwiftView FileImporter(SwiftView content,
                                        Action<SwiftImportedFile> onImported,
                                        Action<string>? onError,
                                        Action? onCancelled)
    {
        SwiftView.ValidateChildren([content]);
        ArgumentNullException.ThrowIfNull(onImported);
        var node = new SwiftView("fileImporter");
        node.Attach(content);
        node.SetFileHandlers(onImported, onError, onCancelled);
        return node;
    }

    public static SwiftView Alert(SwiftView content, string title, string message,
                                  params SwiftView[] actions) =>
        PresentWithActions("alert", content, title, message, actions);

    public static SwiftView ConfirmationDialog(SwiftView content, string title,
                                                params SwiftView[] actions) =>
        PresentWithActions("confirmationDialog", content, title, "", actions);

    private static SwiftView PresentWithActions(string kind, SwiftView content, string title,
                                                string message, SwiftView[] actions)
    {
        SwiftView.ValidateChildren([content, .. actions]);
        if (actions.Length == 0 || actions.Any(action => action.Kind != "button"))
            throw new ArgumentException("A presentation needs one or more Button actions.", nameof(actions));
        var node = Create(kind, title);
        node.Native.Placeholder = message ?? throw new ArgumentNullException(nameof(message));
        node.Attach(content);
        foreach (var action in actions)
            node.Attach(action);
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
