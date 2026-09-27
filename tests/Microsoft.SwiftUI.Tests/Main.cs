using AppKit;
using CoreGraphics;
using Microsoft.SwiftUI;
using Microsoft.SwiftUI.Sample.Shared;
using System.Runtime.CompilerServices;
using Views = Microsoft.SwiftUI.SwiftUI;

NSApplication.Init();

var cases = new (string Name, Action Test)[]
{
    ("native text update", () =>
    {
        var text = Views.Text("Before").WithAccessibilityIdentifier("text.id");
        Assert(text.Text == "Before" && text.AccessibilityIdentifier == "text.id");
        text.Text = "After";
        Assert(text.Text == "After");
    }),
    ("button and text input", () =>
    {
        var taps = 0;
        using var button = Views.Button("Tap", () => taps++);
        using var input = Views.TextField("Name", "Ada").OnFocusChanged(_ => { });
        Assert(button.Text == "Tap" && input.Text == "Ada");
        GC.Collect();
        button.InvokeAction();
        Assert(taps == 1);
        input.FocusRequested = true;
        Assert(input.FocusRequested);
        Assert(Views.TextEditor("Notes").Text == "Notes");
    }),
    ("observable child tree", () =>
    {
        var child = Views.Text("Row");
        var first = Views.VStack(child);
        Assert(first.Children.Count == 1);
        Throws<InvalidOperationException>(() => Views.HStack(child));
        first.RemoveAt(0);
        var second = Views.List(child);
        Assert(second.Children.Count == 1 && first.Children.Count == 0);
        second.Clear();
        Assert(second.Children.Count == 0);
        first.Add(child);
        Assert(first.Children.Count == 1);
        Throws<InvalidOperationException>(() => first.Add(first));
    }),
    ("detached callbacks suspend and restore on reparent", () =>
    {
        var taps = 0;
        var button = Views.Button("Tap", () => taps++);
        var branch = Views.HStack(button);
        using var original = Views.VStack(branch);
        original.RemoveAt(0);
        Throws<InvalidOperationException>(() => button.InvokeAction());
        using var second = Views.Scroll(branch);
        button.InvokeAction();
        Assert(taps == 1);
        second.Clear();
        Throws<InvalidOperationException>(() => button.InvokeAction());
        using var third = Views.VStack(branch);
        button.InvokeAction();
        Assert(taps == 2);
    }),
    ("detached container keeps new and reparented callbacks suspended", () =>
    {
        var oldTaps = 0;
        var newTaps = 0;
        var oldButton = Views.Button("Old", () => oldTaps++);
        using var original = Views.VStack(oldButton);
        original.RemoveAt(0);

        var container = Views.HStack();
        using var owner = Views.VStack(container);
        owner.RemoveAt(0);
        container.Add(oldButton);
        var newButton = Views.Button("New", () => newTaps++);
        container.Add(newButton);
        Throws<InvalidOperationException>(() => oldButton.InvokeAction());
        Throws<InvalidOperationException>(() => newButton.InvokeAction());

        using var reparented = Views.Scroll(container);
        oldButton.InvokeAction();
        newButton.InvokeAction();
        Assert(oldTaps == 1 && newTaps == 1);
    }),
    ("hosting detached root restores callbacks", () =>
    {
        var taps = 0;
        var button = Views.Button("Rehost", () => taps++);
        using var original = Views.VStack(button);
        original.RemoveAt(0);
        Throws<InvalidOperationException>(() => button.InvokeAction());
        using (var host = SwiftUIHost.CreateView(button))
        {
            Assert(host is NSView);
            button.InvokeAction();
            Assert(taps == 1);
            SwiftUIHost.DetachView(button, host);
        }
        button.Dispose();

        var attached = Views.Text("Nested");
        using var parent = Views.VStack(attached);
        Throws<InvalidOperationException>(() => SwiftUIHost.CreateView(attached));
    }),
    ("detached native callback cycle is collectable", () =>
    {
        var owner = CreateDetachedCallbackCycle();
        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
        GC.WaitForPendingFinalizers();
        GC.Collect(2, GCCollectionMode.Forced, blocking: true, compacting: true);
        Assert(!owner.IsAlive);
    }),
    ("stack validates all children before attaching", () =>
    {
        var duplicate = Views.Text("Reusable");
        Throws<InvalidOperationException>(() => Views.VStack(duplicate, duplicate));
        using var duplicatedChild = Views.VStack(duplicate);

        var attached = Views.Text("Attached");
        using var existing = Views.HStack(attached);
        var free = Views.Text("Free");
        Throws<InvalidOperationException>(() => Views.VStack(free, attached));
        using var afterFailure = Views.VStack(free);

        var freeWithNull = Views.Text("Still free");
        Throws<ArgumentNullException>(() => Views.VStack(freeWithNull, null!));
        using var afterNull = Views.VStack(freeWithNull);

        var disposed = Views.Text("Disposed");
        disposed.Dispose();
        var freeWithDisposed = Views.Text("Free after disposed");
        Throws<ObjectDisposedException>(() => Views.VStack(freeWithDisposed, disposed));
        using var afterDisposed = Views.VStack(freeWithDisposed);
    }),
    ("sheet validates identity and parentability before attaching", () =>
    {
        var same = Views.Text("Same");
        Throws<InvalidOperationException>(() => Views.Sheet(same, same));
        using var afterDuplicate = Views.VStack(same);

        var attached = Views.Text("Attached modal");
        using var existing = Views.VStack(attached);
        var content = Views.Text("Reusable content");
        Throws<InvalidOperationException>(() => Views.Sheet(content, attached));
        using var afterFailure = Views.VStack(content);
    }),
    ("navigation, scroll, sheet", () =>
    {
        var navigation = Views.Navigation("Title", Views.Scroll(
            Views.NavigationLink("Detail", Views.Text("Destination"))));
        var sheet = Views.Sheet(navigation, Views.Text("Modal"));
        Assert(sheet.Children.Count == 2 && navigation.Children.Count == 1);
        sheet.IsPresented = true;
        Assert(sheet.IsPresented);
        sheet.IsPresented = false;
        Assert(!sheet.IsPresented);
    }),
    ("toggle and slider state", () =>
    {
        var toggle = Views.Toggle("Enabled");
        toggle.IsOn = true;
        var slider = Views.Slider("Practice level", 0, 10, 5);
        slider.Value = 7.5;
        Assert(toggle.IsOn && slider.Value == 7.5 && slider.AccessibilityLabel == "Practice level");
        slider.AccessibilityLabel = "New level";
        Assert(slider.AccessibilityLabel == "New level");
        Throws<ArgumentOutOfRangeException>(() => slider.Value = 11);
        Throws<ArgumentOutOfRangeException>(() => Views.Slider("Practice level", 1, 1, 1));
        Throws<ArgumentException>(() => Views.Slider(" ", 0, 1, 0.5));
        Throws<ArgumentException>(() => slider.AccessibilityLabel = "");
    }),
    ("picker and image state", () =>
    {
        var picker = Views.Picker("Choice", ["One", "Two"], 1);
        picker.SelectedIndex = 0;
        Assert(picker.SelectedIndex == 0 && picker.Children.Count == 2);
        Assert(Views.Image("star.fill").Kind == "image");
        Throws<ArgumentOutOfRangeException>(() => picker.SelectedIndex = 2);
        Throws<ArgumentException>(() => Views.Picker("Empty", Array.Empty<string>()));
        Throws<ArgumentException>(() => Views.Image(" "));
    }),
    ("container bounds", () =>
    {
        var stack = Views.VStack(Views.Text("One"));
        stack.Spacing = 12;
        Assert(stack.Spacing == 12);
        Throws<ArgumentOutOfRangeException>(() => stack.Spacing = -1);
        Throws<ArgumentOutOfRangeException>(() => stack.RemoveAt(1));
        Throws<InvalidOperationException>(() => Views.Text("Leaf").Add(Views.Text("Other")));
    }),
    ("main-thread isolation", () =>
    {
        Task.Run(() => Throws<InvalidOperationException>(() => Views.Text("Off-thread")))
            .GetAwaiter().GetResult();
    }),
    ("AppKit hosting", () =>
    {
        using var text = Views.Text("Host");
        using (var view = SwiftUIHost.CreateView(text))
        {
            Assert(view is NSView);
            SwiftUIHost.DetachView(text, view);
        }
        using (var controller = SwiftUIHost.CreateController(text))
        {
            Assert(controller is NSViewController);
            SwiftUIHost.DetachController(text, controller);
        }
    }),
    ("hosted root cannot be moved or disposed while displayed", () =>
    {
        var taps = 0;
        var button = Views.Button("Tap", () => taps++);
        using var root = Views.VStack(button);
        using var host = SwiftUIHost.CreateView(root);
        using var window = new NSWindow(new CGRect(0, 0, 400, 200),
            NSWindowStyle.Titled, NSBackingStore.Buffered, false) { ContentView = host };
        Assert(host.Window == window);
        Throws<InvalidOperationException>(() => Views.HStack(root));
        Throws<InvalidOperationException>(() => root.Dispose());
        Throws<InvalidOperationException>(() => SwiftUIHost.CreateView(root));
        Throws<InvalidOperationException>(() => SwiftUIHost.DetachView(root, host));
        button.InvokeAction();
        Assert(taps == 1);

        root.RemoveAt(0);
        Throws<InvalidOperationException>(() => button.InvokeAction());
        root.Add(button);
        button.InvokeAction();
        Assert(taps == 2);

        window.ContentView = new NSView();
        Assert(host.Window is null);
        SwiftUIHost.DetachView(root, host);
        Throws<InvalidOperationException>(() => button.InvokeAction());
        using var newParent = Views.HStack(root);
        button.InvokeAction();
        Assert(taps == 3);
    }),
    ("host identity and controller attachment", () =>
    {
        var taps = 0;
        var root = Views.Button("Tap", () => taps++);
        var otherRoot = Views.Text("Other");
        using var host = SwiftUIHost.CreateView(root);
        using var otherHost = SwiftUIHost.CreateView(otherRoot);
        Throws<InvalidOperationException>(() => SwiftUIHost.DetachView(root, otherHost));
        Throws<InvalidOperationException>(() => SwiftUIHost.CreateController(root));
        root.InvokeAction();
        Assert(taps == 1);
        SwiftUIHost.DetachView(root, host);
        SwiftUIHost.DetachView(otherRoot, otherHost);

        using var controller = SwiftUIHost.CreateController(root);
        using var window = new NSWindow(new CGRect(0, 0, 400, 200),
            NSWindowStyle.Titled, NSBackingStore.Buffered, false) { ContentView = controller.View };
        Assert(controller.View.Window == window);
        Throws<InvalidOperationException>(() => SwiftUIHost.DetachController(root, controller));
        Throws<InvalidOperationException>(() => root.Dispose());
        window.ContentView = new NSView();
        SwiftUIHost.DetachController(root, controller);
        Throws<InvalidOperationException>(() => root.InvokeAction());
        root.Dispose();
        otherRoot.Dispose();
    }),
    ("hosted children are rejected before stack or sheet attachment", () =>
    {
        using var hosted = Views.Text("Hosted");
        using var host = SwiftUIHost.CreateView(hosted);
        var freeStackChild = Views.Text("Free stack child");
        Throws<InvalidOperationException>(() => Views.VStack(freeStackChild, hosted));
        using var stack = Views.HStack(freeStackChild);
        var freeSheetContent = Views.Text("Free sheet content");
        Throws<InvalidOperationException>(() => Views.Sheet(freeSheetContent, hosted));
        using var sheetContentOwner = Views.VStack(freeSheetContent);
        SwiftUIHost.DetachView(hosted, host);
    }),
    ("shared feature screen", () =>
    {
        using var feature = new FeatureScreen();
        Assert(feature.Root.Kind == "navigation");
        Assert(Find(feature.Root, "sample.add")?.Kind == "button");
        Assert(Find(feature.Root, "sample.picker")?.Kind == "picker");
        Assert(Find(feature.Root, "sample.slider")?.AccessibilityLabel == "Practice level");
        Assert(Find(feature.Root, "sample.list-link")?.Kind == "navigationLink");
        Assert(Find(feature.Root, "sample.sheet-content")?.Text == "A native SwiftUI sheet");
        using var host = SwiftUIHost.CreateView(feature.Root);
        Assert(host is NSView);
        SwiftUIHost.DetachView(feature.Root, host);
    }),
    ("explicit host teardown", () =>
    {
        var taps = 0;
        var button = Views.Button("Tap", () => taps++);
        var root = Views.VStack(button);
        Throws<InvalidOperationException>(() => button.Dispose());
        button.InvokeAction();
        Assert(taps == 1);
        root.Dispose();
        Throws<ObjectDisposedException>(() => button.InvokeAction());
        Throws<ObjectDisposedException>(() => root.Text = "Disposed");
        root.Dispose();
    })
};

var failed = 0;
foreach (var (name, test) in cases)
{
    try
    {
        test();
        Console.WriteLine($"PASS {name}");
    }
    catch (Exception error)
    {
        failed++;
        Console.Error.WriteLine($"FAIL {name}: {error}");
    }
}
Console.WriteLine($"Managed tests: {cases.Length - failed}/{cases.Length} passed");
return failed == 0 ? 0 : 1;

static SwiftView? Find(SwiftView view, string identifier)
{
    if (view.AccessibilityIdentifier == identifier)
        return view;
    foreach (var child in view.Children)
    {
        var match = Find(child, identifier);
        if (match is not null)
            return match;
    }
    return null;
}

static void Assert(bool condition)
{
    if (!condition)
        throw new Exception("Assertion failed.");
}

static void Throws<T>(Action action) where T : Exception
{
    try
    {
        action();
    }
    catch (T)
    {
        return;
    }
    throw new Exception($"Expected {typeof(T).Name}.");
}

[MethodImpl(MethodImplOptions.NoInlining)]
static WeakReference CreateDetachedCallbackCycle()
{
    var owner = new CallbackOwner();
    var button = Views.Button("Tap", owner.Tap);
    owner.Child = button;
    var root = Views.VStack(Views.HStack(button));
    root.RemoveAt(0);
    return new WeakReference(owner);
}

file sealed class CallbackOwner
{
    public SwiftView? Child { get; set; }
    public void Tap() { }
}
