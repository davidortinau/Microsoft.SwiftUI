import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Menu label width (0.1.0-preview.68): a menu's custom label fills the width the menu is
/// offered by default; opt-in, it keeps the label's own width, so an icon-only menu beside
/// flexible content stays icon-sized without `fixedSize`.
final class MenuLabelWidthTests: XCTestCase {
    @MainActor
    private func menu(label: MSUNode) -> MSUNode {
        let menu = MSUBridge.makeNode(kind: "menu")
        let action = MSUBridge.makeNode(kind: "button")
        action.text = "Slower"
        menu.insertChild(label, at: 0)
        menu.insertChild(action, at: 1)
        return menu
    }

    @MainActor
    func testFittingTheLabelDefaultsOffAndPublishesChanges() {
        let icon = MSUBridge.makeNode(kind: "image")
        icon.imageName = "slider.horizontal.3"
        let node = menu(label: icon)
        XCTAssertFalse(node.menuLabelFitsContent)
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.menuLabelFitsContent = true
        _ = SwiftUINodeView(node: node).body
        XCTAssertEqual(changes, 1)
        XCTAssertTrue(node.menuLabelFitsContent)
        observation.cancel()
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// The label is measured by itself: macOS draws a Menu as a pull-down button that sizes
    /// to its label either way, so only the label's own view shows what iOS lays out.
    @MainActor
    func testALabelFillsTheOfferedWidthByDefaultAndKeepsItsOwnWhenFitted() {
        let text = MSUBridge.makeNode(kind: "text")
        text.text = "Pace"

        func width(_ view: some View, offered: CGFloat) -> CGFloat {
            NSHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: offered, height: 1_000)).width
        }

        let own = width(SwiftUINodeView(node: text), offered: 300)
        XCTAssertLessThan(own, 100)

        // Default: the label takes all 300 points, as every menu did before this version.
        XCTAssertEqual(width(MenuLabel(label: text, fitsContent: false), offered: 300), 300,
                       accuracy: 0.5)
        // Fitted: the label is as wide as its text, whatever it is offered.
        XCTAssertEqual(width(MenuLabel(label: text, fitsContent: true), offered: 300), own,
                       accuracy: 0.5)
        XCTAssertEqual(width(MenuLabel(label: text, fitsContent: true), offered: 600), own,
                       accuracy: 0.5)
    }

    /// In a row, a fitted label leaves the free width to the flexible neighbour; a default
    /// label shares it.
    @MainActor
    func testInARowAFittedLabelLeavesTheRoomToAFlexibleNeighbour() {
        let text = MSUBridge.makeNode(kind: "text")
        text.text = "Pace"

        func labelWidth(fitsContent: Bool) -> CGFloat {
            var measured: CGFloat = 0
            let row = HStack(spacing: 0) {
                Color.clear.frame(maxWidth: .infinity)
                MenuLabel(label: text, fitsContent: fitsContent)
                    .background(GeometryReader { proxy in
                        Color.clear.onAppear { measured = proxy.size.width }
                    })
            }.frame(width: 400, height: 44)
            let host = NSHostingView(rootView: row)
            host.frame = CGRect(x: 0, y: 0, width: 400, height: 44)
            let window = NSWindow(contentRect: host.frame, styleMask: [.borderless],
                                  backing: .buffered, defer: false)
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
            return measured
        }

        let own = NSHostingController(rootView: SwiftUINodeView(node: text))
            .sizeThatFits(in: CGSize(width: 400, height: 44)).width
        XCTAssertEqual(labelWidth(fitsContent: false), 200, accuracy: 0.5)
        XCTAssertEqual(labelWidth(fitsContent: true), own, accuracy: 0.5)
    }
    #endif
}
