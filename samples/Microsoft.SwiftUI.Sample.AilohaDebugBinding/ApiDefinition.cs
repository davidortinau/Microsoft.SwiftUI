using System;
using Foundation;
using ObjCRuntime;
#if IOS
using UIKit;
#elif MACOS
using AppKit;
#endif

namespace Microsoft.SwiftUI.Sample.AilohaDebugBinding;

[BaseType(typeof(NSObject))]
[DisableDefaultCtor]
interface MicrosoftSwiftUIAilohaDebug
{
    [Static, Export("startWithCompletion:")]
    void Start(Action<bool, string> completion);

    [Static, Export("stop")]
    void Stop();

#if IOS
    [Static, Export("tagTextInputInRoot:placeholder:identifier:")]
    bool TagTextInput(UIView root, string placeholder, string identifier);
#elif MACOS
    [Static, Export("tagTextInputInRoot:placeholder:identifier:")]
    bool TagTextInput(NSView root, string placeholder, string identifier);
#endif
}
