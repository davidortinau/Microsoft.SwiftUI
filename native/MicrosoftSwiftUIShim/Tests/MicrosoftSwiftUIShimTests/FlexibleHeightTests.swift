import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Flexible height (0.1.0-preview.34): opt-in `frame(maxHeight: .infinity)` so a
/// bounded grid of stacks shares its height evenly, and an empty placeholder keeps
/// the same slot as a visible tile.
final class FlexibleHeightTests: XCTestCase {
    @MainActor
    func testFlexibleHeightDefaultsOffAndPublishesChanges() {
        let node = MSUBridge.makeNode(kind: "vstack")
        XCTAssertFalse(node.fillsHeight)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.fillsHeight = true
        XCTAssertEqual(changes, 1)
        XCTAssertTrue(node.fillsHeight)
        observation.cancel()
        _ = SwiftUINodeView(node: node).body
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testFlexibleRowsShareBoundedHeightAndPlaceholdersKeepTheirSlot() {
        struct CapturePlacement: Layout {
            let record: (CGRect) -> Void

            func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                              cache: inout ()) -> CGSize {
                subviews[0].sizeThatFits(proposal)
            }

            func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                               subviews: Subviews, cache: inout ()) {
                record(bounds)
                subviews[0].place(at: bounds.origin, anchor: .topLeading,
                                  proposal: ProposedViewSize(bounds.size))
            }
        }

        func tile(_ text: String) -> MSUNode {
            let label = MSUBridge.makeNode(kind: "text")
            label.text = text
            label.fillsWidth = true
            label.fillsHeight = true
            label.horizontalAlignment = "center"
            label.backgroundHex = "#FFFFFF"
            label.backgroundDarkHex = "#000000"
            label.cornerRadius = 6
            let button = MSUBridge.makeNode(kind: "button")
            button.buttonStyle = "plain"
            button.insertChild(label, at: 0)
            return button
        }

        func placeholder() -> MSUNode {
            let empty = MSUBridge.makeNode(kind: "vstack")
            empty.fillsWidth = true
            empty.fillsHeight = true
            return empty
        }

        func row(_ children: [MSUNode]) -> MSUNode {
            let row = MSUBridge.makeNode(kind: "hstack")
            row.spacing = 4
            row.fillsWidth = true
            row.fillsHeight = true
            for (index, child) in children.enumerated() { row.insertChild(child, at: index) }
            return row
        }

        let visible = tile("A long target word that wraps across lines")
        let hidden = placeholder()
        let rows = [row([visible, tile("short")]), row([hidden, placeholder()])]
        let grid = MSUBridge.makeNode(kind: "vstack")
        grid.spacing = 4
        grid.fillsWidth = true
        grid.fillsHeight = true
        for (index, child) in rows.enumerated() { grid.insertChild(child, at: index) }

        var tileFrame = CGRect.null
        var hiddenFrame = CGRect.null
        var gridFrame = CGRect.null
        let host = NSHostingView(rootView: CapturePlacement(record: { gridFrame = $0 }) {
            SwiftUINodeView(node: grid)
        }.frame(width: 200, height: 400))
        host.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
        _ = host.fittingSize
        host.layoutSubtreeIfNeeded()
        XCTAssertEqual(gridFrame.height, 400, accuracy: 0.5)

        // Measure one visible and one hidden slot inside the same bounded grid.
        let measured = NSHostingView(rootView: VStack(spacing: 4) {
            HStack(spacing: 4) {
                CapturePlacement(record: { tileFrame = $0 }) { SwiftUINodeView(node: visible) }
                SwiftUINodeView(node: tile("short"))
            }
            HStack(spacing: 4) {
                CapturePlacement(record: { hiddenFrame = $0 }) { SwiftUINodeView(node: hidden) }
                SwiftUINodeView(node: placeholder())
            }
        }.frame(width: 200, height: 400))
        measured.frame = CGRect(x: 0, y: 0, width: 200, height: 400)
        _ = measured.fittingSize
        measured.layoutSubtreeIfNeeded()
        XCTAssertEqual(tileFrame.height, 198, accuracy: 1)
        XCTAssertEqual(tileFrame.width, 98, accuracy: 1)
        XCTAssertEqual(hiddenFrame.size.width, tileFrame.size.width, accuracy: 0.5)
        XCTAssertEqual(hiddenFrame.size.height, tileFrame.size.height, accuracy: 0.5)

        // Without the opt-in a tile keeps its content height.
        visible.children.first?.fillsHeight = false
        visible.fillsHeight = false
        tileFrame = .null
        measured.layoutSubtreeIfNeeded()
        _ = measured.fittingSize
        measured.layoutSubtreeIfNeeded()
        XCTAssertLessThan(tileFrame.height, 120)
    }
    #endif
}
