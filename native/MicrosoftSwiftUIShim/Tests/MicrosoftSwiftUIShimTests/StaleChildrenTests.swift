import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Bodies SwiftUI builds after their guard (a sheet's content, a picker's options) must not
/// index children that changed in between: a Swift index trap freezes the app under .NET.
final class StaleChildrenTests: XCTestCase {
    @MainActor
    func testChildLookupIsBoundsSafe() {
        let sheet = MSUBridge.makeNode(kind: "sheet")
        XCTAssertNil(sheet.child(1))
        sheet.insertChild(MSUBridge.makeNode(kind: "text"), at: 0)
        sheet.insertChild(MSUBridge.makeNode(kind: "text"), at: 1)
        XCTAssertNotNil(sheet.child(1))
        XCTAssertNil(sheet.child(2))
        XCTAssertNil(sheet.child(-1))
    }

    @MainActor
    func testPickerAndTabsRenderAfterTheirChildrenShrink() {
        let picker = MSUBridge.makeNode(kind: "picker")
        for index in 0..<3 {
            let option = MSUBridge.makeNode(kind: "text")
            option.text = "Option \(index)"
            picker.insertChild(option, at: index)
        }
        _ = SwiftUINodeView(node: picker).body
        picker.removeChild(at: 2)
        picker.removeChild(at: 1)
        _ = SwiftUINodeView(node: picker).body
        let tabs = MSUBridge.makeNode(kind: "tabView")
        tabs.insertChild(MSUBridge.makeNode(kind: "tab"), at: 0)
        _ = SwiftUINodeView(node: tabs).body
    }
}
