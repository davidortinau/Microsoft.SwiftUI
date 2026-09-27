using AppKit;
using Microsoft.SwiftUI.Sample.MacOS;

NSApplication.Init();
var app = NSApplication.SharedApplication;
var appDelegate = new AppDelegate();
app.Delegate = appDelegate;
app.Run();
GC.KeepAlive(appDelegate);
