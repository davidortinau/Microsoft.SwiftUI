using System;
using Foundation;
using ObjCRuntime;
#if IOS
using UIKit;
#elif MACOS
using AppKit;
#endif

namespace Microsoft.SwiftUI.Native;

[BaseType(typeof(NSObject))]
[DisableDefaultCtor]
interface MSUNode
{
    [Export("kind")]
    string Kind { get; }

    [Export("text")]
    string Text { get; set; }

    [Export("lineLimit")]
    nint LineLimit { get; set; }

    [Export("placeholder")]
    string Placeholder { get; set; }

    [Export("hidesTextEditorScrollBackground")]
    bool HidesTextEditorScrollBackground { get; set; }

    [Export("imageName")]
    string ImageName { get; set; }

    [Export("fixedSymbolSize")]
    double FixedSymbolSize { get; set; }

#nullable enable
    [Export("photoData")]
    NSData? PhotoData { get; set; }
#nullable restore

    [Export("photoStatus")]
    string PhotoStatus { get; }

    [Export("photoMaxHeight")]
    double PhotoMaxHeight { get; set; }

    [Export("automationId")]
    string AutomationId { get; set; }

    [Export("quickAddAnchorId")]
    string QuickAddAnchorId { get; set; }

    [Export("accessibilityLabelText")]
    string AccessibilityLabelText { get; set; }

    [Export("accessibilitySelected")]
    bool AccessibilitySelected { get; set; }

    [Export("isOn")]
    bool IsOn { get; set; }

    [Export("isPresented")]
    bool IsPresented { get; set; }

    [Export("deletePending")]
    bool DeletePending { get; set; }

    [Export("transparentDeleteBackdrop")]
    bool TransparentDeleteBackdrop { get; set; }

    [Export("deleteCloseLabel")]
    string DeleteCloseLabel { get; set; }

    [Export("deleteCancelLabel")]
    string DeleteCancelLabel { get; set; }

    [Export("deleteConfirmLabel")]
    string DeleteConfirmLabel { get; set; }

    [Export("sheetDetentFraction")]
    double SheetDetentFraction { get; set; }

    [Export("focusRequested")]
    bool FocusRequested { get; set; }

    [Export("value")]
    double Value { get; set; }

    [Export("minimum")]
    double Minimum { get; set; }

    [Export("maximum")]
    double Maximum { get; set; }

    [Export("spacing")]
    double Spacing { get; set; }

    [Export("buttonGroupWraps")]
    bool ButtonGroupWraps { get; set; }

    [Export("buttonGroupOverlap")]
    double ButtonGroupOverlap { get; set; }

    [Export("buttonGroupFillAvailableWidth")]
    bool ButtonGroupFillAvailableWidth { get; set; }

    [Export("selectedIndex")]
    nint SelectedIndex { get; set; }

    [Export("selectedValue")]
    string SelectedValue { get; set; }

    [Export("isEnabled")]
    bool IsEnabled { get; set; }

    [Export("canNavigateBack")]
    bool CanNavigateBack { get; set; }

    [Export("hidesTabBar")]
    bool HidesTabBar { get; set; }

    [Export("route")]
    string Route { get; set; }

    [Export("fontStyle")]
    string FontStyle { get; set; }

    [Export("fontSize")]
    double FontSize { get; set; }

    [Export("fontWeight")]
    nint FontWeight { get; set; }

    [Export("fontPostScriptName")]
    string FontPostScriptName { get; set; }

    [Export("lineHeightMultiple")]
    double LineHeightMultiple { get; set; }

    [Export("preferredScheme")]
    string PreferredScheme { get; set; }

    [Export("buttonStyle")]
    string ButtonStyle { get; set; }

    [Export("hasButtonAppearance")]
    bool HasButtonAppearance { get; set; }

    [Export("buttonFillHex")]
    string ButtonFillHex { get; set; }

    [Export("buttonFillDarkHex")]
    string ButtonFillDarkHex { get; set; }

    [Export("buttonBorderHex")]
    string ButtonBorderHex { get; set; }

    [Export("buttonBorderDarkHex")]
    string ButtonBorderDarkHex { get; set; }

    [Export("buttonBorderWidth")]
    double ButtonBorderWidth { get; set; }

    [Export("buttonCornerRadius")]
    double ButtonCornerRadius { get; set; }

    [Export("buttonCircleDiameter")]
    double ButtonCircleDiameter { get; set; }

    [Export("hasButtonEllipticalCornerRadii")]
    bool HasButtonEllipticalCornerRadii { get; set; }

    [Export("buttonCornerTopLeftX")]
    double ButtonCornerTopLeftX { get; set; }

    [Export("buttonCornerTopLeftY")]
    double ButtonCornerTopLeftY { get; set; }

    [Export("buttonCornerTopRightX")]
    double ButtonCornerTopRightX { get; set; }

    [Export("buttonCornerTopRightY")]
    double ButtonCornerTopRightY { get; set; }

    [Export("buttonCornerBottomRightX")]
    double ButtonCornerBottomRightX { get; set; }

    [Export("buttonCornerBottomRightY")]
    double ButtonCornerBottomRightY { get; set; }

    [Export("buttonCornerBottomLeftX")]
    double ButtonCornerBottomLeftX { get; set; }

    [Export("buttonCornerBottomLeftY")]
    double ButtonCornerBottomLeftY { get; set; }

    [Export("buttonDisabledOpacity")]
    double ButtonDisabledOpacity { get; set; }

    [Export("isUnderlined")]
    bool IsUnderlined { get; set; }

    [Export("isStrikethrough")]
    bool IsStrikethrough { get; set; }

    [Export("opacity")]
    double Opacity { get; set; }

    [Export("diameter")]
    double Diameter { get; set; }

    [Export("pickerStyle")]
    string PickerStyle { get; set; }

    [Export("paddingPoints")]
    double PaddingPoints { get; set; }

    [Export("paddingTop")]
    double PaddingTop { get; set; }

    [Export("paddingRight")]
    double PaddingRight { get; set; }

    [Export("paddingBottom")]
    double PaddingBottom { get; set; }

    [Export("paddingLeft")]
    double PaddingLeft { get; set; }

    [Export("foregroundHex")]
    string ForegroundHex { get; set; }

    [Export("foregroundDarkHex")]
    string ForegroundDarkHex { get; set; }

    [Export("backgroundHex")]
    string BackgroundHex { get; set; }

    [Export("backgroundDarkHex")]
    string BackgroundDarkHex { get; set; }

    [Export("tintHex")]
    string TintHex { get; set; }

    [Export("tintDarkHex")]
    string TintDarkHex { get; set; }

    [Export("progressTrackHex")]
    string ProgressTrackHex { get; set; }

    [Export("progressTrackDarkHex")]
    string ProgressTrackDarkHex { get; set; }

    [Export("progressThickness")]
    double ProgressThickness { get; set; }

    [Export("cornerRadius")]
    double CornerRadius { get; set; }

    [Export("borderHex")]
    string BorderHex { get; set; }

    [Export("borderDarkHex")]
    string BorderDarkHex { get; set; }

    [Export("borderWidth")]
    double BorderWidth { get; set; }

    [Export("shadowHex")]
    string ShadowHex { get; set; }

    [Export("shadowDarkHex")]
    string ShadowDarkHex { get; set; }

    [Export("shadowRadius")]
    double ShadowRadius { get; set; }

    [Export("shadowOpacity")]
    double ShadowOpacity { get; set; }

    [Export("shadowOffsetX")]
    double ShadowOffsetX { get; set; }

    [Export("shadowOffsetY")]
    double ShadowOffsetY { get; set; }

    [Export("fillsWidth")]
    bool FillsWidth { get; set; }

    [Export("maxWidth")]
    double MaxWidth { get; set; }

    [Export("horizontalAlignment")]
    string HorizontalAlignment { get; set; }

    [Export("adaptiveStackBelowWidth")]
    double AdaptiveStackBelowWidth { get; set; }

    [Export("minimumHeight")]
    double MinimumHeight { get; set; }

    [Export("gridColumns")]
    nint GridColumns { get; set; }

    [Export("gridColumnMinimumWidths")]
    NSNumber[] GridColumnMinimumWidths { get; set; }

    [Export("navigationTitle")]
    string NavigationTitle { get; set; }

    [Export("inlineNavigationTitle")]
    bool InlineNavigationTitle { get; set; }

    [Export("centerWhenShort")]
    bool CenterWhenShort { get; set; }

    [Export("anchorsToBottom")]
    bool AnchorsToBottom { get; set; }

    [Export("nativeListCanvasHex")]
    string NativeListCanvasHex { get; set; }

    [Export("nativeListCanvasDarkHex")]
    string NativeListCanvasDarkHex { get; set; }

    [Export("nativeListRowHex")]
    string NativeListRowHex { get; set; }

    [Export("nativeListRowDarkHex")]
    string NativeListRowDarkHex { get; set; }

    [Export("placeholderColorHex")]
    string PlaceholderColorHex { get; set; }

    [Export("placeholderColorDarkHex")]
    string PlaceholderColorDarkHex { get; set; }

    [Export("pathDepth")]
    nint PathDepth { get; }

    [Export("appendRoute:")]
    void AppendRoute(string route);

    [Export("popRoute")]
    void PopRoute();

    [Export("clearPath")]
    void ClearPath();

    [Export("insertChild:atIndex:")]
    void InsertChild(MSUNode child, nint index);

    [Export("removeChildAtIndex:")]
    void RemoveChild(nint index);

    [Export("clearChildren")]
    void ClearChildren();

    [Export("clearHandlers")]
    void ClearHandlers();

    [Export("invokeAction")]
    void InvokeAction();

    [Export("setTapHandler:")]
    void SetTapHandler(Action handler);

    [Export("setTextChangedHandler:")]
    void SetTextChangedHandler(Action<string> handler);

    [Export("setBoolChangedHandler:")]
    void SetBoolChangedHandler(Action<bool> handler);

    [Export("setValueChangedHandler:")]
    void SetValueChangedHandler(Action<double> handler);

    [Export("setSelectionChangedHandler:")]
    void SetSelectionChangedHandler(Action<nint> handler);

    [Export("setFocusChangedHandler:")]
    void SetFocusChangedHandler(Action<bool> handler);

    [Export("setDismissedHandler:")]
    void SetDismissedHandler(Action handler);

    [Export("setSelectedValueChangedHandler:")]
    void SetSelectedValueChangedHandler(Action<string> handler);

    [Export("setNavigationChangedHandler:")]
    void SetNavigationChangedHandler(Action<nint> handler);

    [Export("setAppearedHandler:")]
    void SetAppearedHandler(Action handler);

    [Export("setEscapeHandler:")]
    void SetEscapeHandler(Action handler);

    [Export("setSubmitHandler:")]
    void SetSubmitHandler(Action handler);

    [Export("setKeyHandler:")]
    void SetKeyHandler(Func<string, bool> handler);

    [Export("setPhotoRenderedHandler:")]
    void SetPhotoRenderedHandler(Action handler);

    [Export("setPhotoFailedHandler:")]
    void SetPhotoFailedHandler(Action<string> handler);

    [Export("setDeleteCancelledHandler:")]
    void SetDeleteCancelledHandler(Action handler);

    [Export("setDeleteConfirmedHandler:")]
    void SetDeleteConfirmedHandler(Action handler);

    [Export("setFileImportedHandler:")]
    void SetFileImportedHandler(Action<NSData, string, string> handler);

    [Export("setFileImportErrorHandler:")]
    void SetFileImportErrorHandler(Action<string> handler);

    [Export("setFileImportCancelledHandler:")]
    void SetFileImportCancelledHandler(Action handler);

    [Export("setViewportChangedHandler:")]
    void SetViewportChangedHandler(Action<double, nint> handler);
}

[BaseType(typeof(NSObject))]
interface MSUBridge
{
    [Static, Export("makeNodeWithKind:")]
    MSUNode MakeNode(string kind);

    [Static, Export("deactivateHost:")]
    bool DeactivateHost(NSObject host);

    [Static, Export("runApplicationWithRoot:sceneChanged:")]
    void RunApplication(MSUNode root, Action<nint> sceneChanged);

#if IOS
    [Static, Export("hostControllerForRoot:")]
    UIViewController HostController(MSUNode root);
#elif MACOS
    [Static, Export("hostControllerForRoot:")]
    NSViewController HostController(MSUNode root);

    [Static, Export("hostViewForRoot:")]
    NSView HostView(MSUNode root);
#endif
}
