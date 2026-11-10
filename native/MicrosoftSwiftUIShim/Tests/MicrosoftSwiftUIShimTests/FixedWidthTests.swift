import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Fixed width (0.1.0-preview.45): opt-in `frame(width:)`, so a sidebar column keeps its width
/// beside a flexible column instead of taking an equal share of the row.
final class FixedWidthTests: XCTestCase {
    @MainActor
    func testFixedWidthDefaultsOffAndPublishesChanges() {
        let node = MSUBridge.makeNode(kind: "vstack")
        XCTAssertEqual(node.fixedWidth, 0)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.fixedWidth = 240
        _ = SwiftUINodeView(node: node).body
        XCTAssertEqual(changes, 1)
        observation.cancel()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testAFixedWidthIgnoresTheProposedWidth() {
        func size(_ node: MSUNode, width: CGFloat) -> CGSize {
            NSHostingController(rootView: SwiftUINodeView(node: node))
                .sizeThatFits(in: CGSize(width: width, height: 1_000))
        }

        let text = MSUBridge.makeNode(kind: "text")
        text.text = "Filters"
        let natural = size(text, width: 1_000)
        XCTAssertLessThan(natural.width, 200)

        text.fixedWidth = 240
        // Wider than its text when offered more, and still 240 when offered less.
        XCTAssertEqual(size(text, width: 1_000).width, 240, accuracy: 0.5)
        XCTAssertEqual(size(text, width: 100).width, 240, accuracy: 0.5)

        text.fixedWidth = 0
        XCTAssertEqual(size(text, width: 1_000).width, natural.width, accuracy: 0.5)
    }

    @MainActor
    func testAFixedColumnKeepsItsWidthBesideAFlexibleOne() {
        let column = MSUBridge.makeNode(kind: "text")
        column.text = "Filters"
        column.fixedWidth = 300
        let rest = MSUBridge.makeNode(kind: "text")
        rest.text = "Results"
        rest.fillsWidth = true
        let row = MSUBridge.makeNode(kind: "hstack")
        row.spacing = 0
        row.insertChild(column, at: 0)
        row.insertChild(rest, at: 1)

        let host = NSHostingController(rootView: SwiftUINodeView(node: row))
        let total = host.sizeThatFits(in: CGSize(width: 1_000, height: 400))
        // A flexible row fills what it is offered; the column keeps 300 of it, not half.
        XCTAssertEqual(total.width, 1_000, accuracy: 0.5)
        let columnHost = NSHostingController(rootView: SwiftUINodeView(node: column))
        XCTAssertEqual(columnHost.sizeThatFits(in: CGSize(width: 500, height: 400)).width,
                       300, accuracy: 0.5)
    }
    #endif
}
