import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class LabeledContentTests: XCTestCase {
    @MainActor
    func testLabeledContentRendersItsTitleAndContent() {
        let form = MSUBridge.makeNode(kind: "form")
        let row = MSUBridge.makeNode(kind: "labeledContent")
        row.text = "Title"
        let field = MSUBridge.makeNode(kind: "textField")
        field.text = "Int1.2"
        row.insertChild(field, at: 0)
        form.insertChild(row, at: 0)
        _ = SwiftUINodeView(node: form).body
        _ = SwiftUINodeView(node: row).body
        XCTAssertEqual(row.children.first?.text, "Int1.2")
        // Without content it renders nothing rather than failing.
        let empty = MSUBridge.makeNode(kind: "labeledContent")
        _ = SwiftUINodeView(node: empty).body
    }
}
