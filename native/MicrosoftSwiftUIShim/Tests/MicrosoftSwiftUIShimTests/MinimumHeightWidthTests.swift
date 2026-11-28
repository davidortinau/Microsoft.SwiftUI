import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// A minimum height that keeps the child's width (0.1.0-preview.71, SentenceStudio issue 334).
/// SwiftUI's `frame(minHeight:)` places its child in the child's own measured width, and a row
/// placed that way gives its least flexible child an equal share, less than it measured. The
/// bridge's minimum height is a layout of its own that places the child in the width the
/// layout was offered, and is otherwise what the frame was.
final class MinimumHeightWidthTests: XCTestCase {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    private final class Placed {
        var widths: [Int: CGFloat] = [:]
    }

    /// Reports its one child's size and records the width the child is placed in.
    private struct WidthProbe: Layout {
        let placed: Placed
        let index: Int

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            subviews.first?.sizeThatFits(proposal) ?? .zero
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
                           cache: inout ()) {
            placed.widths[index] = bounds.width
            subviews.first?.place(at: bounds.origin, proposal: proposal)
        }
    }

    /// The widths "Submit" and "I was correct" are placed in, side by side in a host 400
    /// points wide, with the row wrapped as `around` wraps it.
    @MainActor
    private func placedWidths<Wrapped: View>(
        _ around: (AnyView) -> Wrapped
    ) -> (submit: CGFloat, wasCorrect: CGFloat) {
        let placed = Placed()
        let row = HStack(spacing: 8) {
            WidthProbe(placed: placed, index: 0) { Text("Submit").padding(.horizontal, 48) }
            WidthProbe(placed: placed, index: 1) { Text("I was correct").padding(.horizontal, 16) }
        }
        let host = NSHostingView(rootView: around(AnyView(row)))
        host.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        host.layoutSubtreeIfNeeded()
        if let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
            host.cacheDisplay(in: host.bounds, to: bitmap)
        }
        return (placed.widths[0] ?? 0, placed.widths[1] ?? 0)
    }

    @MainActor
    func testARowWithAMinimumHeightKeepsItsChildrensWidths() {
        let free = placedWidths { $0 }
        XCTAssertGreaterThan(free.submit, 96)
        XCTAssertGreaterThan(free.wasCorrect, 32)

        // Why the bridge does not use SwiftUI's frame: it squeezes the wider child.
        let framed = placedWidths { $0.frame(minHeight: 60) }
        XCTAssertLessThan(framed.submit, free.submit - 1)

        let bridged = placedWidths { $0.modifier(MinimumHeightFrame(minHeight: 60)) }
        XCTAssertEqual(bridged.submit, free.submit, accuracy: 0.5)
        XCTAssertEqual(bridged.wasCorrect, free.wasCorrect, accuracy: 0.5)
    }

    @MainActor
    private func size(_ node: MSUNode, offered: CGSize = CGSize(width: 400, height: 1_000)) -> CGSize {
        NSHostingController(rootView: SwiftUINodeView(node: node)).sizeThatFits(in: offered)
    }

    @MainActor
    private func row(_ titles: [String]) -> MSUNode {
        let row = MSUBridge.makeNode(kind: "hstack")
        row.spacing = 8
        for (index, title) in titles.enumerated() {
            let text = MSUBridge.makeNode(kind: "text")
            text.text = title
            row.insertChild(text, at: index)
        }
        return row
    }

    /// In height the layout is what `frame(minHeight:)` was: a lower child is raised to the
    /// minimum, a higher one keeps its height, and neither changes the width.
    @MainActor
    func testTheMinimumHeightIsKeptAndTheWidthIsTheChilds() {
        let free = size(row(["Submit", "I was correct"]))
        let raised = row(["Submit", "I was correct"])
        raised.minimumHeight = 60
        XCTAssertEqual(size(raised).height, 60, accuracy: 0.5)
        XCTAssertEqual(size(raised).width, free.width, accuracy: 0.5)

        let low = row(["Submit", "I was correct"])
        low.minimumHeight = 4
        XCTAssertEqual(size(low).height, free.height, accuracy: 0.5)
        XCTAssertEqual(size(low).width, free.width, accuracy: 0.5)
    }

    /// The app uses an empty stack with a minimum height as a spacer and as a bar of a chart:
    /// it is that high, and no wider than its nothing.
    @MainActor
    func testAnEmptyStackWithAMinimumHeightIsThatHigh() {
        let spacer = MSUBridge.makeNode(kind: "vstack")
        spacer.minimumHeight = 24
        let fitted = size(spacer)
        XCTAssertEqual(fitted.height, 24, accuracy: 0.5)
        XCTAssertEqual(fitted.width, 0, accuracy: 0.5)
    }
    #endif
}
