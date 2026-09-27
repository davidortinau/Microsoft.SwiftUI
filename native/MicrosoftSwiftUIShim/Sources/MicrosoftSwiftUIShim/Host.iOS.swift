#if canImport(UIKit)
import SwiftUI
import UIKit

extension MSUBridge {
    @objc(hostControllerForRoot:)
    public static func hostController(forRoot root: MSUNode) -> UIViewController {
        UIHostingController(rootView: SwiftUINodeView(node: root))
    }

    @objc(deactivateHost:)
    public static func deactivateHost(_ host: NSObject) -> Bool {
        guard let controller = host as? UIHostingController<SwiftUINodeView> else { return false }
        controller.rootView = SwiftUINodeView(node: MSUNode(kind: "text"))
        return true
    }
}
#endif
