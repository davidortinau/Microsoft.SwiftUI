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
    ("Text line limit is opt-in and leaves the full title and node intact", () =>
    {
        using var normal = Views.Text("This ordinary text still wraps freely.");
        using var title = Views.Text("An especially long learning resource title")
            .WithAccessibilityIdentifier("bridge.resource.title");
        Assert(ReferenceEquals(title.WithLineLimit(1), title));
        Assert(title.Text == "An especially long learning resource title"
            && title.AccessibilityIdentifier == "bridge.resource.title");
        title.Text = "An updated resource title with the original node";
        Assert(title.Text == "An updated resource title with the original node");
        Assert(normal.Text == "This ordinary text still wraps freely.");
        Throws<ArgumentOutOfRangeException>(() => title.WithLineLimit(0));
        Throws<ArgumentOutOfRangeException>(() => title.WithLineLimit(-1));
        using var button = Views.Button("Not text", () => { });
        using var input = Views.TextField("Not text");
        using var inline = Views.InlineText(Views.Text("One"), Views.Text("Two"));
        Throws<InvalidOperationException>(() => button.WithLineLimit(1));
        Throws<InvalidOperationException>(() => input.WithLineLimit(1));
        Throws<InvalidOperationException>(() => inline.WithLineLimit(1));
    }),
    ("inline literal text owns two styled runs and rejects non-text children", () =>
    {
        var target = Views.Text("강남 *[district]*")
            .WithTypography(17, 700, 1.29, "Manrope-Bold")
            .WithForegroundColor("#0F172A", "#F0F9FF");
        var native = Views.Text("  Gangnam (district)\nnear the river")
            .WithTypography(17, 400, 1.29, "Manrope-Regular")
            .WithForegroundColor("#475569", "#BAE6FD");
        using var inline = Views.InlineText(target, native)
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("bridge.inline.vocabulary");
        Assert(inline.Kind == "inlineText"
            && inline.Children.SequenceEqual([target, native])
            && target.Text == "강남 *[district]*"
            && native.Text == "  Gangnam (district)\nnear the river");
        target.Text = "강남";
        native.Text = "";
        target.WithTypography(21.25, 700, 1.29, "Manrope-Bold");
        native.WithForegroundColor("#475569", "#BAE6FD");
        Assert(target.Text == "강남" && native.Text == ""
            && inline.Children[0] == target && inline.Children[1] == native);
        Throws<InvalidOperationException>(() => Views.InlineText(target, Views.Text("Other")));
        Throws<ArgumentException>(() => Views.InlineText(
            Views.Text("Valid"), Views.Image("xmark")));
        Throws<ArgumentNullException>(() =>
            Views.InlineText(null!, Views.Text("Valid")));
        var repeated = Views.Text("Once");
        Throws<InvalidOperationException>(() => Views.InlineText(repeated, repeated));
        using var hosted = SwiftUIHost.CreateView(inline);
        SwiftUIHost.DetachView(inline, hosted);
        var disposed = Views.Text("No longer valid");
        disposed.Dispose();
        Throws<ObjectDisposedException>(() => Views.InlineText(
            Views.Text("Valid"), disposed));
    }),
    ("source footer divider and indeterminate progress are real distinct nodes", () =>
    {
        using var footer = Views.VStack(
            Views.Divider().WithAccessibilityIdentifier("bridge.footer.divider"),
            Views.IndeterminateProgress("Loading learning resources")
                .WithAccessibilityIdentifier("bridge.resources.spinner"),
            Views.Progress(1, 4, 3, "One of four"));
        Assert(footer.Children.Select(child => child.Kind)
            .SequenceEqual(["divider", "indeterminateProgress", "progress"]));
        Assert(footer.Children[1].AccessibilityIdentifier == "bridge.resources.spinner");
        Throws<ArgumentException>(() => Views.IndeterminateProgress(""));
        using var host = SwiftUIHost.CreateView(footer);
        SwiftUIHost.DetachView(footer, host);
    }),
    ("horizontal grid validates columns and retains row identity on removal", () =>
    {
        var changed = "";
        var removed = 0;
        SwiftView Header() => Views.HStack(
            Views.Text("Target"), Views.Text("Native"), Views.Text("Type"),
            Views.Text("Tags"), Views.Text("Remove"));
        SwiftView Row(string id) => Views.HStack(
                Views.TextField("Target", onChanged: text => changed = text)
                    .WithAccessibilityIdentifier($"bridge.grid.target.{id}"),
                Views.Text("Native"),
                Views.Picker("Type", ["Word", "Phrase", "Sentence"], 0, _ => { }),
                Views.Text("Tags"),
                Views.Button("Remove", () => removed++)
                    .WithAccessibilityIdentifier($"bridge.grid.remove.{id}"))
            .WithAccessibilityIdentifier($"bridge.grid.row.{id}");
        var header = Header().WithAccessibilityIdentifier("bridge.grid.header");
        var first = Row("first");
        var second = Row("second");
        using var grid = Views.HorizontalGrid([0, 0, 120, 0, 0], header, first, second)
            .WithAccessibilityIdentifier("bridge.grid");
        grid.Spacing = 8;
        Assert(grid.Kind == "horizontalGrid" && grid.Children.Count == 3);
        Assert(grid.Children[0] == header && grid.Children[2] == second);
        Throws<InvalidOperationException>(() => first.RemoveAt(0));
        Throws<InvalidOperationException>(() => second.Add(Views.Text("Extra")));
        Throws<InvalidOperationException>(() => header.Clear());
        Throws<InvalidOperationException>(() => grid.RemoveAt(0));
        Throws<ArgumentException>(() => grid.Add(Views.HStack(Views.Text("Short"))));

        first.Children[4].InvokeAction();
        grid.RemoveAt(1);
        first.Dispose();
        Assert(grid.Children.Count == 2 && grid.Children[1] == second && removed == 1);
        second.Children[0].Text = "Retained input";
        Assert(second.Children[0].Text == "Retained input");
        second.Children[4].InvokeAction();
        Assert(removed == 2 && changed == "");

        Throws<ArgumentNullException>(() => Views.HorizontalGrid(null!, Header()));
        Throws<ArgumentException>(() => Views.HorizontalGrid([], Header()));
        Throws<ArgumentOutOfRangeException>(() =>
            Views.HorizontalGrid([0, double.NaN, 120, 0, 0], Header()));
        Throws<ArgumentOutOfRangeException>(() =>
            Views.HorizontalGrid([0, -1, 120, 0, 0], Header()));
        Throws<ArgumentOutOfRangeException>(() =>
            Views.HorizontalGrid([0, double.PositiveInfinity, 120, 0, 0], Header()));
        Throws<ArgumentException>(() =>
            Views.HorizontalGrid([0, 120], Views.HStack(Views.Text("One"))));
        Throws<ArgumentException>(() =>
            Views.HorizontalGrid([0, 120], Views.HStack(Views.Text("A"), Views.Text("B")),
                                 Views.HStack(Views.Text("Short"))));
        using var hosted = SwiftUIHost.CreateView(grid);
        SwiftUIHost.DetachView(grid, hosted);
    }),
    ("composed native menu retains its label and exact selected action", () =>
    {
        var selectedIndex = 0;
        var selectedText = Views.Text("Video");
        SwiftView? menu = null;
        var video = Views.Button("Video", () => { }).WithAccessibilitySelected();
        SwiftView? audio = null;
        audio = Views.Button("Audio", () =>
        {
            selectedIndex = 1;
            selectedText.Text = "Audio";
            menu!.Text = "Audio";
            video.WithAccessibilitySelected(false);
            audio!.WithAccessibilitySelected();
        });
        var label = Views.HStack(selectedText.WithFlexibleWidth(),
                Views.Image("chevron.down"))
            .WithFlexibleWidth();
        using (menu = Views.Menu(label, video, audio!)
            .WithAccessibilityIdentifier("bridge.menu.media")
            .WithAccessibilityLabel("Media type"))
        {
            menu.Text = "Video";
            Assert(menu.Kind == "menu" &&
                menu.Children.SequenceEqual([label, video, audio!]) &&
                menu.AccessibilityIdentifier == "bridge.menu.media");
            audio.InvokeAction();
            Assert(selectedIndex == 1 && selectedText.Text == "Audio" &&
                menu.Text == "Audio" && menu.Children[1] == video);
            using var host = SwiftUIHost.CreateView(menu);
            SwiftUIHost.DetachView(menu, host);
        }
        using var oldMenu = Views.Menu("More", Views.Button("Existing", () => { }));
        Assert(oldMenu.Text == "More" && oldMenu.Children.Count == 1 &&
               oldMenu.Children[0].Kind == "button");
        Throws<ArgumentNullException>(() =>
            Views.Menu((SwiftView)null!, Views.Button("Option", () => { })));
        Throws<ArgumentException>(() => Views.Menu(Views.Text("No options")));
        Throws<ArgumentException>(() => Views.Menu(
            Views.Button("Invalid label", () => { }), Views.Button("Option", () => { })));
        Throws<ArgumentException>(() => Views.Menu(Views.Text("Label"), Views.Text("Not an action")));
    }),
    ("photo bytes decode without symbols or answer-bearing metadata", () =>
    {
        var png = Convert.FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQ7LgLAAIkAXfC8r3XAAAAAElFTkSuQmCC");
        using var thumbnail = Views.ImageFromBytes(png, "Photo hint");
        Assert(thumbnail.Kind == "photo" &&
            thumbnail.PhotoLoadState == SwiftPhotoLoadState.Loading);
        using var zoom = Views.ZoomablePhoto(png, "Photo hint");
        Assert(zoom.Kind == "zoomPhoto" &&
            zoom.PhotoLoadState == SwiftPhotoLoadState.Loading);
        var errors = new List<string>();
        using var failed = Views.ImageFromBytes([0, 1, 2], "Photo hint",
            onFailed: errors.Add);
        Assert(failed.PhotoLoadState == SwiftPhotoLoadState.Failed &&
            errors.SequenceEqual(["decodeFailed"]));
        Throws<ArgumentOutOfRangeException>(() =>
            Views.ImageFromBytes(png, "Photo hint", maxHeight: 0));
        Throws<ArgumentOutOfRangeException>(() =>
            Views.ImageFromBytes(new byte[8 * 1024 * 1024 + 1], "Photo hint"));
        Throws<ArgumentException>(() => Views.ZoomablePhoto(png, " "));
        Throws<InvalidOperationException>(() =>
        {
            _ = Views.Text("Not a photo").PhotoLoadState;
        });
    }),
    ("sheet detent and fullscreen photo retain independent presentation", () =>
    {
        var png = Convert.FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQ7LgLAAIkAXfC8r3XAAAAAElFTkSuQmCC");
        var sheet = Views.Sheet(Views.Text("Quiz"), Views.Scroll(Views.Text("Details")))
            .WithSheetDetentFraction(0.7);
        var cover = Views.FullScreenPhotoCover(sheet,
            Views.ZoomablePhoto(png, "Photo hint"),
            Views.Button("Close", () => { }).WithAccessibilityIdentifier("bridge.photo.close"),
            () => { });
        using var root = Views.VStack(cover);
        sheet.IsPresented = true;
        cover.IsPresented = true;
        Assert(sheet.IsPresented && cover.IsPresented &&
            cover.Children[0] == sheet &&
            cover.Children[1].Kind == "zoomPhoto" &&
            cover.Children[2].Kind == "button");
        sheet.IsPresented = false;
        cover.IsPresented = false;
        Throws<ArgumentOutOfRangeException>(() => sheet.WithSheetDetentFraction(0));
        Throws<ArgumentOutOfRangeException>(() => sheet.WithSheetDetentFraction(1.1));
        Throws<InvalidOperationException>(() => root.WithSheetDetentFraction(.7));
        Throws<ArgumentException>(() => Views.FullScreenPhotoCover(
            Views.Text("Quiz"), Views.Image("photo"), Views.Button("Close", () => { }),
            () => { }));
        using var host = SwiftUIHost.CreateView(root);
        SwiftUIHost.DetachView(root, host);
    }),
    ("focused input submit and scoped Quick Add keys share one text field", () =>
    {
        var input = Views.TextField("Find vocabulary")
            .WithAccessibilityIdentifier("bridge.quick.field")
            .OnSubmit(() => { })
            .OnKeyPress(key => key == SwiftTextKey.Enter);
        var form = Views.Form(Views.Section("Words", input));
        var popup = Views.QuickAddSuggestions(form, "bridge.quick.field",
            Views.VStack(Views.Button("Existing word", () => { })
                .WithAccessibilitySelected()),
            () => { });
        using var root = Views.VStack(popup);
        popup.IsPresented = true;
        Assert(popup.IsPresented && ReferenceEquals(input, form.Children[0].Children[0]));
        input.FocusRequested = true;
        Assert(input.FocusRequested);
        popup.IsPresented = false;
        Throws<InvalidOperationException>(() => Views.Text("Wrong").OnSubmit(() => { }));
        Throws<InvalidOperationException>(() => Views.Text("Wrong").OnKeyPress(_ => true));
        Throws<InvalidOperationException>(() => Views.Text("Wrong").WithAccessibilitySelected());
        Throws<ArgumentNullException>(() => input.OnKeyPress(null!));
        Throws<ArgumentNullException>(() => input.OnSubmit(null!));
        Throws<ArgumentException>(() => Views.QuickAddSuggestions(
            Views.Form(Views.Text("No input")), "missing",
            Views.Button("Suggestion", () => { })));
        using var host = SwiftUIHost.CreateView(root);
        SwiftUIHost.DetachView(root, host);
    }),
    ("busy starter and centered resource confirmation are owned by scene root", () =>
    {
        var busy = Views.StarterBlockingOverlay(Views.Text("Resources"),
                "Creating starter resource")
            .WithAccessibilityIdentifier("bridge.starter");
        var cancelled = 0;
        var deletes = 0;
        using var dialog = Views.ResourceDeleteConfirmation(busy,
                "Delete resource?", "Cannot be undone", "Close", "Cancel", "Delete",
                () => cancelled++, () => deletes++)
            .WithAccessibilityIdentifier("bridge.delete");
        busy.IsPresented = true;
        dialog.IsPresented = true;
        dialog.DeletePending = true;
        Assert(ReferenceEquals(dialog.WithTransparentDeleteBackdrop(), dialog));
        Assert(ReferenceEquals(dialog.WithTransparentDeleteBackdrop(false), dialog));
        Assert(busy.IsPresented && dialog.IsPresented && dialog.DeletePending &&
            dialog.Children.Single() == busy && cancelled == 0 && deletes == 0);
        dialog.DeletePending = false;
        dialog.IsPresented = false;
        busy.IsPresented = false;
        Throws<InvalidOperationException>(() => busy.DeletePending = true);
        Throws<InvalidOperationException>(() => busy.WithTransparentDeleteBackdrop());
        Throws<ArgumentException>(() => Views.StarterBlockingOverlay(
            Views.Text("Content"), " "));
        Throws<ArgumentNullException>(() => Views.ResourceDeleteConfirmation(
            Views.Text("Content"), "Delete", "Warning", "Close", "Cancel", "Delete",
            null!, () => { }));
        using var host = SwiftUIHost.CreateView(dialog);
        SwiftUIHost.DetachView(dialog, host);
    }),
    ("completed card opacity and text strikethrough preserve button action", () =>
    {
        var taps = 0;
        var title = Views.Text("Completed Quiz").WithStrikethrough();
        var card = Views.Button(Views.VStack(title), () => taps++)
            .WithOpacity(0.75).WithAccessibilityIdentifier("bridge.completed");
        using var root = Views.VStack(card);
        using var host = SwiftUIHost.CreateView(root);
        Assert(title.Kind == "text" && card.Kind == "button");
        card.InvokeAction();
        title.WithStrikethrough(false).WithStrikethrough();
        Assert(taps == 1 && card.AccessibilityIdentifier == "bridge.completed");
        Throws<InvalidOperationException>(() => card.WithStrikethrough());
        Throws<ArgumentOutOfRangeException>(() => card.WithOpacity(double.NaN));
        Throws<ArgumentOutOfRangeException>(() => card.WithOpacity(-0.1));
        Throws<ArgumentOutOfRangeException>(() => card.WithOpacity(1.1));
        SwiftUIHost.DetachView(root, host);
    }),
    ("source typography uses validated source metrics and optional font face", () =>
    {
        using var title = Views.Text("Source 24px").WithTypography(24, 700, 1.17);
        title.WithTypography(17, 400, 1.29, "Manrope-Regular");
        title.WithFont(SwiftFontStyle.Body).WithTypography(24, 700, 1.17);
        Throws<ArgumentOutOfRangeException>(() => title.WithTypography(0, 700, 1.17));
        Throws<ArgumentOutOfRangeException>(() => title.WithTypography(24, 650, 1.17));
        Throws<ArgumentOutOfRangeException>(() => title.WithTypography(24, 700, double.NaN));
        Throws<ArgumentException>(() => title.WithTypography(24, 700, 1.17, " "));
    }),
    ("mounted scheme and adaptive palettes reject malformed colors", () =>
    {
        using var root = Views.VStack(Views.Text("Color").WithForegroundColor("#0B0D12", "#F8FAFF"))
            .WithPreferredColorScheme(SwiftColorScheme.Dark)
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithTintColor("#1E4DFF", "#6B8CFF");
        Assert(root.PreferredColorScheme == SwiftColorScheme.Dark);
        using var host = SwiftUIHost.CreateView(root);
        root.PreferredColorScheme = SwiftColorScheme.Light;
        Assert(root.PreferredColorScheme == SwiftColorScheme.Light);
        SwiftUIHost.DetachView(root, host);
        Throws<ArgumentOutOfRangeException>(() => root.PreferredColorScheme = (SwiftColorScheme)10);
        Throws<ArgumentException>(() => root.WithBackgroundColor("#F7F8FF", "#12345Z"));
        Throws<ArgumentException>(() => root.WithTintColor("#123", "#6B8CFF"));
    }),
    ("source width padding rounded surface stroke and shadow", () =>
    {
        using var card = Views.VStack(Views.Text("Card"))
            .WithPadding(12, 16, 12, 16)
            .WithFlexibleWidth(440, SwiftHorizontalAlignment.Center)
            .WithRoundedSurface("#EEF1FF", "#121B33", 16, "#D6DAF0", "#263457", 1)
            .WithShadow("#000000", "#000000", 15, 0.15, 4);
        using var action = Views.Button("Insight", () => { })
            .WithButtonStyle(SwiftButtonStyle.Plain);
        Throws<ArgumentOutOfRangeException>(() =>
            card.WithFlexibleWidth(double.PositiveInfinity));
        Throws<ArgumentOutOfRangeException>(() =>
            card.WithFlexibleWidth(null, (SwiftHorizontalAlignment)8));
        Throws<ArgumentOutOfRangeException>(() => card.WithPadding(0, double.NaN, 0, 0));
        Throws<ArgumentException>(() =>
            card.WithRoundedSurface("#FFFFFF", "#000000", 16, "#FF00FF", null, 1));
        Throws<ArgumentException>(() =>
            card.WithRoundedSurface("#FFFFFF", "#000000", 16, borderWidth: 1));
        Throws<ArgumentOutOfRangeException>(() =>
            card.WithShadow("#000000", "#000000", 15, 1.1));
        using var plain = Views.Text("No surface");
        Throws<InvalidOperationException>(() =>
            plain.WithShadow("#000000", "#000000", 15, 0.15));
        using var host = SwiftUIHost.CreateView(card);
        SwiftUIHost.DetachView(card, host);
    }),
    ("source button shadow offsets require an appearance and retain surface ABI", () =>
    {
        var signature = typeof(SwiftView).GetMethod(nameof(SwiftView.WithShadow),
            [typeof(string), typeof(string), typeof(double), typeof(double), typeof(double)]);
        Assert(signature is not null && signature.GetParameters()[4].HasDefaultValue &&
               Equals(signature.GetParameters()[4].DefaultValue, 0d));

        var taps = 0;
        var source = Views.Button("Brite", () => taps++)
            .WithButtonAppearance("#A2E436", "#A2E436", "#000000", "#000000", 4);
        source.AccessibilityIdentifier = "bridge.button.shadow";
        Assert(ReferenceEquals(source.WithShadow("#000000", "#000000", 0, 1, 3)
            .WithButtonShadowOffsetX(3), source));
        var offsetFirst = Views.Button("Before shadow", () => { })
            .WithButtonAppearance(null, null, "#000000", "#000000", 25)
            .WithButtonShadowOffsetX(-2.5)
            .WithShadow("#000000", "#000000", 0, 1, 3);
        var oldSurface = Views.Button("Old surface", () => { })
            .WithRoundedSurface("#FFFFFF", "#212529", 4)
            .WithShadow("#000000", "#000000", 0, 1, 3);
        using var root = Views.VStack(source, offsetFirst, oldSurface);
        using var host = SwiftUIHost.CreateView(root);
        Assert(root.Children[0] == source &&
               source.AccessibilityIdentifier == "bridge.button.shadow");
        source.WithButtonShadowOffsetX(0).WithButtonShadowOffsetX(3);
        source.WithShadow("#000000", "#000000", 0, 1, 3);
        source.IsEnabled = false;
        source.InvokeAction();
        Assert(taps == 0);
        source.IsEnabled = true;
        source.InvokeAction();
        Assert(taps == 1);
        SwiftUIHost.DetachView(root, host);

        using var plain = Views.Button("No appearance", () => { });
        Throws<InvalidOperationException>(() => plain.WithButtonShadowOffsetX(3));
        Throws<InvalidOperationException>(() =>
            plain.WithShadow("#000000", "#000000", 0, 1, 3));
        Throws<InvalidOperationException>(() => oldSurface.WithButtonShadowOffsetX(3));
        Throws<InvalidOperationException>(() => Views.Text("Wrong kind")
            .WithButtonShadowOffsetX(3));
        foreach (var invalid in new[] { double.NaN, double.PositiveInfinity, double.NegativeInfinity })
            Throws<ArgumentOutOfRangeException>(() => source.WithButtonShadowOffsetX(invalid));
        root.Dispose();
        Throws<ObjectDisposedException>(() => source.WithButtonShadowOffsetX(3));
        Throws<ObjectDisposedException>(() => source.WithShadow("#000000", "#000000", 0, 1, 3));
    }),
    ("opt-in button appearance validates palette, radius and disabled opacity", () =>
    {
        var taps = 0;
        var button = Views.Button(
                Views.HStack(Views.Image("eye"), Views.Text("Show"))
                    .WithPadding(10, 14, 10, 14).WithMinimumHeight(44),
                () => taps++)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 6)
            .WithButtonBorderWidth(2)
            .WithMinimumHeight(44);
        using var owner = Views.VStack(button);
        Assert(owner.Children.Single() == button && button.Children.Single().Kind == "hstack");
        button.IsEnabled = false;
        button.InvokeAction();
        Assert(taps == 0);
        button.IsEnabled = true;
        button.InvokeAction();
        Assert(taps == 1);
        using var host = SwiftUIHost.CreateView(owner);
        button.WithButtonAppearance("#F8F9FA", "#121B33", "#D6DAF0", "#263457", 25)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 2.4, 1)
            .WithButtonBorderWidth(1)
            .WithButtonBorderWidth(2);
        using var widthFirst = Views.Button("Width first", () => { })
            .WithButtonBorderWidth(2)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 6);
        Assert(ReferenceEquals(widthFirst.WithButtonBorderWidth(1), widthFirst));
        SwiftUIHost.DetachView(owner, host);
        Throws<InvalidOperationException>(() => Views.Text("Not a button")
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 6));
        Throws<InvalidOperationException>(() =>
            Views.Text("Not a button").WithButtonBorderWidth(2));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonBorderWidth(0));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonBorderWidth(-1));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonBorderWidth(double.NaN));
        Throws<ArgumentOutOfRangeException>(() =>
            button.WithButtonBorderWidth(double.PositiveInfinity));
        Throws<ArgumentOutOfRangeException>(() =>
            button.WithButtonBorderWidth(double.NegativeInfinity));
        Throws<ArgumentException>(() => button.WithButtonAppearance(
            null, "#121B33", "#6B7888", "#93A3C7", 6));
        Throws<ArgumentException>(() => button.WithButtonAppearance(
            "#F8F9FA", "#BAD", "#6B7888", "#93A3C7", 6));
        Throws<ArgumentException>(() => button.WithButtonAppearance(
            null, null, "#BAD", "#93A3C7", 6));
        Throws<ArgumentException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#12345Z", 6));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#93A3C7", 0));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#93A3C7", double.NaN));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#93A3C7", 6, -0.01));
        Throws<ArgumentOutOfRangeException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#93A3C7", 6, double.PositiveInfinity));
        owner.Dispose();
        Throws<ObjectDisposedException>(() => button.WithButtonAppearance(
            null, null, "#6B7888", "#93A3C7", 6));
        Throws<ObjectDisposedException>(() => button.WithButtonBorderWidth(2));
    }),
    ("Button-only circular appearance keeps actual actions and rejects unsafe sizes", () =>
    {
        var audioTaps = 0;
        var infoTaps = 0;
        var audio = Views.Button(Views.Image("speaker.wave.2"), () => audioTaps++)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 22)
            .WithButtonCircle(44)
            .WithAccessibilityLabel("Play audio")
            .WithAccessibilityIdentifier("bridge.quiz.play-prompt");
        var info = Views.Button(Views.Image("info.circle"), () => infoTaps++)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 22)
            .WithButtonCircle(44)
            .WithAccessibilityLabel("Word learning details")
            .WithAccessibilityIdentifier("bridge.quiz.details");
        using var root = Views.HStack(audio, info);
        Assert(audio.Kind == "button" && info.Kind == "button"
            && audio.Children.Single().Kind == "image"
            && info.Children.Single().Kind == "image"
            && audio.AccessibilityIdentifier == "bridge.quiz.play-prompt"
            && info.AccessibilityIdentifier == "bridge.quiz.details"
            && ReferenceEquals(audio.WithButtonCircle(44), audio));
        using var host = SwiftUIHost.CreateView(root);
        audio.InvokeAction();
        info.IsEnabled = false;
        info.InvokeAction();
        Assert(audioTaps == 1 && infoTaps == 0);
        info.IsEnabled = true;
        info.InvokeAction();
        Assert(infoTaps == 1);
        foreach (var invalid in new[] {
            0d, -1d, double.NaN, double.PositiveInfinity, double.NegativeInfinity
        })
            Throws<ArgumentOutOfRangeException>(() => audio.WithButtonCircle(invalid));
        Throws<InvalidOperationException>(() => audio.WithMinimumHeight(45));
        Assert(ReferenceEquals(audio.WithMinimumHeight(44), audio));
        SwiftUIHost.DetachView(root, host);
        using var ordinary = Views.Button("Unstyled", () => { });
        Throws<InvalidOperationException>(() => ordinary.WithButtonCircle(44));
        Throws<InvalidOperationException>(() => Views.Text("Wrong kind")
            .WithButtonCircle(44));
        using var tooTall = Views.Button("Tall", () => { })
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 22)
            .WithMinimumHeight(45);
        Throws<InvalidOperationException>(() => tooTall.WithButtonCircle(44));
        root.Dispose();
        Throws<ObjectDisposedException>(() => audio.WithButtonCircle(44));
    }),
    ("opt-in SF Symbol size preserves button actions without scaling other text", () =>
    {
        var taps = 0;
        var icon = Views.Image("speaker.wave.2").WithFixedSymbolSize(14);
        var button = Views.Button(icon, () => taps++)
            .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 22)
            .WithButtonCircle(44)
            .WithAccessibilityLabel("Play audio");
        using var host = SwiftUIHost.CreateView(button);
        Assert(icon.Kind == "image" && ReferenceEquals(icon.WithFixedSymbolSize(21), icon));
        button.IsEnabled = false;
        button.InvokeAction();
        Assert(taps == 0);
        button.IsEnabled = true;
        button.InvokeAction();
        Assert(taps == 1);
        foreach (var invalid in new[] {
            0d, -1d, double.NaN, double.PositiveInfinity, double.NegativeInfinity
        })
            Throws<ArgumentOutOfRangeException>(() => icon.WithFixedSymbolSize(invalid));
        Throws<InvalidOperationException>(() => Views.Text("Prompt")
            .WithFixedSymbolSize(14));
        Throws<InvalidOperationException>(() => button.WithFixedSymbolSize(14));
        SwiftUIHost.DetachView(button, host);
        button.Dispose();
        Throws<ObjectDisposedException>(() => icon.WithFixedSymbolSize(14));
    }),
    ("paired clear button border keeps the original ABI and mounted action", () =>
    {
        var signature = typeof(SwiftView).GetMethod(nameof(SwiftView.WithButtonAppearance),
            [typeof(string), typeof(string), typeof(string), typeof(string),
             typeof(double), typeof(double)]);
        Assert(signature is not null && signature.GetParameters()[5].HasDefaultValue &&
               Equals(signature.GetParameters()[5].DefaultValue, 0.65d));
        var taps = 0;
        var label = Views.HStack(Views.Image("arrow.left.square"),
                Views.Text("Logout").WithUnderline(false))
            .WithPadding(6, 16, 6, 16).WithMinimumHeight(44);
        label.Spacing = 4;
        var clear = Views.Button(label, () => taps++)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonBorderWidth(2)
            .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
            .WithButtonAppearance(null, null, null, null, 25)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("bridge.clear.link");
        using var root = Views.VStack(clear);
        using var host = SwiftUIHost.CreateView(root);
        Assert(root.Children.Single() == clear &&
               clear.AccessibilityIdentifier == "bridge.clear.link");
        Throws<ArgumentException>(() =>
            clear.WithButtonAppearance(null, null, null, "#000000", 25));
        Throws<ArgumentException>(() =>
            clear.WithButtonAppearance(null, null, "#000000", null, 25));
        Throws<ArgumentException>(() =>
            clear.WithButtonAppearance(null, null, "", "", 25));
        Throws<ArgumentException>(() =>
            clear.WithButtonAppearance(null, null, "#123", "#000000", 25));
        clear.IsEnabled = false;
        clear.InvokeAction();
        Assert(taps == 0);
        clear.IsEnabled = true;
        clear.InvokeAction();
        Assert(taps == 1);
        Assert(ReferenceEquals(clear.WithButtonAppearance(null, null, null, null, 25),
                               clear));
        clear.WithButtonAppearance(null, null, "#000000", "#FFFFFF", 25)
            .WithButtonAppearance(null, null, null, null, 25);
        SwiftUIHost.DetachView(root, host);
        root.Dispose();
        Throws<ObjectDisposedException>(() =>
            clear.WithButtonAppearance(null, null, null, null, 25));
    }),
    ("button group limits overlap and wrap to ordered real Buttons", () =>
    {
        var taps = new List<int>();
        var first = Views.Button("First", () => taps.Add(0))
            .WithAccessibilityIdentifier("bridge.group.first");
        var second = Views.Button("Second", () => taps.Add(1))
            .WithAccessibilityIdentifier("bridge.group.second");
        var group = Views.ButtonGroup([first, second], wraps: true, selectedIndex: 0)
            .WithAccessibilityIdentifier("bridge.group");
        Assert(group.Kind == "buttonGroup" && group.SelectedIndex == 0 &&
               ReferenceEquals(group.Children[0], first) &&
               ReferenceEquals(group.Children[1], second));
        using var root = Views.VStack(group);
        using var host = SwiftUIHost.CreateView(root);
        group.SelectedIndex = 1;
        Assert(group.SelectedIndex == 1);
        group.SelectedIndex = -1;
        Assert(group.SelectedIndex == -1);
        second.IsEnabled = false;
        second.InvokeAction();
        first.InvokeAction();
        Assert(taps.SequenceEqual([0]));
        second.IsEnabled = true;
        second.InvokeAction();
        Assert(taps.SequenceEqual([0, 1]));
        Assert(ReferenceEquals(group.Children[0], first) &&
               ReferenceEquals(group.Children[1], second));
        Throws<ArgumentOutOfRangeException>(() => group.SelectedIndex = -2);
        Throws<ArgumentOutOfRangeException>(() => group.SelectedIndex = 2);
        Throws<InvalidOperationException>(() => group.Spacing = -2);
        Throws<InvalidOperationException>(() => group.Add(Views.Button("Third", () => { })));
        Throws<InvalidOperationException>(() => group.Clear());
        Throws<ArgumentException>(() => Views.ButtonGroup([]));
        Throws<ArgumentException>(() => Views.ButtonGroup([Views.Text("Not a Button")]));
        Throws<InvalidOperationException>(() => Views.ButtonGroup([first]));
        Throws<ArgumentNullException>(() => Views.ButtonGroup(null!));
        SwiftUIHost.DetachView(root, host);
        root.Dispose();
        Throws<ObjectDisposedException>(() => group.SelectedIndex = 0);
        using var oldStack = Views.HStack(Views.Text("Old spacing"));
        Throws<ArgumentOutOfRangeException>(() => oldStack.Spacing = -2);
    }),
    ("group-only layout modifier keeps legacy ABI and original Button identity", () =>
    {
        var factory = typeof(Views).GetMethod(nameof(Views.ButtonGroup),
            [typeof(SwiftView[]), typeof(bool), typeof(int?)]);
        Assert(factory is not null &&
               factory.GetParameters()[1].HasDefaultValue &&
               Equals(factory.GetParameters()[1].DefaultValue, false) &&
               factory.GetParameters()[2].HasDefaultValue &&
               factory.GetParameters()[2].DefaultValue is null);
        var modifier = typeof(SwiftView).GetMethod(nameof(SwiftView.WithButtonGroupLayout),
            [typeof(double), typeof(bool)]);
        Assert(modifier is not null && modifier.GetParameters()[1].HasDefaultValue &&
               Equals(modifier.GetParameters()[1].DefaultValue, false));

        var taps = new List<int>();
        var first = Views.Button("First", () => taps.Add(0))
            .WithAccessibilityIdentifier("bridge.group.original.first")
            .WithMinimumHeight(44);
        var second = Views.Button("Second", () => taps.Add(1))
            .WithAccessibilityIdentifier("bridge.group.original.second")
            .WithMinimumHeight(44);
        var group = Views.ButtonGroup([first, second])
            .WithAccessibilityIdentifier("bridge.group.original");
        Assert(group.SelectedIndex == -1 && group.Children.Count == 2 &&
               ReferenceEquals(group.WithButtonGroupLayout(1, fillAvailableWidth: true), group));
        using var root = Views.VStack(group);
        using var host = SwiftUIHost.CreateView(root);
        group.WithButtonGroupLayout(0).WithButtonGroupLayout(2);
        group.SelectedIndex = 0;
        group.SelectedIndex = 1;
        group.SelectedIndex = -1;
        first.InvokeAction();
        second.InvokeAction();
        Assert(taps.SequenceEqual([0, 1]) &&
               group.Children[0] == first && group.Children[1] == second &&
               first.AccessibilityIdentifier == "bridge.group.original.first" &&
               second.AccessibilityIdentifier == "bridge.group.original.second");
        foreach (var invalid in new[] {
            -1, double.NaN, double.PositiveInfinity, double.NegativeInfinity
        })
            Throws<ArgumentOutOfRangeException>(() => group.WithButtonGroupLayout(invalid));
        Throws<InvalidOperationException>(() =>
            Views.Button("Not a group", () => { }).WithButtonGroupLayout(1));
        Throws<InvalidOperationException>(() =>
            Views.HStack(Views.Text("Not a group")).WithButtonGroupLayout(1));
        Throws<InvalidOperationException>(() => group.Spacing = -1);
        using var stack = Views.HStack(Views.Text("Unchanged spacing"));
        Throws<ArgumentOutOfRangeException>(() => stack.Spacing = -1);
        SwiftUIHost.DetachView(root, host);
        root.Dispose();
        Throws<ObjectDisposedException>(() => group.WithButtonGroupLayout(1));
    }),
    ("elliptical button corners validate eight axes and preserve mounted identity", () =>
    {
        var taps = 0;
        var axes = new double[] { 255, 25, 25, 225, 225, 25, 25, 255 };
        static SwiftView Apply(SwiftView button, double[] radii) =>
            button.WithButtonEllipticalCornerRadii(
                radii[0], radii[1], radii[2], radii[3],
                radii[4], radii[5], radii[6], radii[7]);

        using var noAppearance = Apply(Views.Button("Plain", () => { }), axes)
            .WithButtonStyle(SwiftButtonStyle.Plain);
        var button = Views.Button("Sketchy", () => taps++)
            .WithButtonAppearance(null, null, "#28A745", "#28A745", 15)
            .WithButtonBorderWidth(2)
            .WithMinimumHeight(44);
        var beforeAppearance = Apply(Views.Button("Order", () => { }), axes)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#28A745", "#28A745", 15);
        using var root = Views.VStack(noAppearance, button, beforeAppearance);
        Assert(ReferenceEquals(Apply(button, axes), button));
        using var host = SwiftUIHost.CreateView(root);
        Assert(ReferenceEquals(root.Children[1], button) &&
               ReferenceEquals(root.Children[2], beforeAppearance));
        Assert(ReferenceEquals(Apply(button, new double[8]), button));
        Assert(ReferenceEquals(Apply(button, axes), button));
        button.IsEnabled = false;
        button.InvokeAction();
        Assert(taps == 0);
        button.IsEnabled = true;
        button.InvokeAction();
        Assert(taps == 1);
        foreach (var invalid in new[] { -1, double.NaN, double.PositiveInfinity, double.NegativeInfinity })
        {
            for (var axis = 0; axis < axes.Length; axis++)
            {
                var rejected = (double[])axes.Clone();
                rejected[axis] = invalid;
                Throws<ArgumentOutOfRangeException>(() => Apply(button, rejected));
            }
        }
        SwiftUIHost.DetachView(root, host);
        Throws<InvalidOperationException>(() =>
            Apply(Views.Text("Not a button"), axes));
        root.Dispose();
        Throws<ObjectDisposedException>(() => Apply(button, axes));
    }),
    ("fixed native Circle and Text-only underline keep node identity", () =>
    {
        var selected = Views.Circle(8, "#2C3E50", "#6B8CFF")
            .WithAccessibilityLabel("Step 3 of 6")
            .WithAccessibilityIdentifier("bridge.selected.step");
        var muted = Views.Circle(8, "#A0A0A0", "#5B6580");
        var dots = Views.HStack(selected, muted);
        dots.Spacing = 4;
        var text = Views.Text("Logout").WithUnderline();
        using var root = Views.VStack(dots, Views.Button(
            Views.HStack(Views.Image("arrow.left"), text).WithMinimumHeight(44), () => { }));
        Assert(selected.Kind == "circle" && muted.Kind == "circle" &&
            dots.Children[0] == selected && text.Kind == "text");
        using var host = SwiftUIHost.CreateView(root);
        text.WithUnderline(false).WithUnderline();
        selected.WithForegroundColor("#445566", "#778899");
        SwiftUIHost.DetachView(root, host);
        Throws<ArgumentOutOfRangeException>(() => Views.Circle(0, "#2C3E50", "#6B8CFF"));
        Throws<ArgumentOutOfRangeException>(() => Views.Circle(double.NaN, "#2C3E50", "#6B8CFF"));
        Throws<ArgumentException>(() => Views.Circle(8, "#BAD", "#6B8CFF"));
        Throws<ArgumentException>(() => Views.Circle(8, "#2C3E50", "#BAD"));
        Throws<InvalidOperationException>(() => selected.WithUnderline());
        root.Dispose();
        Throws<ObjectDisposedException>(() => text.WithUnderline());
    }),
    ("real progress has safe zero total and mutable fraction", () =>
    {
        using var progress = Views.Progress(1, 3, 8, "Today's progress")
            .WithTintColor("#1E4DFF", "#6B8CFF")
            .WithProgressTrackColor("#EEF1FF", "#121B33");
        Assert(progress.Kind == "progress" && progress.Value == 1 && progress.ProgressTotal == 3);
        progress.Value = 2;
        progress.ProgressTotal = 4;
        Assert(progress.Value == 2 && progress.ProgressTotal == 4);
        Throws<ArgumentOutOfRangeException>(() => progress.ProgressTotal = 1);
        Throws<ArgumentOutOfRangeException>(() => progress.Value = 5);
        Throws<ArgumentOutOfRangeException>(() => Views.Progress(1, 0, 8, "Progress"));
        Throws<ArgumentOutOfRangeException>(() => Views.Progress(0, 1, 0, "Progress"));
        using var empty = Views.Progress(0, 0, 4, "No activities");
        Assert(empty.Value == 0 && empty.ProgressTotal == 0);
        using var host = SwiftUIHost.CreateView(progress);
        SwiftUIHost.DetachView(progress, host);
    }),
    ("bottom inset and adaptive viewport preserve child ownership", () =>
    {
        var field = Views.TextField("Answer");
        var scroll = Views.Scroll(field).OnViewportChanged((_, _) => { });
        var footer = Views.HStack(Views.Text("1/3")).WithAdaptiveStack(430);
        using var inset = Views.BottomInset(scroll, footer);
        Assert(inset.Children[0] == scroll && inset.Children[1] == footer
            && scroll.Children[0] == field);
        Throws<InvalidOperationException>(() => Views.VStack(field));
        Throws<ArgumentException>(() => Views.BottomInset(Views.Text("Not scroll"), Views.Text("Footer")));
        using var grid = Views.LazyVGrid(1, Views.Text("One"));
        grid.GridColumns = 2;
        Assert(grid.GridColumns == 2);
        Throws<ArgumentOutOfRangeException>(() => grid.GridColumns = 0);
        Throws<InvalidOperationException>(() => grid.WithAdaptiveStack(430));
        Throws<ArgumentOutOfRangeException>(() => footer.WithAdaptiveStack(-1));
        using var host = SwiftUIHost.CreateView(inset);
        SwiftUIHost.DetachView(inset, host);
    }),
    ("source List and Form colors are explicit and validated", () =>
    {
        using var form = Views.Form(Views.Section("Basic", Views.TextField("Title")))
            .WithNativeListColors("#F7F8FF", "#060913", "#EEF1FF", "#121B33");
        using var list = Views.List(Views.Text("Row"))
            .WithNativeListColors("#F7F8FF", "#060913", "#EEF1FF", "#121B33");
        Assert(form.Kind == "form" && list.Kind == "list"
            && form.Children.Single().Kind == "section");
        Throws<InvalidOperationException>(() => Views.VStack().WithNativeListColors(
            "#F7F8FF", "#060913", "#EEF1FF", "#121B33"));
        Throws<ArgumentException>(() => form.WithNativeListColors(
            "#F7F8FF", "#BAD", "#EEF1FF", "#121B33"));
        using var host = SwiftUIHost.CreateView(form);
        SwiftUIHost.DetachView(form, host);
    }),
    ("inline title and short Scroll centering require their proper nodes", () =>
    {
        using var root = Views.Scroll(Views.Text("Brand")).WithCenterWhenShort();
        root.WithCenterWhenShort(false).WithCenterWhenShort();
        using var title = Views.VStack(Views.Text("Content"))
            .WithNavigationTitle("Resources").WithInlineNavigationTitle();
        title.WithNavigationTitle("Resources updated").WithInlineNavigationTitle(false)
            .WithInlineNavigationTitle();
        Throws<InvalidOperationException>(() => Views.Text("Untitled").WithInlineNavigationTitle());
        Throws<InvalidOperationException>(() => Views.Text("Not a Scroll").WithCenterWhenShort());
        using var host = SwiftUIHost.CreateView(root);
        SwiftUIHost.DetachView(root, host);
    }),
    ("bottom scroll anchor is opt-in and requires a Scroll", () =>
    {
        using var root = Views.Scroll(Views.Text("First"), Views.Text("Newest"))
            .WithScrollAnchoredToBottom();
        root.WithScrollAnchoredToBottom(false).WithScrollAnchoredToBottom()
            .WithCenterWhenShort();
        Throws<InvalidOperationException>(() => Views.VStack().WithScrollAnchoredToBottom());
        using var host = SwiftUIHost.CreateView(root);
        SwiftUIHost.DetachView(root, host);
    }),
    ("real secure text and editor fields accept paired prompt colors", () =>
    {
        using var secure = Views.SecureField("Password")
            .WithPlaceholderColor("#7A8699", "#93A3C7");
        using var textField = Views.TextField("Email")
            .WithPlaceholderColor("#7A8699", "#93A3C7");
        using var editor = Views.TextEditor()
            .WithTextEditorPlaceholder("Write a sentence")
            .WithPlaceholderColor("#7A8699", "#93A3C7");
        Assert(secure.Kind == "secureField" && textField.Kind == "textField"
            && editor.Kind == "textEditor" && editor.Text == "");
        Assert(ReferenceEquals(editor.WithTextEditorScrollBackgroundHidden(), editor));
        Assert(ReferenceEquals(editor.WithTextEditorScrollBackgroundHidden(false), editor));
        editor.Text = "A target-language sentence.";
        editor.Text = "";
        editor.WithTextEditorPlaceholder("");
        Throws<ArgumentNullException>(() => editor.WithTextEditorPlaceholder(null!));
        Throws<InvalidOperationException>(() =>
            textField.WithTextEditorPlaceholder("Not an editor"));
        Throws<InvalidOperationException>(() =>
            textField.WithTextEditorScrollBackgroundHidden());
        Throws<InvalidOperationException>(() =>
            secure.WithTextEditorScrollBackgroundHidden());
        using var notInput = Views.Text("Not an input");
        Throws<InvalidOperationException>(() =>
            notInput.WithPlaceholderColor("#7A8699", "#93A3C7"));
        Throws<ArgumentException>(() => secure.WithPlaceholderColor("#7A8699", "#BAD"));
        using var host = SwiftUIHost.CreateView(secure);
        SwiftUIHost.DetachView(secure, host);
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
    ("SwiftUI forms with secure input and valued pickers", () =>
    {
        var password = Views.SecureField("Password", "secret", _ => { })
            .WithAccessibilityIdentifier("bridge.password");
        var language = Views.Picker("Target language",
            [new SwiftPickerOption("en", "English"), new SwiftPickerOption("ko", "Korean")],
            "en", _ => { }).WithPickerStyle(SwiftPickerStyle.Menu);
        using var form = Views.Form(Views.Section("Sign in", password, language))
            .WithNavigationTitle("Account");
        Assert(password.Text == "secret" && language.SelectedValue == "en");
        language.SelectedValue = "ko";
        Assert(language.SelectedValue == "ko" && form.Children.Count == 1);
        password.Text = "updated";
        Assert(password.Text == "updated");
        Throws<ArgumentOutOfRangeException>(() => language.SelectedValue = "fr");
        using var host = SwiftUIHost.CreateView(form);
        Assert(host is NSView);
        SwiftUIHost.DetachView(form, host);
    }),
    ("independent SwiftUI tabs and programmatic path", () =>
    {
        var dashboard = Views.NavigationStack(Views.Form(Views.Text("Dashboard")));
        var resources = Views.NavigationStack(Views.List(Views.Text("Resources")));
        using var tabs = Views.TabView(1, _ => { },
            Views.Tab("Home", "house", dashboard),
            Views.Tab("Resources", "books.vertical", resources));
        Assert(tabs.SelectedIndex == 1);
        tabs.SelectedIndex = 0;
        dashboard.Push("quiz", Views.Form(Views.SecureField("Answer")));
        resources.Push("edit", Views.Form(Views.TextField("Title")));
        Assert(dashboard.NavigationPath.SequenceEqual(["quiz"]));
        Assert(resources.NavigationPath.SequenceEqual(["edit"]));
        Throws<ArgumentException>(() => dashboard.Push("quiz", Views.Text("Duplicate")));
        dashboard.Pop();
        Assert(dashboard.NavigationPath.Count == 0 && resources.NavigationPath.Count == 1);
        Throws<InvalidOperationException>(() => dashboard.Pop());
        using var host = SwiftUIHost.CreateView(tabs);
        Assert(host is NSView);
        SwiftUIHost.DetachView(tabs, host);
    }),
    ("SwiftUI menus, dialogs, grid, importer and modifiers", () =>
    {
        var called = 0;
        var list = Views.Searchable(Views.List(Views.Text("Result")), "Find", onChanged: _ => { });
        var grid = Views.LazyVGrid(2, Views.Text("One"), Views.Text("Two"));
        var menu = Views.Menu("More", Views.Button("Action", () => called++));
        var toolbar = Views.Toolbar(Views.VStack(list, grid), menu);
        var alert = Views.Alert(toolbar, "Delete?", "Cannot be undone",
            Views.Button("Cancel", () => called++));
        var importer = Views.FileImporter(alert, _ => { }, _ => { });
        using var dialog = Views.ConfirmationDialog(importer, "Choose",
            Views.Button("Confirm", () => called++));
        dialog.IsPresented = true;
        importer.IsPresented = true;
        alert.IsPresented = true;
        Assert(dialog.IsPresented && importer.IsPresented && alert.IsPresented);
        var button = menu.Children[0];
        button.InvokeAction();
        Assert(called == 1);
        button.WithButtonStyle(SwiftButtonStyle.Bordered);
        grid.WithPadding(16).WithMinimumHeight(44).WithForegroundColor("#234567")
            .WithBackgroundColor("#ABCDEF").OnEscape(() => { });
        Throws<ArgumentException>(() => grid.WithForegroundColor("red"));
        using var host = SwiftUIHost.CreateView(dialog);
        Assert(host is NSView);
        SwiftUIHost.DetachView(dialog, host);
    }),
    ("disabled actions and composite SwiftUI buttons", () =>
    {
        var taps = 0;
        var label = Views.VStack(
            Views.Image("book"),
            Views.Text("Resource"),
            Views.Text("Updated today")).WithPadding(12);
        var button = Views.Button(label, () => taps++)
            .WithAccessibilityLabel("Open resource");
        using var root = Views.List(button);
        Assert(button.Children.Single() == label && button.IsEnabled);
        button.IsEnabled = false;
        button.InvokeAction();
        Assert(taps == 0);
        button.IsEnabled = true;
        button.InvokeAction();
        Assert(taps == 1);
        Throws<InvalidOperationException>(() => Views.Button(label, () => { }));
        using var host = SwiftUIHost.CreateView(root);
        SwiftUIHost.DetachView(root, host);
    }),
    ("navigation locks Back and updates destination title", () =>
    {
        using var stack = Views.NavigationStack(Views.Text("Root"));
        var detail = Views.List(Views.Text("Destination"))
            .WithNavigationTitle("Before").WithTabBarHidden();
        stack.Push("detail", detail);
        Assert(stack.CanNavigateBack);
        stack.CanNavigateBack = false;
        Throws<InvalidOperationException>(() => stack.Pop());
        Assert(stack.NavigationPath.SequenceEqual(["detail"]));
        detail.WithNavigationTitle("After");
        Assert(stack.NavigationPath.SequenceEqual(["detail"]));
        stack.CanNavigateBack = true;
        stack.Pop();
        Assert(stack.NavigationPath.Count == 0);
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
