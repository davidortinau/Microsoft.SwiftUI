import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Fixed size (0.1.0-preview.43): opt-in `fixedSize(horizontal:vertical:)`, so a badge or a
/// short button beside a flexible title keeps its ideal width instead of an equal share.
final class FixedSizeTests: XCTestCase {
    @MainActor
    func testFixedSizeDefaultsOffAndPublishesChanges() {
        let node = MSUBridge.makeNode(kind: "text")
        node.text = "Failed"
        XCTAssertFalse(node.fixedHorizontalSize)
        XCTAssertFalse(node.fixedVerticalSize)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.fixedHorizontalSize = true
        _ = SwiftUINodeView(node: node).body
        node.fixedVerticalSize = true
        _ = SwiftUINodeView(node: node).body
        XCTAssertEqual(changes, 2)
        observation.cancel()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testAFixedWidthKeepsItsIdealWidthWhenProposedLess() {
        func label(_ text: String) -> MSUNode {
            let node = MSUBridge.makeNode(kind: "text")
            node.text = text
            return node
        }

        func size(_ node: MSUNode, width: CGFloat) -> CGSize {
            NSHostingController(rootView: SwiftUINodeView(node: node))
                .sizeThatFits(in: CGSize(width: width, height: 1_000))
        }

        let text = label("Select All New")
        let ideal = size(text, width: 1_000)
        let squeezed = size(text, width: ideal.width / 3)
        // Unfixed, a narrow proposal wraps the text: narrower and taller than its ideal.
        XCTAssertLessThan(squeezed.width, ideal.width)
        XCTAssertGreaterThan(squeezed.height, ideal.height)

        text.fixedHorizontalSize = true
        let fixed = size(text, width: ideal.width / 3)
        XCTAssertEqual(fixed.width, ideal.width, accuracy: 0.5)
        XCTAssertEqual(fixed.height, ideal.height, accuracy: 0.5)
    }
    #endif
}
