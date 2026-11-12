import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class SplitViewTests: XCTestCase {
    @MainActor
    private func split(columns: Int) -> MSUNode {
        let split = MSUBridge.makeNode(kind: "splitView")
        for index in 0..<columns {
            split.insertChild(MSUBridge.makeNode(kind: "vstack"), at: index)
        }
        return split
    }

    @MainActor
    func testDefaultsKeepTheSystemBehavior() {
        let node = split(columns: 3)
        XCTAssertEqual(node.splitColumnVisibility, "automatic")
        XCTAssertEqual(node.splitCompactColumn, "sidebar")
        XCTAssertEqual(node.splitViewStyle, "")
        XCTAssertEqual(node.children[1].splitColumnIdealWidth, 0)
        _ = SwiftUINodeView(node: node).body
        _ = SplitViewNodeView(node: node).body
        _ = SplitViewNodeView(node: split(columns: 2)).body
    }

    @MainActor
    func testStylesAndColumnWidthsRender() {
        for style in ["balanced", "prominentDetail"] {
            let node = split(columns: 3)
            node.splitViewStyle = style
            node.children[1].splitColumnMinWidth = 280
            node.children[1].splitColumnIdealWidth = 340
            node.children[1].splitColumnMaxWidth = 520
            node.splitColumnVisibility = "doubleColumn"
            node.splitCompactColumn = "content"
            _ = SplitViewNodeView(node: node).body
        }
    }

    func testVisibilityAndColumnNamesRoundTrip() {
        // A platform may resolve .automatic to an equal visibility (macOS: .doubleColumn), so
        // the check is that each name maps back to an equal visibility.
        for name in ["automatic", "all", "doubleColumn", "detailOnly"] {
            let visibility = msuSplitVisibility(name)
            XCTAssertEqual(msuSplitVisibility(msuSplitVisibilityName(visibility)), visibility)
        }
        XCTAssertEqual(msuSplitVisibilityName(.all), "all")
        XCTAssertEqual(msuSplitVisibilityName(.detailOnly), "detailOnly")
        for (index, name) in ["sidebar", "content", "detail"].enumerated() {
            XCTAssertEqual(msuSplitColumnName(msuSplitColumn(name)), name)
            XCTAssertEqual(msuSplitColumnIndex(name), index)
        }
    }

    @MainActor
    func testAViewCanBeLeftOutInACompactWidth() {
        let button = MSUBridge.makeNode(kind: "button")
        XCTAssertFalse(button.hiddenInCompactWidth)
        button.hiddenInCompactWidth = true
        _ = SwiftUINodeView(node: button).body
    }

    @MainActor
    func testTabBarOnlyStyleSelectsTheTabAPI() {
        let tabs = MSUBridge.makeNode(kind: "tabView")
        let tab = MSUBridge.makeNode(kind: "tab")
        tab.text = "Library"
        tab.imageName = "books.vertical"
        tab.insertChild(split(columns: 3), at: 0)
        tabs.insertChild(tab, at: 0)
        tabs.tabViewStyle = "tabBarOnly"
        XCTAssertTrue(tabs.usesAdaptiveTabs)
        _ = SwiftUINodeView(node: tabs).body
    }
}
