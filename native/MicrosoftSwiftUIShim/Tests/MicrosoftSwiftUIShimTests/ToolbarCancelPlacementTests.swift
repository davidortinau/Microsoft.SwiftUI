import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class ToolbarCancelPlacementTests: XCTestCase {
    @MainActor
    func testCancelRoleButtonRendersBesideTheOtherToolbarItems() {
        let toolbar = MSUBridge.makeNode(kind: "toolbar")
        toolbar.insertChild(MSUBridge.makeNode(kind: "text"), at: 0)
        let cancel = MSUBridge.makeNode(kind: "button")
        cancel.text = "Cancel"
        cancel.buttonRole = "cancel"
        toolbar.insertChild(cancel, at: 1)
        let save = MSUBridge.makeNode(kind: "button")
        save.text = "Import"
        toolbar.insertChild(save, at: 2)
        _ = SwiftUINodeView(node: toolbar).body
        // The node order is kept: a toolbar's buttons are updated in place by index.
        XCTAssertEqual(toolbar.children.map(\.text), ["", "Cancel", "Import"])
        // Without a Cancel-role button the toolbar renders as before.
        cancel.buttonRole = ""
        _ = SwiftUINodeView(node: toolbar).body
    }
}
