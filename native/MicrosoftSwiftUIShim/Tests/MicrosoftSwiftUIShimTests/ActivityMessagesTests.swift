import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Activity messages (0.1.0-preview.35): an `overlay` node layers a transient
/// toast over a page edge, and an opt-in announcement tells VoiceOver about it.
final class ActivityMessagesTests: XCTestCase {
    @MainActor
    func testOverlayDefaultsToBottomAndRendersBothChildren() {
        let overlay = MSUBridge.makeNode(kind: "overlay")
        XCTAssertEqual(overlay.overlayEdge, "bottom")
        let page = MSUBridge.makeNode(kind: "vstack")
        let layer = MSUBridge.makeNode(kind: "vstack")
        overlay.insertChild(page, at: 0)
        overlay.insertChild(layer, at: 1)
        _ = SwiftUINodeView(node: overlay).body
        _ = OverlayNodeView(node: overlay).body
        var changes = 0
        let observation = overlay.objectWillChange.sink { changes += 1 }
        overlay.overlayEdge = "top"
        XCTAssertEqual(changes, 1)
        observation.cancel()
        _ = OverlayNodeView(node: overlay).body
    }

    @MainActor
    func testAnnouncementDefaultsEmptyPublishesChangesAndPostsNonEmptyText() {
        let text = MSUBridge.makeNode(kind: "text")
        XCTAssertEqual(text.accessibilityAnnouncement, "")
        var changes = 0
        let observation = text.objectWillChange.sink { changes += 1 }
        text.accessibilityAnnouncement = "Saved"
        XCTAssertEqual(changes, 1)
        observation.cancel()
        _ = SwiftUINodeView(node: text).body

        let before = msuPostedAnnouncements.count
        msuPostAnnouncement("")
        XCTAssertEqual(msuPostedAnnouncements.count, before)
        msuPostAnnouncement("Graded! Accuracy: 85%")
        XCTAssertEqual(msuPostedAnnouncements.last, "Graded! Accuracy: 85%")
        XCTAssertEqual(msuPostedAnnouncements.count, before + 1)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testOverlayLayerDoesNotChangeContentLayout() {
        func page() -> MSUNode {
            let text = MSUBridge.makeNode(kind: "text")
            text.text = "Page"
            let stack = MSUBridge.makeNode(kind: "vstack")
            stack.insertChild(text, at: 0)
            return stack
        }
        let plain = NSHostingView(rootView: SwiftUINodeView(node: page()))
        plain.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        plain.layoutSubtreeIfNeeded()

        let overlay = MSUBridge.makeNode(kind: "overlay")
        overlay.insertChild(page(), at: 0)
        let layer = MSUBridge.makeNode(kind: "vstack")
        let toast = MSUBridge.makeNode(kind: "text")
        toast.text = "Saved"
        toast.accessibilityAnnouncement = "Saved"
        layer.insertChild(toast, at: 0)
        overlay.insertChild(layer, at: 1)
        let layered = NSHostingView(rootView: SwiftUINodeView(node: overlay))
        layered.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        layered.layoutSubtreeIfNeeded()
        XCTAssertEqual(layered.fittingSize.width, plain.fittingSize.width, accuracy: 0.5)
    }
    #endif
}
