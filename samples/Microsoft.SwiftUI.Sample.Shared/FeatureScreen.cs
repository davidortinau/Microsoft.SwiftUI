using Microsoft.SwiftUI;
using Views = Microsoft.SwiftUI.SwiftUI;

namespace Microsoft.SwiftUI.Sample.Shared;

public sealed class FeatureScreen : IDisposable
{
    private int _count;
    private readonly SwiftView _counter;
    private readonly SwiftView _greeting;
    private readonly SwiftView _focusState;
    private readonly SwiftView _sheetState;
    private readonly SwiftView _sheet;

    public SwiftView Root { get; }

    public FeatureScreen()
    {
        _counter = Views.Text("Count: 0").WithAccessibilityIdentifier("sample.counter");
        _greeting = Views.Text("Type a name").WithAccessibilityIdentifier("sample.greeting");
        _focusState = Views.Text("Name is not focused");
        _sheetState = Views.Text("Sheet closed").WithAccessibilityIdentifier("sample.sheet-state");

        var name = Views.TextField("Name", onChanged: value =>
            _greeting.Text = string.IsNullOrWhiteSpace(value) ? "Type a name" : $"Hello, {value}")
            .WithAccessibilityIdentifier("sample.name");
        name.OnFocusChanged(focused =>
            _focusState.Text = focused ? "Name is focused" : "Name is not focused");

        var toggleState = Views.Text("Notifications: off");
        var toggle = Views.Toggle("Notifications", onChanged: value =>
            toggleState.Text = value ? "Notifications: on" : "Notifications: off")
            .WithAccessibilityIdentifier("sample.toggle");

        var level = Views.Text("Level: 0.5");
        var slider = Views.Slider("Practice level", 0, 1, 0.5,
                value => level.Text = $"Level: {value:F1}")
            .WithAccessibilityIdentifier("sample.slider");

        var selection = Views.Text("Selection: Coffee");
        var picker = Views.Picker("Choose one", ["Coffee", "Tea"], onChanged: index =>
            selection.Text = index == 0 ? "Selection: Coffee" : "Selection: Tea")
            .WithAccessibilityIdentifier("sample.picker");

        _sheet = Views.Sheet(
            Views.HStack(
                Views.Button("Open sheet", OpenSheet).WithAccessibilityIdentifier("sample.open-sheet"),
                _sheetState),
            Views.VStack(
                Views.Text("A native SwiftUI sheet").WithAccessibilityIdentifier("sample.sheet-content"),
                Views.Button("Close", CloseSheet)
                    .WithAccessibilityIdentifier("sample.close-sheet")),
            () => _sheetState.Text = "Sheet closed");

        Root = Views.Navigation("SwiftUI Bridge",
            Views.Scroll(
                Views.Text("Shared C# feature declaration")
                    .WithAccessibilityIdentifier("sample.heading"),
                Views.HStack(
                    _counter,
                    Views.Button("Add", () => _counter.Text = $"Count: {++_count}")
                        .WithAccessibilityIdentifier("sample.add")),
                Views.HStack(name, Views.Button("Focus name", () => name.FocusRequested = true)),
                _greeting,
                _focusState,
                toggle,
                toggleState,
                Views.HStack(slider, level),
                picker,
                selection,
                Views.Image("star.fill").WithAccessibilityIdentifier("sample.image"),
                Views.NavigationLink("Browse list",
                    Views.List(Views.Text("First row"), Views.Text("Second row")))
                    .WithAccessibilityIdentifier("sample.list-link"),
                _sheet))
            .WithAccessibilityIdentifier("sample.root");
    }

    private void OpenSheet()
    {
        _sheetState.Text = "Sheet open";
        _sheet.IsPresented = true;
    }

    private void CloseSheet() => _sheet.IsPresented = false;

    public void Dispose() => Root.Dispose();
}
