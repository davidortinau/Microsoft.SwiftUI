import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Dynamic Type override (0.1.0-preview.70): a node and everything under it are drawn at one
/// Dynamic Type size. On macOS SwiftUI scales nothing for `dynamicTypeSize`, so the bridge
/// multiplies text by Apple's Body size for it over 17, as iOS does for a font relative to Body.
final class DynamicTypeOverrideTests: XCTestCase {
    @MainActor
    private func text(_ value: String, size: Double = 0, font: String = "", style: String = "") -> MSUNode {
        let node = MSUBridge.makeNode(kind: "text")
        node.text = value
        node.fontSize = size
        node.fontPostScriptName = font
        node.fontStyle = style
        return node
    }

    @MainActor
    func testTheOverrideDefaultsToTheSystemsSizeAndPublishesChanges() {
        let node = text("Retry")
        XCTAssertEqual(node.dynamicTypeSizeOverride, -1)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.dynamicTypeSizeOverride = 11
        buildHosted(node)
        XCTAssertEqual(changes, 1)
        observation.cancel()
    }

    func testSizesAndScalesFollowApplesBodyTable() {
        XCTAssertNil(msuDynamicTypeSize(-1))
        XCTAssertNil(msuDynamicTypeSize(12))
        XCTAssertEqual(msuDynamicTypeSize(0), .xSmall)
        XCTAssertEqual(msuDynamicTypeSize(3), .large)
        XCTAssertEqual(msuDynamicTypeSize(11), .accessibility5)
        // No override: the system's scale and what an ancestor set, unchanged.
        XCTAssertEqual(msuTextScale(system: 1, inherited: 1, override: -1), 1)
        XCTAssertEqual(msuTextScale(system: 1, inherited: 2, override: -1), 2)
        XCTAssertEqual(msuTextScale(system: 1.5, inherited: 1, override: 12), 1.5)
        // A node's own override stands for both.
        XCTAssertEqual(msuTextScale(system: 1, inherited: 2, override: 3), 1)
        XCTAssertEqual(msuTextScale(system: 1, inherited: 1, override: 11), 53.0 / 17, accuracy: 0.0001)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    private func size(_ node: MSUNode) -> CGSize {
        NSHostingController(rootView: SwiftUINodeView(node: node))
            .sizeThatFits(in: CGSize(width: 10_000, height: 10_000))
    }

    /// Every kind of font a node can carry is 53/17 as large at accessibility5, on the node
    /// itself and under a container that carries the override; without it nothing changes.
    /// The system font sets its letters closer as it grows, so its width is a little under the
    /// ratio (2.85 to 2.98 here); a named font is the ratio.
    @MainActor
    func testTextIsDrawnAtBodysRatioOnTheNodeAndUnderIt() {
        let scale = 53.0 / 17
        let kinds: [(String, () -> MSUNode)] = [
            ("a system font with a size", { self.text("Completed 11/25/2026", size: 15) }),
            ("a named font relative to Body", { self.text("Completed 11/25/2026", size: 15, font: "Helvetica") }),
            ("a text style", { self.text("Completed 11/25/2026", style: "caption") }),
            ("no font of its own", { self.text("Completed 11/25/2026") }),
        ]
        for (what, make) in kinds {
            let plain = size(make())
            let own = make()
            own.dynamicTypeSizeOverride = 11
            XCTAssertEqual(size(own).width / plain.width, scale, accuracy: 0.3, "\(what), on the node")
            XCTAssertEqual(size(own).height / plain.height, scale, accuracy: 0.3, "\(what), on the node")

            let stack = MSUBridge.makeNode(kind: "vstack")
            stack.insertChild(make(), at: 0)
            let unscaled = size(stack)
            if what.hasPrefix("a named font") {
                XCTAssertEqual(size(own).width / plain.width, scale, accuracy: 0.05, what)
            }
            XCTAssertEqual(unscaled.width, plain.width, accuracy: 0.5, "\(what), no override")
            stack.dynamicTypeSizeOverride = 11
            XCTAssertEqual(size(stack).width / plain.width, scale, accuracy: 0.3, "\(what), under a container")

            // The default size is the default drawing, and a child's own override wins.
            stack.dynamicTypeSizeOverride = 3
            XCTAssertEqual(size(stack).width, plain.width, accuracy: 0.5, "\(what), at large")
            let held = make()
            held.dynamicTypeSizeOverride = 3
            let outer = MSUBridge.makeNode(kind: "vstack")
            outer.insertChild(held, at: 0)
            outer.dynamicTypeSizeOverride = 11
            XCTAssertEqual(size(outer).width, plain.width, accuracy: 0.5, "\(what), held at large inside")
        }
    }

    /// A symbol without a size of its own grows with the text beside it, as on iOS.
    @MainActor
    func testASymbolWithoutASizeOfItsOwnGrowsWithTheText() {
        func icon() -> MSUNode {
            let node = MSUBridge.makeNode(kind: "image")
            node.imageName = "arrow.clockwise"
            return node
        }
        let plain = size(icon())
        let large = icon()
        large.dynamicTypeSizeOverride = 11
        XCTAssertGreaterThan(size(large).width, plain.width * 2.5)
    }
    #endif
}
