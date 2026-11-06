import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Keyboard dismissal by a scroll node's drag (0.1.0-preview.41): opt-in, so existing
/// scrolls keep the system's automatic behavior.
final class ScrollKeyboardDismissalTests: XCTestCase {
    @MainActor
    func testDismissalDefaultsToTheSystemAndPublishesChanges() {
        let scroll = MSUBridge.makeNode(kind: "scroll")
        scroll.insertChild(MSUBridge.makeNode(kind: "textEditor"), at: 0)
        XCTAssertEqual(scroll.scrollDismissesKeyboard, "")
        var changes = 0
        let observation = scroll.objectWillChange.sink { changes += 1 }
        for mode in ["interactively", "immediately", "never", ""] {
            scroll.scrollDismissesKeyboard = mode
            XCTAssertEqual(scroll.scrollDismissesKeyboard, mode)
            _ = SwiftUINodeView(node: scroll).body
        }
        XCTAssertEqual(changes, 4)
        observation.cancel()
    }

    func testOnlyANamedModeAppliesTheModifier() {
        // "" applies nothing (the environment's behavior stays); content inside an opted-in
        // scroll is reset to "automatic".
        XCTAssertNil(ScrollKeyboardDismissal.resolved(""))
        XCTAssertNil(ScrollKeyboardDismissal.resolved("sometimes"))
        for mode in ["automatic", "immediately", "interactively", "never"] {
            XCTAssertNotNil(ScrollKeyboardDismissal.resolved(mode), mode)
        }
    }
}
