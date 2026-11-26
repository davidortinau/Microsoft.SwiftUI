import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// A row that stacks when too wide (0.1.0-preview.69): an HStack's children are laid out in a
/// row while, each at its own width, they fit the width offered, and in a column when they do
/// not. Off by default.
final class FittingStackTests: XCTestCase {
    @MainActor
    private func row(_ titles: [String]) -> MSUNode {
        let row = MSUBridge.makeNode(kind: "hstack")
        for (index, title) in titles.enumerated() {
            let text = MSUBridge.makeNode(kind: "text")
            text.text = title
            row.insertChild(text, at: index)
        }
        return row
    }

    @MainActor
    func testStackingDefaultsOffAndPublishesChanges() {
        let node = row(["Submit", "I was correct"])
        XCTAssertFalse(node.stacksWhenTooWide)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.stacksWhenTooWide = true
        _ = SwiftUINodeView(node: node).body
        XCTAssertEqual(changes, 1)
        XCTAssertTrue(node.stacksWhenTooWide)
        observation.cancel()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    private func size(_ node: MSUNode, offered: CGFloat) -> CGSize {
        NSHostingController(rootView: SwiftUINodeView(node: node))
            .sizeThatFits(in: CGSize(width: offered, height: 1_000))
    }

    /// With room the children share one row at their own widths; without it they are one
    /// under another, none of them wrapped, and the layout is as wide as its widest child.
    @MainActor
    func testChildrenShareARowWhileTheyFitAndStackWhenTheyDoNot() {
        let first = row(["Submit the answer"])
        let second = row(["I was correct after all"])
        let both = row(["Submit the answer", "I was correct after all"])
        both.spacing = 8
        both.stacksWhenTooWide = true

        let a = size(first, offered: 1_000)
        let b = size(second, offered: 1_000)
        let needed = a.width + 8 + b.width

        let wide = size(both, offered: needed + 40)
        XCTAssertEqual(wide.width, needed, accuracy: 1)
        XCTAssertEqual(wide.height, max(a.height, b.height), accuracy: 1)

        // Exactly enough is still a row.
        XCTAssertEqual(size(both, offered: needed + 1).height, max(a.height, b.height), accuracy: 1)

        // Ten points short: a column, each child on one line of its own.
        let narrow = size(both, offered: needed - 10)
        XCTAssertEqual(narrow.height, a.height + 8 + b.height, accuracy: 1)
        XCTAssertEqual(narrow.width, max(a.width, b.width), accuracy: 1)
    }

    /// Without the option the same row at the same width stays one row and its text wraps:
    /// what every HStack did before this version.
    @MainActor
    func testWithoutTheOptionTheRowIsNotStacked() {
        let both = row(["Submit the answer", "I was correct after all"])
        both.spacing = 8
        let needed = size(both, offered: 1_000).width
        let line = size(both, offered: 1_000).height
        let plain = size(both, offered: needed - 10)
        both.stacksWhenTooWide = true
        let stacked = size(both, offered: needed - 10)
        XCTAssertEqual(stacked.height, line * 2 + 8, accuracy: 1)
        // The plain row kept both children side by side: it is not the column's height.
        XCTAssertNotEqual(plain.height, stacked.height, accuracy: 1)
    }
    #endif
}
