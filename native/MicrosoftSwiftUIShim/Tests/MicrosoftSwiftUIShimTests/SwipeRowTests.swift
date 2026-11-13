import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class SwipeRowTests: XCTestCase {
    @MainActor
    func testSwipeRowsRolesAndLabelsRender() {
        let list = MSUBridge.makeNode(kind: "list")
        let row = MSUBridge.makeNode(kind: "swipeRow")
        row.insertChild(MSUBridge.makeNode(kind: "text"), at: 0)
        let delete = MSUBridge.makeNode(kind: "button")
        let label = MSUBridge.makeNode(kind: "label")
        label.text = "Delete"
        label.imageName = "trash"
        delete.insertChild(label, at: 0)
        delete.buttonRole = "destructive"
        row.insertChild(delete, at: 1)
        let study = MSUBridge.makeNode(kind: "button")
        study.text = "Study"
        row.insertChild(study, at: 2)
        row.swipeLeadingCount = 1
        list.insertChild(row, at: 0)
        _ = SwiftUINodeView(node: list).body
        _ = SwiftUINodeView(node: row).body
        _ = SwiftUINodeView(node: delete).body
        XCTAssertEqual(delete.buttonRole, "destructive")
        // A leading count past the actions is clamped when rendering.
        row.swipeLeadingCount = 9
        _ = SwiftUINodeView(node: row).body
    }
}
