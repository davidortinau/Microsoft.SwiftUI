using Microsoft.SwiftUI;
using Views = Microsoft.SwiftUI.SwiftUI;

namespace Microsoft.SwiftUI.AppMainProbe.iOS;

public static class Program
{
    public static void Main()
    {
        SwiftView? accountStack = null;
        SwiftView? resourceStack = null;
        var selection = Views.Text("Selected: English").WithAccessibilityIdentifier("probe.language.value");
        var back = Views.Text("Root").WithAccessibilityIdentifier("probe.navigation.path");
        var entered = Views.Text("Password empty");
        var appeared = Views.Text("Appear: waiting");
        var scene = Views.Text("Scene: Unknown");
        var submission = Views.Text("Submit idle");
        var submit = Views.Button("Continue", () => submission.Text = "Submitted");
        submit.IsEnabled = false;

        var account = Views.Form(
            Views.Section("Sign in",
                Views.TextField("Email").WithAccessibilityIdentifier("probe.email"),
                Views.SecureField("Password", onChanged: value =>
                {
                    entered.Text = value.Length > 0 ? "Password entered" : "Password empty";
                    submit.IsEnabled = value.Length > 0;
                })
                    .WithAccessibilityIdentifier("probe.password"),
                entered, submit, submission,
                Views.Picker("Language",
                    [new SwiftPickerOption("en", "English"), new SwiftPickerOption("ko", "Korean")],
                    "en", value => selection.Text = value == "ko"
                        ? "Selected: Korean" : "Selected: English")
                    .WithPickerStyle(SwiftPickerStyle.Menu)
                    .WithAccessibilityIdentifier("probe.language"),
                selection, appeared, scene),
            Views.Section("Navigation",
                Views.Button("Open detail", () =>
                {
                    var detailText = Views.Text("Detail from managed C#")
                        .WithAccessibilityIdentifier("probe.detail");
                    var locked = Views.Text("Back unlocked");
                    SwiftView? detail = null;
                    detail = Views.List(
                        detailText,
                        Views.Button("Refresh detail", () =>
                        {
                            detailText.Text = "Detail refreshed in C#";
                            detail!.WithNavigationTitle("Detail refreshed");
                        }),
                        Views.Button("Lock Back", () =>
                        {
                            accountStack!.CanNavigateBack = false;
                            locked.Text = "Back locked";
                        }),
                        Views.Button("Unlock Back", () =>
                        {
                            accountStack!.CanNavigateBack = true;
                            locked.Text = "Back unlocked";
                        }),
                        locked,
                        Views.Button("Back", () => accountStack!.Pop())
                            .WithAccessibilityIdentifier("probe.back"))
                        .WithNavigationTitle("Detail").WithTabBarHidden();
                    accountStack!.Push("detail", detail);
                })
                    .WithAccessibilityIdentifier("probe.open.detail"),
                back))
            .WithNavigationTitle("Account");
        accountStack = Views.NavigationStack(account,
            path => back.Text = path.Count == 0 ? "Returned to root" : string.Join("/", path));

        var importStatus = Views.Text("Import idle");
        SwiftView? importer = null;
        SwiftView? tabs = null;
        SwiftView? sceneRoot = null;
        var resources = Views.List(
            Views.Text("Resources in SwiftUI List").WithAccessibilityIdentifier("probe.resources"),
            Views.Button("Open four-screen bridge", () => resourceStack!.Push(
                "four-screen-bridge", BuildFourScreenBridgeProbe(sceneRoot!)))
                .WithAccessibilityIdentifier("probe.p16.open"),
            Views.Button("Open horizontal grid", () => resourceStack!.Push(
                "horizontal-grid", BuildHorizontalGridProbe()))
                .WithAccessibilityIdentifier("probe.p18.open"),
            Views.Button("Open composed menu selects", () => resourceStack!.Push(
                "composed-menu-selects", BuildComposedMenuProbe()))
                .WithAccessibilityIdentifier("probe.p19.open"),
            Views.Button("Open styling probe", () => resourceStack!.Push(
                "style", BuildStyleProbe(tabs!)))
                .WithAccessibilityIdentifier("probe.open.style"),
            Views.Button("Open style correction", () => resourceStack!.Push(
                "style-correction", BuildStyleCorrectionMenu(tabs!, resourceStack!)))
                .WithAccessibilityIdentifier("probe.v8.open"),
            Views.Button("Open source appearance", () => resourceStack!.Push(
                "appearance", BuildAppearanceProbe(tabs!)))
                .WithAccessibilityIdentifier("probe.v9.open"),
            Views.Button("Open border width probe", () =>
            {
                tabs!.PreferredColorScheme = SwiftColorScheme.Light;
                resourceStack!.Push("border-width", BuildBorderWidthProbe());
            }).WithAccessibilityIdentifier("probe.v10.open"),
            Views.Button("Open elliptical button probe", () =>
            {
                tabs!.PreferredColorScheme = SwiftColorScheme.Light;
                resourceStack!.Push("ellipse-composite", BuildEllipseCompositeProbe(tabs!));
            }).WithAccessibilityIdentifier("probe.v11.open"),
            Views.Button("Open button shadow probe", () =>
            {
                tabs!.PreferredColorScheme = SwiftColorScheme.Light;
                resourceStack!.Push("button-shadow", BuildButtonShadowProbe(tabs!));
            }).WithAccessibilityIdentifier("probe.v12.open"),
            Views.Button("Open clear border and button groups", () =>
            {
                tabs!.PreferredColorScheme = SwiftColorScheme.Light;
                resourceStack!.Push("button-groups", BuildButtonGroupProbe(tabs!));
            }).WithAccessibilityIdentifier("probe.v13.open"),
            Views.Button("Choose file", () => importer!.IsPresented = true),
            importStatus,
            Views.Button("Open resource", () => resourceStack!.Push("resource",
                Views.Form(Views.Section("Resource", Views.Text("Source detail")
                    .WithAccessibilityIdentifier("probe.resource.detail")))
                    .WithNavigationTitle("Resource")))
                .WithAccessibilityIdentifier("probe.resource.open"),
            Views.Button(
                Views.VStack(
                    Views.Image("books.vertical"),
                    Views.Text("Resource card title"),
                    Views.Text("Resource card date"))
                    .WithPadding(12)
                    .WithBackgroundColor("#EEEEEE"),
                () => resourceStack!.Push("card",
                    Views.List(Views.Text("Card detail"))
                        .WithNavigationTitle("Resource card")))
                .WithAccessibilityLabel("Open resource card")
                .WithAccessibilityIdentifier("probe.resource.card"))
            .WithNavigationTitle("Resources");
        importer = Views.FileImporter(resources,
            _ => importStatus.Text = "File imported",
            error => importStatus.Text = $"File error: {error}",
            () => importStatus.Text = "Import cancelled");
        resourceStack = Views.NavigationStack(importer);

        tabs = Views.TabView(
            Views.Tab("Account", "person", accountStack),
            Views.Tab("Resources", "books.vertical", resourceStack))
            .WithAccessibilityIdentifier("probe.tabs")
            .WithPreferredColorScheme(SwiftColorScheme.Dark)
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithForegroundColor("#0B0D12", "#F8FAFF")
            .WithTintColor("#1E4DFF", "#6B8CFF")
            .OnAppear(() => appeared.Text = "Appear: yes");

        sceneRoot = Views.StarterBlockingOverlay(tabs, "Creating starter resource")
            .WithAccessibilityIdentifier("probe.p16.starter");
        SwiftUIApplication.Run(sceneRoot,
            phase => scene.Text = $"Scene: {phase}");
    }

    private static SwiftView BuildStyleProbe(SwiftView root)
    {
        var scheme = Views.Text("Scheme: Dark")
            .WithAccessibilityIdentifier("probe.style.scheme");
        var viewport = Views.Text("Viewport: waiting")
            .WithAccessibilityIdentifier("probe.style.viewport");
        var cardTaps = 0;
        var cardCount = Views.Text("Card taps: 0");
        var card = Views.Button(
                Views.VStack(
                    Views.Text("Source type: 24pt 700 1.17")
                        .WithTypography(24, 700, 1.17),
                    Views.Text("Source body: 15pt 400 1.33")
                        .WithTypography(15, 400, 1.33)
                        .WithForegroundColor("#394150", "#C6D0E7"),
                    cardCount)
                    .WithPadding(24, 16, 24, 16)
                    .WithFlexibleWidth()
                    .WithRoundedSurface("#EEF1FF", "#121B33", 16,
                                        "#D6DAF0", "#263457", 1)
                    .WithShadow("#000000", "#000000", 15, 0.15, 4),
                () => cardCount.Text = $"Card taps: {++cardTaps}")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithFlexibleWidth(440, SwiftHorizontalAlignment.Center)
            .WithAccessibilityIdentifier("probe.style.card");

        var progressStatus = Views.Text("Progress: 1 of 3");
        var progress = Views.Progress(1, 3, 8, "Today's progress")
            .WithTintColor("#1E4DFF", "#6B8CFF")
            .WithProgressTrackColor("#EEF1FF", "#121B33")
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.style.progress");
        var thinProgress = Views.Progress(1, 3, 4, "Plan progress")
            .WithTintColor("#1E4DFF", "#6B8CFF")
            .WithProgressTrackColor("#EEF1FF", "#121B33")
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.style.progress.thin");

        var resourceGrid = Views.LazyVGrid(1,
                Views.Text("Resource one").WithAccessibilityIdentifier("probe.style.resource.one"),
                Views.Text("Resource two").WithAccessibilityIdentifier("probe.style.resource.two"))
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.style.resources.grid");
        var dashboardGrid = Views.LazyVGrid(2,
                Views.Text("Study").WithAccessibilityIdentifier("probe.style.tile.one"),
                Views.Text("Practice").WithAccessibilityIdentifier("probe.style.tile.two"),
                Views.Text("Review").WithAccessibilityIdentifier("probe.style.tile.three"))
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.style.dashboard.grid");

        var filters = Views.HStack(
                Views.Button("Filter One", () => { })
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.style.filter.one"),
                Views.Button("Filter Two", () => { })
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.style.filter.two"))
            .WithAdaptiveStack(430)
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.style.filters");
        var inputStatus = Views.Text("Input: empty")
            .WithAccessibilityIdentifier("probe.style.input.status");
        var scroll = Views.Scroll(
                Views.Button("Toggle Scheme", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme
                        == SwiftColorScheme.Dark ? SwiftColorScheme.Light : SwiftColorScheme.Dark;
                    scheme.Text = $"Scheme: {root.PreferredColorScheme}";
                }).WithAccessibilityIdentifier("probe.style.toggle.scheme"),
                scheme, viewport, card, progressStatus, progress, thinProgress,
                Views.Button("Advance Progress", () =>
                {
                    progress.Value = 2;
                    thinProgress.Value = 2;
                    progressStatus.Text = "Progress: 2 of 3";
                }).WithAccessibilityIdentifier("probe.style.advance"),
                filters, resourceGrid, dashboardGrid,
                Views.TextField("Style input", onChanged: value =>
                        inputStatus.Text = $"Input: {value}")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.style.input"),
                Views.Text("Scroll bottom marker")
                    .WithAccessibilityIdentifier("probe.style.bottom"))
            .WithPadding(12)
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithForegroundColor("#0B0D12", "#F8FAFF")
            .OnViewportChanged((width, size) =>
            {
                var wide = width >= 768;
                resourceGrid.GridColumns = wide ? 2 : 1;
                dashboardGrid.GridColumns = wide ? 3 : 2;
                viewport.Text = $"Viewport: {(int)Math.Round(width)} size {size} " +
                    $"resources {resourceGrid.GridColumns} tiles {dashboardGrid.GridColumns}";
            });
        scroll.Spacing = 16;

        var footerStatus = Views.Text("Footer idle");
        var footerActions = Views.HStack(
                Views.Text("1 / 3").WithAccessibilityIdentifier("probe.style.footer.count"),
                Views.Button("Footer action", () => footerStatus.Text = "Footer activated")
                    .WithAccessibilityIdentifier("probe.style.footer.action"),
                footerStatus)
            .WithAdaptiveStack(300);
        var footer = Views.VStack(footerActions, inputStatus)
            .WithPadding(12, 16, 12, 16)
            .WithFlexibleWidth()
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithForegroundColor("#0B0D12", "#F8FAFF")
            .WithAccessibilityIdentifier("probe.style.footer");
        return Views.BottomInset(scroll, footer)
            .WithNavigationTitle("Style from C#")
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.style.screen");
    }

    private static SwiftView BuildStyleCorrectionMenu(SwiftView root, SwiftView stack)
    {
        var menu = Views.Scroll(
            Views.Button("Form palette", () => stack.Push("style-form", BuildStyleForm(root)))
                .WithAccessibilityIdentifier("probe.v8.open.form"),
            Views.Button("List palette", () => stack.Push("style-list", BuildStyleList()))
                .WithAccessibilityIdentifier("probe.v8.open.list"),
            Views.Button("Button targets", () => stack.Push("style-buttons", BuildStyleButtons()))
                .WithAccessibilityIdentifier("probe.v8.open.buttons"),
            Views.Button("Centered sign in", () => stack.Push("style-center", BuildCenteredSignIn()))
                .WithAccessibilityIdentifier("probe.v8.open.center"))
            .WithPadding(16)
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithNavigationTitle("Style contracts")
            .WithInlineNavigationTitle()
            .WithTabBarHidden();
        menu.Spacing = 20;
        return menu;
    }

    private static SwiftView BuildStyleForm(SwiftView root)
    {
        var scheme = Views.Text("Mode: Dark")
            .WithAccessibilityIdentifier("probe.v8.form.mode");
        var inputStatus = Views.Text("Secure input empty")
            .WithAccessibilityIdentifier("probe.v8.form.secure.status");
        var form = Views.Form(
            Views.Section("",
                Views.Text("Basic Information")
                    .WithAccessibilityIdentifier("probe.v8.form.heading"),
                Views.TextField("Email")
                    .WithPlaceholderColor("#7A8699", "#93A3C7")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.form.email"),
                Views.SecureField("Password", onChanged: value =>
                    inputStatus.Text = value.Length > 0
                        ? "Secure input entered" : "Secure input empty")
                    .WithPlaceholderColor("#7A8699", "#93A3C7")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.form.password"),
                inputStatus),
            Views.Section("",
                Views.Button("Change appearance", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme
                        == SwiftColorScheme.Dark ? SwiftColorScheme.Light : SwiftColorScheme.Dark;
                    scheme.Text = $"Mode: {root.PreferredColorScheme}";
                }).WithAccessibilityIdentifier("probe.v8.form.theme"),
                scheme))
            .WithNativeListColors("#F7F8FF", "#060913", "#EEF1FF", "#121B33")
            .WithNavigationTitle("Source Form")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v8.form");
        return form;
    }

    private static SwiftView BuildStyleList()
    {
        return Views.List(
                Views.Section("Resources",
                    Views.Text("First resource")
                        .WithAccessibilityIdentifier("probe.v8.list.first"),
                    Views.Text("Second resource")
                        .WithAccessibilityIdentifier("probe.v8.list.second")),
                Views.Text("Third resource")
                    .WithAccessibilityIdentifier("probe.v8.list.third"))
            .WithNativeListColors("#F7F8FF", "#060913", "#EEF1FF", "#121B33")
            .WithNavigationTitle("Source List")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v8.list");
    }

    private static SwiftView BuildStyleButtons()
    {
        var status = Views.Text("No action")
            .WithAccessibilityIdentifier("probe.v8.buttons.status");
        var actions = Views.Scroll(
                status,
                Views.Button("Next", () => status.Text = "Next tapped")
                    .WithButtonStyle(SwiftButtonStyle.BorderedProminent)
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.next"),
                Views.Button("Done", () => status.Text = "Done tapped")
                    .WithButtonStyle(SwiftButtonStyle.Bordered)
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.done"),
                Views.Button(Views.HStack(
                    Views.Image("eye"), Views.Text("Show password")),
                    () => status.Text = "Visibility tapped")
                    .WithButtonStyle(SwiftButtonStyle.Plain)
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.visibility"))
            .WithPadding(16)
            .WithNavigationTitle("Source Actions")
            .WithInlineNavigationTitle()
            .WithTabBarHidden();
        actions.Spacing = 16;
        return actions;
    }

    private static SwiftView BuildCenteredSignIn()
    {
        var status = Views.Text("Password empty")
            .WithAccessibilityIdentifier("probe.v8.center.status");
        var card = Views.VStack(
                Views.Text("SentenceStudio")
                    .WithTypography(24, 700, 1.17)
                    .WithAccessibilityIdentifier("probe.v8.center.brand"),
                Views.Text("Sign In").WithTypography(22, 600, 1.27),
                Views.Text("Email"),
                Views.TextField("Email")
                    .WithPlaceholderColor("#7A8699", "#93A3C7")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.center.email"),
                Views.Text("Password"),
                Views.SecureField("Password", onChanged: value =>
                    status.Text = value.Length > 0 ? "Password entered" : "Password empty")
                    .WithPlaceholderColor("#7A8699", "#93A3C7")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.center.password"),
                status,
                Views.Toggle("Remember me"),
                Views.Button("Sign In", () => status.Text = "No account action")
                    .WithButtonStyle(SwiftButtonStyle.BorderedProminent)
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.v8.center.submit"),
                Views.Text("Forgot password"),
                Views.Text("Create account").WithAccessibilityIdentifier("probe.v8.center.bottom"))
            .WithPadding(24)
            .WithFlexibleWidth(440, SwiftHorizontalAlignment.Center)
            .WithRoundedSurface("#EEF1FF", "#121B33", 16)
            .WithAccessibilityIdentifier("probe.v8.center.card");
        card.Spacing = 12;
        var scroll = Views.Scroll(card)
            .WithCenterWhenShort()
            .WithPadding(16)
            .WithForegroundColor("#0B0D12", "#F8FAFF")
            .WithBackgroundColor("#F7F8FF", "#060913")
            .WithNavigationTitle("Source Sign In")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v8.center.scroll");
        return scroll;
    }

    private static SwiftView BuildAppearanceProbe(SwiftView root)
    {
        var status = Views.Text("No action").WithAccessibilityIdentifier("probe.v9.status");
        var scheme = Views.Text("Mode: Dark").WithAccessibilityIdentifier("probe.v9.mode");

        var dots = Views.HStack(Enumerable.Range(0, 6).Select(index =>
        {
            var selected = index == 2;
            var dot = Views.Circle(8, selected ? "#2C3E50" : "#A0A0A0",
                selected ? "#6B8CFF" : "#5B6580");
            if (selected)
                dot.WithAccessibilityLabel("Step 3 of 6")
                    .WithAccessibilityIdentifier("probe.v9.step");
            return dot;
        }).ToArray())
            .WithFlexibleWidth(alignment: SwiftHorizontalAlignment.Center)
            .WithAccessibilityIdentifier("probe.v9.dots");
        dots.Spacing = 4;

        var linkText = Views.Text("Logout").WithUnderline();
        var linkLabel = Views.HStack(
                Views.Image("rectangle.portrait.and.arrow.right"), linkText)
            .WithForegroundColor("#6B7888", "#93A3C7")
            .WithPadding(6, 16, 6, 16)
            .WithMinimumHeight(44)
            .WithFlexibleWidth(alignment: SwiftHorizontalAlignment.Center);
        linkLabel.Spacing = 4;
        var logout = Views.Button(linkLabel, () => status.Text = "Logout tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithMinimumHeight(44)
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.v9.logout");

        SwiftView Filled(string title, string id, double radius, string light, string dark)
        {
            return Views.Button(Views.Text(title)
                    .WithForegroundColor("#FFFFFF", "#FFFFFF")
                    .WithPadding(10, 20, 10, 20)
                    .WithMinimumHeight(44),
                    () => status.Text = $"{title} tapped")
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance(light, dark, light, dark, radius)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);
        }

        var radius6 = Filled("Radius six", "probe.v9.radius.6", 6,
            "#2C3E50", "#6B8CFF");
        var radius25 = Filled("Radius twenty-five", "probe.v9.radius.25", 25,
            "#2C3E50", "#6B8CFF");
        var radius2Point4 = Filled("Radius two point four", "probe.v9.radius.2.4", 2.4,
            "#2C3E50", "#6B8CFF");

        var tertiary = Views.Button(
                Views.Text("Retry").WithForegroundColor("#0B0D12", "#F8FAFF")
                    .WithPadding(10, 20, 10, 20).WithMinimumHeight(44),
                () => status.Text = "Retry tapped")
            .WithButtonAppearance("#F8F9FA", "#121B33", "#D6DAF0", "#263457", 6)
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("probe.v9.tertiary");

        SwiftView Outline(string id)
        {
            var label = Views.HStack(Views.Image("eye"), Views.Text("Show"))
                .WithForegroundColor("#6B7888", "#93A3C7")
                .WithPadding(10, 20, 10, 20).WithMinimumHeight(44);
            label.Spacing = 4;
            return Views.Button(label, () => status.Text = $"{id} tapped")
                .WithButtonAppearance(null, null, "#6B7888", "#93A3C7", 6)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);
        }

        var bodyOutline = Outline("probe.v9.outline.body");
        var cardOutline = Outline("probe.v9.outline.card");
        var whiteSurface = Views.VStack(bodyOutline)
            .WithBackgroundColor("#FFFFFF", "#060913").WithPadding(12);
        var cardSurface = Views.VStack(cardOutline)
            .WithBackgroundColor("#EEF1FF", "#121B33").WithPadding(12);

        var disabled = Filled("Disabled primary", "probe.v9.disabled", 6,
            "#2C3E50", "#6B8CFF");
        disabled.IsEnabled = false;
        var parentDisabled = Views.VStack(
            Filled("Parent disabled", "probe.v9.parent.disabled", 6,
                "#2C3E50", "#6B8CFF"));
        parentDisabled.IsEnabled = false;

        var scroll = Views.Scroll(
                status,
                Views.Button("Toggle Scheme", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme == SwiftColorScheme.Dark
                        ? SwiftColorScheme.Light : SwiftColorScheme.Dark;
                    scheme.Text = $"Mode: {root.PreferredColorScheme}";
                }).WithAccessibilityIdentifier("probe.v9.theme"),
                scheme,
                dots,
                logout,
                Views.Button("Toggle underline", () =>
                {
                    linkText.WithUnderline(false);
                    status.Text = "Underline off";
                }).WithAccessibilityIdentifier("probe.v9.underline.off"),
                radius6, radius25, radius2Point4, tertiary,
                whiteSurface, cardSurface, disabled, parentDisabled)
            .WithPadding(12)
            .WithForegroundColor("#0B0D12", "#F8FAFF")
            .WithBackgroundColor("#FFFFFF", "#060913")
            .WithNavigationTitle("Source appearance")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v9.screen");
        scroll.Spacing = 12;
        return scroll;
    }

    private static SwiftView BuildBorderWidthProbe()
    {
        var status = Views.Text("No action").WithAccessibilityIdentifier("probe.v10.status");
        SwiftView Outline(string text, string id, Action onTap) =>
            Views.Button(
                    Views.Text(text)
                        .WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#FFFFFF", "#FFFFFF")
                        .WithPadding(4, 16, 4, 16)
                        .WithMinimumHeight(44),
                    onTap)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);

        var source = Outline("Vapor Override", "probe.v10.vapor.override",
                () => status.Text = "Override tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8)
            .WithButtonBorderWidth(2);
        var unchangedDefault = Outline("Default width", "probe.v10.default",
                () => status.Text = "Default tapped")
            .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8)
            .WithButtonStyle(SwiftButtonStyle.Plain);
        var mutable = Outline("Mutable width", "probe.v10.mutable",
                () => status.Text = "Mutable tapped")
            .WithButtonBorderWidth(2)
            .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8)
            .WithButtonStyle(SwiftButtonStyle.Plain);
        var thick = true;
        var directDisabled = Outline("Direct disabled", "probe.v10.disabled",
                () => status.Text = "Disabled invoked")
            .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8)
            .WithButtonBorderWidth(2);
        directDisabled.IsEnabled = false;
        var parentDisabled = Views.VStack(
            Outline("Parent disabled", "probe.v10.parent.disabled",
                    () => status.Text = "Parent invoked")
                .WithButtonBorderWidth(2)
                .WithButtonAppearance(null, null, "#3CF281", "#12B886", 0.8));
        parentDisabled.IsEnabled = false;

        var scroll = Views.Scroll(
                Views.Text("Vapor Light · source button border"),
                status, source, unchangedDefault, mutable,
                Views.Button("Toggle mutable stroke", () =>
                {
                    thick = !thick;
                    mutable.WithButtonBorderWidth(thick ? 2 : 1);
                    status.Text = thick ? "Stroke two" : "Stroke one";
                }).WithAccessibilityIdentifier("probe.v10.toggle"),
                directDisabled, parentDisabled)
            .WithPadding(16)
            .WithBackgroundColor("#1A0933", "#170229")
            .WithNavigationTitle("Button border width")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v10.screen");
        scroll.Spacing = 12;
        return scroll;
    }

    private static SwiftView BuildEllipseCompositeProbe(SwiftView root)
    {
        var status = Views.Text("No action").WithAccessibilityIdentifier("probe.v11.status");
        SwiftView Sketchy(string text, string id) =>
            Views.Button(
                    Views.Text(text)
                        .WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#28A745", "#12B886")
                        .WithPadding(4, 16, 4, 16)
                        .WithMinimumHeight(44),
                    () => status.Text = $"{id} tapped")
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance(null, null, "#28A745", "#12B886", 15)
                .WithButtonBorderWidth(2)
                .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);

        SwiftView Brite(string text, string id, string border) =>
            Views.Button(
                    Views.Text(text)
                        .WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#000000", "#000000")
                        .WithPadding(6, 16, 6, 16)
                        .WithMinimumHeight(44),
                    () => status.Text = $"{id} tapped")
                .WithButtonAppearance("#A2E436", "#A2E436", border, border, 4)
                .WithButtonBorderWidth(2)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);

        var source = Sketchy("Override", "probe.v11.sketchy.source");
        var longSource = Sketchy("Override this example with more text", "probe.v11.sketchy.long");
        var mutable = Sketchy("Mutable", "probe.v11.sketchy.mutable");
        var roundedDefault = Views.Button(
                Views.Text("Old caller").WithPadding(4, 16, 4, 16).WithMinimumHeight(44),
                () => status.Text = "Old caller tapped")
            .WithButtonAppearance(null, null, "#28A745", "#12B886", 15)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("probe.v11.rounded.default");
        var directDisabled = Sketchy("Disabled", "probe.v11.sketchy.disabled");
        directDisabled.IsEnabled = false;
        var parentDisabled = Views.VStack(
            Sketchy("Parent disabled", "probe.v11.sketchy.parent.disabled"));
        parentDisabled.IsEnabled = false;
        var briteEnabled = Brite("Enabled Sign In", "probe.v11.brite.enabled", "#000000");
        var briteDisabled = Brite("Disabled Sign In", "probe.v11.brite.disabled", "#A2E436");
        briteDisabled.IsEnabled = false;
        var briteParentDisabled = Views.VStack(
            Brite("Parent disabled Sign In", "probe.v11.brite.parent.disabled", "#A2E436"));
        briteParentDisabled.IsEnabled = false;
        var square = false;

        var scroll = Views.Scroll(
                Views.Text("Sketchy source corners and Brite disabled compositing"),
                status,
                source, longSource, mutable,
                Views.Button("Toggle mutable corners", () =>
                {
                    square = !square;
                    mutable.WithButtonEllipticalCornerRadii(
                        square ? 0 : 255, square ? 0 : 25, square ? 0 : 25, square ? 0 : 225,
                        square ? 0 : 225, square ? 0 : 25, square ? 0 : 25, square ? 0 : 255);
                    status.Text = square ? "Corners square" : "Corners elliptical";
                }).WithAccessibilityIdentifier("probe.v11.corners.toggle"),
                roundedDefault, directDisabled, parentDisabled,
                briteEnabled, briteDisabled, briteParentDisabled,
                Views.Button("Toggle Light Dark", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme == SwiftColorScheme.Light
                        ? SwiftColorScheme.Dark : SwiftColorScheme.Light;
                    status.Text = root.PreferredColorScheme == SwiftColorScheme.Dark
                        ? "Mode: Dark" : "Mode: Light";
                }).WithAccessibilityIdentifier("probe.v11.theme"))
            .WithPadding(16)
            .WithForegroundColor("#212529", "#FFFFFF")
            .WithBackgroundColor("#FFFFFF", "#212529")
            .WithNavigationTitle("Source button corners")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v11.screen");
        scroll.Spacing = 12;
        return scroll;
    }

    private static SwiftView BuildButtonShadowProbe(SwiftView root)
    {
        var status = Views.Text("No action").WithAccessibilityIdentifier("probe.v12.status");
        SwiftView Brite(string text, string id, string border, Action onTap) =>
            Views.Button(
                    Views.Text(text).WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#000000", "#000000")
                        .WithPadding(6, 16, 6, 16).WithMinimumHeight(44),
                    onTap)
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance("#A2E436", "#A2E436", border, border, 4)
                .WithButtonBorderWidth(2)
                .WithShadow("#000000", "#000000", 0, 1, 3)
                .WithButtonShadowOffsetX(3)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);

        SwiftView? enabled = null;
        var horizontalShadow = true;
        enabled = Brite("Brite Sign In", "probe.v12.brite.enabled", "#000000", () =>
        {
            horizontalShadow = !horizontalShadow;
            enabled!.WithButtonShadowOffsetX(horizontalShadow ? 3 : 0);
            status.Text = horizontalShadow ? "Shadow x3" : "Shadow x0";
        });
        var disabled = Brite("Disabled Sign In", "probe.v12.brite.disabled", "#A2E436",
            () => status.Text = "Disabled invoked");
        disabled.IsEnabled = false;
        var parentDisabled = Views.VStack(
            Brite("Parent disabled", "probe.v12.brite.parent.disabled", "#A2E436",
                () => status.Text = "Parent invoked"));
        parentDisabled.IsEnabled = false;

        var outline = Views.Button(
                Views.Text("Outline, no shadow").WithTypography(14, 400, 1.2)
                    .WithForegroundColor("#000000", "#000000")
                    .WithPadding(6, 16, 6, 16).WithMinimumHeight(44),
                () => status.Text = "Outline tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance("#FFFFFF", "#FFFFFF", "#000000", "#000000", 4)
            .WithButtonBorderWidth(2)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("probe.v12.outline");

        var link = Views.Button(
                Views.Text("Text link").WithTypography(14, 400, 1.2).WithUnderline()
                    .WithForegroundColor("#000000", "#000000")
                    .WithPadding(6, 16, 6, 16).WithMinimumHeight(44),
                () => status.Text = "Link tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#000000", "#000000", 4)
            .WithButtonBorderWidth(2)
            .WithShadow("#000000", "#000000", 0, 1, 3)
            .WithButtonShadowOffsetX(3)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("probe.v12.link");
        var linkShadow = true;

        var ellipse = Views.Button(
                Views.Text("Ellipse shadow").WithTypography(14, 400, 1.2)
                    .WithForegroundColor("#000000", "#FFFFFF")
                    .WithPadding(6, 16, 6, 16).WithMinimumHeight(44),
                () => status.Text = "Ellipse tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithButtonAppearance(null, null, "#000000", "#FFFFFF", 25)
            .WithButtonBorderWidth(2)
            .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
            .WithShadow("#000000", "#000000", 0, 1, 3)
            .WithButtonShadowOffsetX(3)
            .WithMinimumHeight(44)
            .WithAccessibilityIdentifier("probe.v12.ellipse");

        var surface = Views.Button("Existing surface", () => status.Text = "Surface tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithPadding(12)
            .WithRoundedSurface("#EEF1FF", "#121B33", 4)
            .WithShadow("#000000", "#000000", 0, 1, 3)
            .WithAccessibilityIdentifier("probe.v12.surface");

        var scroll = Views.Scroll(
                Views.Text("Real SwiftUI Button shadow"), status,
                enabled, disabled, parentDisabled, outline, link,
                Views.Button("Toggle link shadow", () =>
                {
                    linkShadow = !linkShadow;
                    link.WithShadow("#000000", "#000000", 0, linkShadow ? 1 : 0, 3)
                        .WithButtonShadowOffsetX(linkShadow ? 3 : 0);
                    status.Text = linkShadow ? "Link shadow on" : "Link shadow off";
                }).WithAccessibilityIdentifier("probe.v12.link.toggle"),
                ellipse, surface,
                Views.Button("Toggle Light Dark", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme == SwiftColorScheme.Light
                        ? SwiftColorScheme.Dark : SwiftColorScheme.Light;
                    status.Text = root.PreferredColorScheme == SwiftColorScheme.Dark
                        ? "Mode: Dark" : "Mode: Light";
                }).WithAccessibilityIdentifier("probe.v12.theme"))
            .WithPadding(16)
            .WithForegroundColor("#212529", "#FFFFFF")
            .WithBackgroundColor("#FFFFFF", "#212529")
            .WithNavigationTitle("Button shadow")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v12.screen");
        scroll.Spacing = 12;
        return scroll;
    }

    private static SwiftView BuildButtonGroupProbe(SwiftView root)
    {
        var status = Views.Text("No action").WithAccessibilityIdentifier("probe.v13.status");
        var mode = Views.Text("Mode: Light").WithAccessibilityIdentifier("probe.v13.mode");
        var viewport = Views.Text("Parent available: waiting")
            .WithAccessibilityIdentifier("probe.v13.viewport");

        SwiftView Link(string id, bool clear, Action action)
        {
            var label = Views.HStack(
                    Views.Image("arrow.left.square"),
                    Views.Text("Logout").WithUnderline(false))
                .WithTypography(14, 400, 1.2)
                .WithForegroundColor("#6A6D71", "#B6BABF")
                .WithPadding(6, 16, 6, 16)
                .WithMinimumHeight(44);
            label.Spacing = 4;
            return Views.Button(label, action)
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance(null, null,
                    clear ? null : "#000000", clear ? null : "#FFFFFF", 25)
                .WithButtonBorderWidth(2)
                .WithButtonEllipticalCornerRadii(255, 25, 25, 225, 225, 25, 25, 255)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);
        }

        SwiftView Center(SwiftView button) =>
            Views.HStack(button).WithFlexibleWidth(alignment: SwiftHorizontalAlignment.Center);

        var clearLink = Link("probe.v13.link.clear", true,
            () => status.Text = "Link tapped");
        var opaqueReference = Link("probe.v13.link.opaque", false,
            () => status.Text = "Opaque tapped");
        var disabled = Link("probe.v13.link.disabled", true,
            () => status.Text = "Disabled invoked");
        disabled.IsEnabled = false;
        var inheritedDisabled = Views.VStack(
            Link("probe.v13.link.parent.disabled", true,
                () => status.Text = "Parent invoked"));
        inheritedDisabled.IsEnabled = false;

        SwiftView GroupButton(string title, string id, bool selected,
                              bool first, Action action, double borderWidth = 2)
        {
            var button = Views.Button(
                    Views.Text(title).WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#000000", "#FFFFFF")
                        .WithPadding(4, 16, 4, 16).WithMinimumHeight(44),
                    action)
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance(selected ? "#A2E436" : null,
                    selected ? "#A2E436" : null,
                    selected ? "#A2E436" : "#000000",
                    selected ? "#A2E436" : "#FFFFFF", 4)
                .WithButtonBorderWidth(borderWidth)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier(id);
            if (first)
                button.WithButtonEllipticalCornerRadii(4, 4, 0, 0, 0, 0, 4, 4);
            else
                button.WithButtonEllipticalCornerRadii(0, 0, 4, 4, 4, 4, 0, 0);
            return button;
        }

        var first = GroupButton("Today", "probe.v13.joined.first", true, true,
            () => status.Text = "First seam");
        var second = GroupButton("Choose", "probe.v13.joined.second", false, false,
            () => status.Text = "Second seam");
        first.WithShadow("#000000", "#000000", 0, 1, 3).WithButtonShadowOffsetX(3);
        var joined = Views.ButtonGroup([first, second], selectedIndex: 0)
            .WithFlexibleWidth(alignment: SwiftHorizontalAlignment.Center)
            .WithAccessibilityIdentifier("probe.v13.joined");

        SwiftView sourcePair = null!;
        SwiftView sourceFirst = null!;
        SwiftView sourceSecond = null!;
        var sourceStatus = Views.Text("Source: no action")
            .WithAccessibilityIdentifier("probe.v15.status");
        var sourceHits = new int[2];
        void SelectSource(int index)
        {
            sourcePair.SelectedIndex = index;
            sourceFirst.WithButtonAppearance(index == 0 ? "#A2E436" : null,
                index == 0 ? "#A2E436" : null,
                index == 0 ? "#A2E436" : "#000000",
                index == 0 ? "#A2E436" : "#FFFFFF", 4);
            sourceSecond.WithButtonAppearance(index == 1 ? "#A2E436" : null,
                index == 1 ? "#A2E436" : null,
                index == 1 ? "#A2E436" : "#000000",
                index == 1 ? "#A2E436" : "#FFFFFF", 4);
            sourceStatus.Text = $"Source: {(index == 0 ? "Today" : "Choose Your Own")} ({++sourceHits[index]})";
        }
        sourceFirst = GroupButton("Today", "probe.v15.group.first", true, true,
            () => SelectSource(0), borderWidth: 1);
        sourceSecond = GroupButton("Choose Your Own", "probe.v15.group.second", false, false,
            () => SelectSource(1), borderWidth: 1);
        sourcePair = Views.ButtonGroup([sourceFirst, sourceSecond], selectedIndex: 0)
            .WithButtonGroupLayout(1)
            .WithFlexibleWidth()
            .WithAccessibilityIdentifier("probe.v15.group");

        static bool Rejects<T>(Action action) where T : Exception
        {
            try { action(); return false; }
            catch (T) { return true; }
        }
        using var wrongKind = Views.Button("Not a group", () => { });
        var checkedGroup = Views.ButtonGroup([Views.Button("Guarded", () => { })]);
        var groupGuardsPass = checkedGroup.SelectedIndex == -1 &&
            ReferenceEquals(checkedGroup.WithButtonGroupLayout(0), checkedGroup) &&
            new[] { -1d, double.NaN, double.PositiveInfinity, double.NegativeInfinity }
                .All(value => Rejects<ArgumentOutOfRangeException>(
                    () => checkedGroup.WithButtonGroupLayout(value))) &&
            Rejects<InvalidOperationException>(() => wrongKind.WithButtonGroupLayout(1));
        checkedGroup.Dispose();
        groupGuardsPass &= Rejects<ObjectDisposedException>(
            () => checkedGroup.WithButtonGroupLayout(1));
        var guardStatus = Views.Text(groupGuardsPass ? "Group guards passed" : "Group guards failed")
            .WithAccessibilityIdentifier("probe.v15.guards");

        var captions = new[] { "5m", "Ten minutes", "20 minutes", "Half hour",
                               "Forty-five minutes", "Long session" };
        var choices = captions.Select((title, index) =>
        {
            var button = Views.Button(
                    Views.Text(title).WithTypography(14, 400, 1.2)
                        .WithForegroundColor("#000000", "#FFFFFF")
                        .WithPadding(4, 12, 4, 12).WithMinimumHeight(44)
                        .WithFlexibleWidth(alignment: SwiftHorizontalAlignment.Center),
                    () => status.Text = $"Choice {index}")
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithButtonAppearance(index == 2 ? "#A2E436" : null,
                    index == 2 ? "#A2E436" : null,
                    index == 2 ? "#A2E436" : "#000000",
                    index == 2 ? "#A2E436" : "#FFFFFF", 4)
                .WithButtonBorderWidth(2)
                .WithMinimumHeight(44)
                .WithFlexibleWidth()
                .WithAccessibilityIdentifier($"probe.v13.choice.{index}");
            button.WithButtonEllipticalCornerRadii(
                index == 0 ? 4 : 0, index == 0 ? 4 : 0,
                index == 5 ? 4 : 0, index == 5 ? 4 : 0,
                index == 5 ? 4 : 0, index == 5 ? 4 : 0,
                index == 0 ? 4 : 0, index == 0 ? 4 : 0);
            return button;
        }).ToArray();
        var preferences = Views.ButtonGroup(choices, wraps: true, selectedIndex: 2)
            .WithFlexibleWidth(320)
            .WithAccessibilityIdentifier("probe.v13.choices")
            .OnViewportChanged((width, type) =>
                viewport.Text = $"Parent available: {Math.Round(width)} / Type: {type}");
        var narrow = false;

        var scroll = Views.Scroll(
                Views.Text("Clear stroke and intrinsic Button groups"),
                status, mode,
                Center(clearLink), Center(opaqueReference),
                Center(disabled), Center(inheritedDisabled),
                joined,
                sourcePair, sourceStatus, guardStatus,
                Views.Button("Fill source group", () =>
                {
                    sourcePair.WithButtonGroupLayout(1, fillAvailableWidth: true);
                    sourceStatus.Text = "Source group: Filled";
                }).WithAccessibilityIdentifier("probe.v15.fill"),
                Views.Button("Select next", () =>
                {
                    joined.SelectedIndex = 1;
                    first.WithButtonAppearance(null, null, "#000000", "#FFFFFF", 4)
                        .WithShadow("#000000", "#000000", 0, 0, 3);
                    second.WithButtonAppearance("#A2E436", "#A2E436",
                            "#A2E436", "#A2E436", 4)
                        .WithShadow("#000000", "#000000", 0, 1, 3)
                        .WithButtonShadowOffsetX(3);
                    status.Text = "Selected: Second";
                }).WithAccessibilityIdentifier("probe.v13.joined.select.second"),
                viewport, preferences,
                Views.Button("Contract group width", () =>
                {
                    narrow = !narrow;
                    preferences.WithFlexibleWidth(narrow ? 195 : 320);
                    status.Text = narrow ? "Width: 195" : "Width: 320";
                }).WithAccessibilityIdentifier("probe.v13.width"),
                Views.Button("Lengthen one localized choice", () =>
                {
                    choices[3].Children[0].Text = "Ein längerer Zeitabschnitt";
                    status.Text = "Label expanded";
                }).WithAccessibilityIdentifier("probe.v13.locale"),
                Views.Button("Toggle Light Dark", () =>
                {
                    root.PreferredColorScheme = root.PreferredColorScheme == SwiftColorScheme.Light
                        ? SwiftColorScheme.Dark : SwiftColorScheme.Light;
                    mode.Text = $"Mode: {root.PreferredColorScheme}";
                }).WithAccessibilityIdentifier("probe.v13.theme"))
            .WithPadding(12)
            .WithBackgroundColor("#FFFFFF", "#212529")
            .WithForegroundColor("#212529", "#FFFFFF")
            .WithNavigationTitle("Button groups")
            .WithInlineNavigationTitle()
            .WithTabBarHidden()
            .WithAccessibilityIdentifier("probe.v13.screen");
        scroll.Spacing = 8;
        return scroll;
    }

    private static SwiftView BuildComposedMenuProbe()
    {
        var mediaStatus = Views.Text("Media type selection: Video (0)")
            .WithAccessibilityIdentifier("probe.p19.media.status");
        var languageStatus = Views.Text("Language selection: English (0)")
            .WithAccessibilityIdentifier("probe.p19.language.status");

        SwiftView Select(string id, string field, string[] values, SwiftView status)
        {
            var selectedIndex = 0;
            var selectedText = Views.Text(values[selectedIndex])
                .WithAccessibilityIdentifier($"{id}.value");
            var chevron = Views.Image("chevron.down")
                .WithAccessibilityIdentifier($"{id}.chevron");
            var label = Views.HStack(selectedText.WithFlexibleWidth(), chevron)
                .WithFlexibleWidth()
                .WithPadding(8, 12, 8, 12)
                .WithRoundedSurface("#F7F8FF", "#060913", 6,
                                    "#6B7888", "#93A3C7", 1)
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier($"{id}.label");
            label.Spacing = 8;
            SwiftView? menu = null;
            var marks = new SwiftView[values.Length];
            var options = new SwiftView[values.Length];
            for (var i = 0; i < values.Length; i++)
            {
                var choice = i;
                marks[i] = Views.Image("checkmark").WithOpacity(i == selectedIndex ? 1 : 0);
                options[i] = Views.Button(
                        Views.HStack(Views.Text(values[i]).WithFlexibleWidth(), marks[i]),
                        () =>
                        {
                            selectedIndex = choice;
                            selectedText.Text = values[choice];
                            menu!.Text = values[choice];
                            status.Text = $"{field} selection: {values[choice]} ({choice})";
                            for (var index = 0; index < options.Length; index++)
                            {
                                marks[index].WithOpacity(index == choice ? 1 : 0);
                                options[index].WithAccessibilitySelected(index == choice);
                            }
                        })
                    .WithAccessibilityIdentifier($"{id}.option.{i}")
                    .WithAccessibilityLabel(values[i])
                    .WithAccessibilitySelected(i == selectedIndex);
            }
            menu = Views.Menu(label, options)
                .WithAccessibilityLabel(field)
                .WithAccessibilityIdentifier(id)
                .WithFlexibleWidth();
            menu.Text = values[selectedIndex];
            return menu;
        }

        return Views.Form(
                Views.Section("Resource Edit",
                    Views.Text("Media type"),
                    Select("probe.p19.media", "Media type", ["Video", "Text", "Audio"],
                        mediaStatus),
                    mediaStatus,
                    Views.Text("Language"),
                    Select("probe.p19.language", "Language",
                        ["English", "Korean", "Spanish"], languageStatus),
                    languageStatus))
            .WithNavigationTitle("Composed selects")
            .WithInlineNavigationTitle()
            .WithTabBarHidden();
    }

    private static SwiftView BuildHorizontalGridProbe()
    {
        using (var invalidHeader = Views.HStack(Views.Text("Only one cell")))
        {
            try
            {
                _ = Views.HorizontalGrid([0, double.NaN], invalidHeader);
                throw new InvalidOperationException("A non-finite column minimum was accepted.");
            }
            catch (ArgumentOutOfRangeException)
            {
            }
        }

        var inputStatus = Views.Text("Input: untouched")
            .WithAccessibilityIdentifier("probe.p18.input.status");
        var focusStatus = Views.Text("Focus B: not yet")
            .WithAccessibilityIdentifier("probe.p18.focus.status");
        var typeAStatus = Views.Text("Type A: Word")
            .WithAccessibilityIdentifier("probe.p18.type.a.status");
        var typeStatus = Views.Text("Type B: Word")
            .WithAccessibilityIdentifier("probe.p18.type.status");
        var countStatus = Views.Text("Rows: 2")
            .WithAccessibilityIdentifier("probe.p18.rows.status");
        SwiftView? grid = null;
        SwiftView? firstRow = null;
        var autoRemoveTriggered = false;
        firstRow = Views.HStack(
                Views.TextField("Target A", "morning", value =>
                        inputStatus.Text = $"Input A: {value}")
                    .WithAccessibilityIdentifier("probe.p18.target.a"),
                Views.Text("greeting").WithAccessibilityIdentifier("probe.p18.native.a"),
                Views.Picker("Type A", ["Word", "Phrase", "Sentence"], 0,
                        selected => typeAStatus.Text =
                            $"Type A: {new[] { "Word", "Phrase", "Sentence" }[selected]}")
                    .WithTypography(15, 400, 1.3)
                    .WithForegroundColor("#0B0D12", "#F8FAFF")
                    .WithPadding(8, 12, 8, 12)
                    .WithRoundedSurface("#F7F8FF", "#060913", 6,
                                        "#6B7888", "#93A3C7", 1)
                    .WithMinimumHeight(44)
                    .WithPickerStyle(SwiftPickerStyle.Menu)
                    .WithFlexibleWidth()
                    .WithAccessibilityIdentifier("probe.p18.kind.a"),
                Views.Text("daily").WithAccessibilityIdentifier("probe.p18.tags.a"),
                Views.Button(Views.Image("xmark"), () =>
                {
                    grid!.RemoveAt(1);
                    firstRow!.Dispose();
                    countStatus.Text = "Rows: 1";
                })
                    .WithAccessibilityLabel("Remove A")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.p18.remove.a"))
            .WithAccessibilityIdentifier("probe.p18.row.a");
        SwiftView? secondRow = null;
        secondRow = Views.HStack(
                Views.TextField("Target B", "good afternoon", value =>
                {
                    inputStatus.Text = $"Input B: {value}";
                    if (value.EndsWith('!') && !autoRemoveTriggered)
                    {
                        autoRemoveTriggered = true;
                        firstRow!.Children[4].InvokeAction();
                    }
                })
                    .OnFocusChanged(focused =>
                        focusStatus.Text = focused ? "Focus B: yes" : "Focus B: no")
                    .WithAccessibilityIdentifier("probe.p18.target.b"),
                Views.Text("salutation").WithAccessibilityIdentifier("probe.p18.native.b"),
                Views.Picker("Type B", ["Word", "Phrase", "Sentence"], 0,
                        selected => typeStatus.Text =
                            $"Type B: {new[] { "Word", "Phrase", "Sentence" }[selected]}")
                    .WithPickerStyle(SwiftPickerStyle.Menu)
                    .WithAccessibilityIdentifier("probe.p18.kind.b"),
                Views.Text("formal").WithAccessibilityIdentifier("probe.p18.tags.b"),
                Views.Button(Views.Image("xmark"), () =>
                {
                    grid!.RemoveAt(1);
                    secondRow!.Dispose();
                    countStatus.Text = "Rows: 0";
                })
                    .WithAccessibilityLabel("Remove B")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.p18.remove.b"))
            .WithAccessibilityIdentifier("probe.p18.row.b");
        grid = Views.HorizontalGrid([0, 0, 120, 0, 0],
                Views.HStack(
                        Views.Text("Target").WithAccessibilityIdentifier("probe.p18.header.target"),
                        Views.Text("Native").WithAccessibilityIdentifier("probe.p18.header.native"),
                        Views.Text("Type").WithAccessibilityIdentifier("probe.p18.header.type"),
                        Views.Text("Tags").WithAccessibilityIdentifier("probe.p18.header.tags"),
                        Views.Text("Remove").WithAccessibilityIdentifier("probe.p18.header.remove"))
                    .WithAccessibilityIdentifier("probe.p18.header"),
                firstRow, secondRow)
            .WithAccessibilityIdentifier("probe.p18.grid");
        grid.Spacing = 12;

        return Views.Form(Views.Section("Staged vocabulary",
                Views.Text("Column guard: passed")
                    .WithAccessibilityIdentifier("probe.p18.guard"),
                inputStatus, focusStatus, typeAStatus, typeStatus, countStatus, grid))
            .WithNavigationTitle("Horizontal grid")
            .WithInlineNavigationTitle()
            .WithTabBarHidden();
    }

    private static SwiftView BuildFourScreenBridgeProbe(SwiftView sceneRoot)
    {
        var bytes = Convert.FromBase64String(
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQ7LgLAAIkAXfC8r3XAAAAAElFTkSuQmCC");
        var status = Views.Text("Bridge idle")
            .WithAccessibilityIdentifier("probe.p16.status");
        var photoStatus = Views.Text("Photo loading")
            .WithAccessibilityIdentifier("probe.p16.photo.status");
        var modalReceipt = Views.Text("No modal receipt")
            .WithAccessibilityIdentifier("probe.p16.modal.receipt");
        var modalStatus = Views.Text("No modal dismissed")
            .WithAccessibilityIdentifier("probe.p16.modal.status");
        var selectedStatus = Views.Text("No quick-add selection")
            .WithAccessibilityIdentifier("probe.p16.quick.status");
        var quickKeyReceipt = Views.Text("Keys: none")
            .WithAccessibilityIdentifier("probe.p16.quick.keys");
        var submitCount = 0;
        var correcting = false;
        SwiftView? answer = null;
        answer = Views.TextField("Answer", onChanged: _ => { })
            .WithAccessibilityIdentifier("probe.p16.quiz.answer")
            .OnSubmit(() =>
            {
                if (string.IsNullOrWhiteSpace(answer!.Text))
                    return;
                submitCount++;
                status.Text = correcting
                    ? $"Correction submitted: {submitCount}"
                    : $"Answer submitted: {submitCount}";
            });
        var completed = Views.Button(Views.Text("Completed Quiz")
                .WithStrikethrough(),
                () => status.Text = "Completed card tapped")
            .WithButtonStyle(SwiftButtonStyle.Plain)
            .WithOpacity(0.75)
            .WithAccessibilityIdentifier("probe.p16.completed");

        SwiftView? cover = null;
        SwiftView? sheet = null;
        SwiftView? deleteDialog = null;
        var photo = Views.ImageFromBytes(bytes, "Photo hint", maxHeight: 160,
                onRendered: () => photoStatus.Text = "Photo displayed",
                onFailed: failure => photoStatus.Text = $"Photo failed: {failure}")
            .WithAccessibilityIdentifier("probe.p16.photo.thumbnail");
        var thumbnail = Views.Button(photo, () => cover!.IsPresented = true)
            .WithAccessibilityLabel("Enlarge photo")
            .WithAccessibilityIdentifier("probe.p16.photo.open");

        SwiftView? quickPopup = null;
        SwiftView? quickField = null;
        var highlighted = -1;
        var selectedCount = 0;
        SwiftView[] candidates = new SwiftView[3];

        void Highlight(int next)
        {
            highlighted = next;
            for (var index = 0; index < candidates.Length; index++)
            {
                var selected = index == highlighted;
                candidates[index].WithAccessibilitySelected(selected)
                    .WithButtonAppearance(selected ? "#1E4DFF" : null,
                        selected ? "#6B8CFF" : null,
                        "#6B7888", "#93A3C7", 6);
            }
        }

        void Choose(int index)
        {
            selectedStatus.Text = $"Chosen: {index}, count: {++selectedCount}";
            quickPopup!.IsPresented = false;
            quickField!.Text = "";
            quickField.FocusRequested = true;
        }

        for (var index = 0; index < candidates.Length; index++)
        {
            var option = index;
            candidates[index] = Views.Button(
                    Views.Text(option == 2 ? "Create new word" : $"Word {option + 1}")
                        .WithPadding(8, 12, 8, 12)
                        .WithFlexibleWidth(),
                    () => Choose(option))
                .WithButtonStyle(SwiftButtonStyle.Plain)
                .WithFlexibleWidth()
                .WithMinimumHeight(44)
                .WithAccessibilityIdentifier($"probe.p16.quick.option.{option}");
        }
        Highlight(-1);
        quickField = Views.TextField("Find vocabulary", onChanged: value =>
            {
                Highlight(-1);
                quickPopup!.IsPresented = !string.IsNullOrWhiteSpace(value);
            })
            .WithAccessibilityIdentifier("probe.p16.quick.field")
            .OnKeyPress(key =>
            {
                quickKeyReceipt.Text =
                    $"Key: {key}, popup: {quickPopup!.IsPresented}, selected: {highlighted}";
                if (key == SwiftTextKey.Escape)
                {
                    quickPopup!.IsPresented = false;
                    quickField!.Text = "";
                    return true;
                }
                if (!quickPopup!.IsPresented)
                    return false;
                if (key is SwiftTextKey.ArrowDown or SwiftTextKey.ArrowUp)
                {
                    Highlight(highlighted < 0
                        ? key == SwiftTextKey.ArrowDown ? 0 : candidates.Length - 1
                        : (highlighted + (key == SwiftTextKey.ArrowDown ? 1
                            : candidates.Length - 1)) % candidates.Length);
                    selectedStatus.Text = $"Highlighted: {highlighted}";
                    return true;
                }
                if (key == SwiftTextKey.Enter && highlighted >= 0)
                {
                    Choose(highlighted);
                    return true;
                }
                return false;
            })
            .OnSubmit(() =>
            {
                quickKeyReceipt.Text =
                    $"Submit: popup: {quickPopup!.IsPresented}, selected: {highlighted}";
                selectedStatus.Text = "Quick Add submit fallback";
            });

        var sentenceStatus = Views.Text("Sentence empty")
            .WithAccessibilityIdentifier("probe.p17.sentence.status");
        var sentenceEditor = Views.TextEditor("", next =>
                sentenceStatus.Text = next.Length == 0
                    ? "Sentence empty" : $"Sentence length: {next.Length}")
            .WithTextEditorPlaceholder("Write a sentence with the target word")
            .WithPlaceholderColor("#7A8699", "#93A3C7")
            .WithMinimumHeight(140)
            .WithAccessibilityLabel("Sentence editor")
            .WithAccessibilityIdentifier("probe.p17.sentence.input");

        var editor = Views.Form(
            Views.Section("Quiz",
                status, completed,
                Views.VStack(Views.Divider()
                        .WithAccessibilityIdentifier("probe.p16.divider"))
                    .WithFlexibleWidth(),
                Views.IndeterminateProgress("Loading quiz")
                    .WithAccessibilityIdentifier("probe.p16.spinner"),
                answer!,
                Views.Button("Submit answer", () =>
                {
                    if (!string.IsNullOrWhiteSpace(answer!.Text))
                        status.Text = "Answer submitted by button";
                }).WithAccessibilityIdentifier("probe.p16.quiz.submit"),
                Views.Button("Type Correct", () =>
                {
                    correcting = true;
                    answer!.Text = "";
                    answer!.FocusRequested = true;
                    status.Text = "Type Correct in the same field";
                }).WithAccessibilityIdentifier("probe.p16.quiz.correct"),
                photoStatus, modalReceipt, thumbnail,
                Views.Button("Decode failure", () =>
                {
                    using var bad = Views.ImageFromBytes([0, 1, 2], "Photo hint",
                        onFailed: error => photoStatus.Text = $"Photo failed: {error}");
                }).WithAccessibilityIdentifier("probe.p16.photo.bad"),
                Views.Button("Learning Details", () => sheet!.IsPresented = true)
                    .WithAccessibilityIdentifier("probe.p16.details.open")),
            Views.Section("Quick Add",
                selectedStatus, quickKeyReceipt, quickField!,
                Views.Text("Form row below suggestions")
                    .WithAccessibilityIdentifier("probe.p16.quick.row-below")),
            Views.Section("Resource",
                modalStatus,
                Views.Button("Request Delete", () => deleteDialog!.IsPresented = true)
                    .WithAccessibilityIdentifier("probe.p16.delete.open"),
                Views.Button("Block starter", () => sceneRoot.IsPresented = true)
                    .WithAccessibilityIdentifier("probe.p16.starter.open"),
                Views.Button("Background action", () => status.Text = "Background activated")
                    .WithAccessibilityIdentifier("probe.p16.background.action")),
            Views.Section("Sentence placeholder", sentenceStatus, sentenceEditor));
        editor.WithAccessibilityIdentifier("probe.p16.screen");
        var suggestions = Views.VStack(candidates)
            .WithAccessibilityIdentifier("probe.p16.quick.suggestions");
        quickPopup = Views.QuickAddSuggestions(
            editor, "probe.p16.quick.field", suggestions,
            () => selectedStatus.Text = "Suggestions dismissed")
            .WithAccessibilityIdentifier("probe.p16.quick.listbox");
        var details = new List<SwiftView>
        {
            Views.Text("Learning Details")
                .WithAccessibilityIdentifier("probe.p16.details.heading"),
            Views.Divider(),
            Views.Button("Close details", () => sheet!.IsPresented = false)
                .WithAccessibilityIdentifier("probe.p16.details.close")
        };
        details.AddRange(Enumerable.Range(0, 18).Select(index =>
            Views.Text($"Owned progress detail {index}")));
        sheet = Views.Sheet(quickPopup,
            Views.Scroll(details.ToArray())
                .WithAccessibilityIdentifier("probe.p16.details.scroll"),
            () =>
            {
                modalStatus.Text = "Details dismissed";
                modalReceipt.Text = "Details dismissed";
            })
            .WithSheetDetentFraction(0.7);
        cover = Views.FullScreenPhotoCover(sheet,
                Views.ZoomablePhoto(bytes, "Photo hint",
                        onFailed: failure => photoStatus.Text =
                            $"Viewer photo failed: {failure}")
                    .WithAccessibilityIdentifier("probe.p16.photo.fullscreen"),
                Views.Button(Views.Image("xmark"), () => cover!.IsPresented = false)
                    .WithAccessibilityLabel("Close photo")
                    .WithMinimumHeight(44)
                    .WithAccessibilityIdentifier("probe.p16.photo.close"),
                () =>
                {
                    modalStatus.Text = "Photo dismissed";
                    modalReceipt.Text = "Photo dismissed";
                    if (correcting)
                        answer!.FocusRequested = true;
                })
            .WithAccessibilityIdentifier("probe.p16.photo.cover");
        deleteDialog = Views.ResourceDeleteConfirmation(cover,
                "Delete resource?", "A confirmed delete is irreversible.",
                "Close", "Cancel", "Delete",
                () => modalStatus.Text = "Delete cancelled, draft retained",
                () =>
                {
                    modalStatus.Text = "Dummy confirm callback only";
                    deleteDialog!.IsPresented = false;
                })
            .WithAccessibilityIdentifier("probe.p16.delete");
        return deleteDialog
            .WithNavigationTitle("Four-screen bridge")
            .WithInlineNavigationTitle()
            .WithTabBarHidden();
    }
}
