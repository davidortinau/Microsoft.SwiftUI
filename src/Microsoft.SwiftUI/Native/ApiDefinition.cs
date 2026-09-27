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

    [Export("placeholder")]
    string Placeholder { get; set; }

    [Export("imageName")]
    string ImageName { get; set; }

    [Export("automationId")]
    string AutomationId { get; set; }

    [Export("accessibilityLabelText")]
    string AccessibilityLabelText { get; set; }

    [Export("isOn")]
    bool IsOn { get; set; }

    [Export("isPresented")]
    bool IsPresented { get; set; }

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

    [Export("selectedIndex")]
    nint SelectedIndex { get; set; }

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
}

[BaseType(typeof(NSObject))]
interface MSUBridge
{
    [Static, Export("makeNodeWithKind:")]
    MSUNode MakeNode(string kind);

    [Static, Export("deactivateHost:")]
    bool DeactivateHost(NSObject host);

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
