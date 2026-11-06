import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// A toggle that draws only its switch (0.1.0-preview.42): opt-in, so existing toggles keep
/// their label.
final class ToggleLabelsHiddenTests: XCTestCase {
    @MainActor
    func testLabelsHiddenDefaultsOffAndPublishesChanges() {
        let toggle = MSUBridge.makeNode(kind: "toggle")
        toggle.text = "Pause monitoring"
        XCTAssertFalse(toggle.labelsHidden)
        var changes = 0
        let observation = toggle.objectWillChange.sink { changes += 1 }
        toggle.labelsHidden = true
        XCTAssertTrue(toggle.labelsHidden)
        _ = SwiftUINodeView(node: toggle).body
        toggle.labelsHidden = false
        _ = SwiftUINodeView(node: toggle).body
        XCTAssertEqual(changes, 2)
        XCTAssertEqual(toggle.text, "Pause monitoring")
        observation.cancel()
    }
}
