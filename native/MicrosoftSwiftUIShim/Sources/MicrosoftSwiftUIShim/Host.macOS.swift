#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftUI

extension MSUBridge {
    @objc(hostControllerForRoot:)
    public static func hostController(forRoot root: MSUNode) -> NSViewController {
        NSHostingController(rootView: SwiftUINodeView(node: root))
    }

    @objc(hostViewForRoot:)
    public static func hostView(forRoot root: MSUNode) -> NSView {
        NSHostingView(rootView: SwiftUINodeView(node: root))
    }

    @objc(deactivateHost:)
    public static func deactivateHost(_ host: NSObject) -> Bool {
        if let view = host as? NSHostingView<SwiftUINodeView> {
            view.rootView = SwiftUINodeView(node: MSUNode(kind: "text"))
            return true
        }
        if let controller = host as? NSHostingController<SwiftUINodeView> {
            controller.rootView = SwiftUINodeView(node: MSUNode(kind: "text"))
            return true
        }
        return false
    }
}
#endif
