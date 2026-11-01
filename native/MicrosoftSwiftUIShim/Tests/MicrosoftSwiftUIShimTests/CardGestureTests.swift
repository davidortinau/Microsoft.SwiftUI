import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Horizontal drag and card transform additions (0.1.0-preview.33). Both are
/// opt-in: nodes that never set them render and behave as before.
final class CardGestureTests: XCTestCase {
    @MainActor
    func testTransformDefaultsUnsetAndRecordsTheLatestChange() {
        let card = MSUBridge.makeNode(kind: "button")
        XCTAssertFalse(card.hasTransform)
        XCTAssertEqual(card.offsetX, 0)
        XCTAssertEqual(card.offsetY, 0)
        XCTAssertEqual(card.rotationDegrees, 0)
        XCTAssertFalse(card.transformAnimated)
        _ = SwiftUINodeView(node: card).body

        var changes = 0
        let observation = card.objectWillChange.sink { changes += 1 }
        card.setTransform(offsetX: 42, offsetY: -3, rotation: 2.5, animated: false)
        XCTAssertEqual(changes, 1, "One transform change publishes once.")
        XCTAssertTrue(card.hasTransform)
        XCTAssertEqual(card.offsetX, 42)
        XCTAssertEqual(card.offsetY, -3)
        XCTAssertEqual(card.rotationDegrees, 2.5)
        XCTAssertFalse(card.transformAnimated)
        _ = SwiftUINodeView(node: card).body

        card.setTransform(offsetX: 0, offsetY: 0, rotation: 0, animated: true)
        XCTAssertTrue(card.hasTransform, "Returning to zero keeps the same view structure.")
        XCTAssertTrue(card.transformAnimated)
        XCTAssertEqual(card.offsetX, 0)
        observation.cancel()
        _ = SwiftUINodeView(node: card).body
    }

    @MainActor
    func testHorizontalDragIsOptInOrderedAndRespectsDisabled() {
        let card = MSUBridge.makeNode(kind: "button")
        var taps = 0
        card.setTapHandler { taps += 1 }
        XCTAssertFalse(card.hasHorizontalDrag)
        XCTAssertEqual(card.horizontalDragMinimumDistance, 10)
        _ = SwiftUINodeView(node: card).body

        var changed: [Double] = []
        var ended: [(Double, Double)] = []
        var cancelled = 0
        var changes = 0
        let observation = card.objectWillChange.sink { changes += 1 }
        card.setHorizontalDragHandlers({ changed.append($0) },
                                       endedHandler: { ended.append(($0, $1)) },
                                       cancelledHandler: { cancelled += 1 })
        XCTAssertEqual(changes, 1, "Attaching the gesture must re-render the node.")
        observation.cancel()
        XCTAssertTrue(card.hasHorizontalDrag)
        _ = SwiftUINodeView(node: card).body

        // An end without a begun drag is ignored.
        card.reportHorizontalDragEnded(200, predicted: 260)
        XCTAssertTrue(ended.isEmpty)

        card.reportHorizontalDragChanged(30)
        card.reportHorizontalDragChanged(120)
        XCTAssertTrue(card.horizontalDragActive)
        card.reportHorizontalDragEnded(124, predicted: 190)
        XCTAssertEqual(changed, [30, 120])
        XCTAssertEqual(ended.count, 1)
        XCTAssertEqual(ended[0].0, 124)
        XCTAssertEqual(ended[0].1, 190)
        XCTAssertFalse(card.horizontalDragActive)
        card.reportHorizontalDragCancelled()
        XCTAssertEqual(cancelled, 0, "An ended drag is not also cancelled.")

        card.reportHorizontalDragChanged(-40)
        card.reportHorizontalDragCancelled()
        XCTAssertEqual(cancelled, 1)
        XCTAssertFalse(card.horizontalDragActive)

        // A drag that began while enabled still ends after a disable, so the owner can settle.
        card.reportHorizontalDragChanged(-50)
        card.isEnabled = false
        card.reportHorizontalDragEnded(-60, predicted: -60)
        XCTAssertEqual(ended.count, 2)
        // A disabled view does not begin a drag.
        card.reportHorizontalDragChanged(-70)
        XCTAssertEqual(changed, [30, 120, -40, -50])
        XCTAssertFalse(card.horizontalDragActive)
        card.isEnabled = true

        card.invokeAction()
        XCTAssertEqual(taps, 1, "The view's own tap stays independent of the drag.")
        card.clearHandlers()
        XCTAssertFalse(card.hasHorizontalDrag)
        card.reportHorizontalDragChanged(10)
        XCTAssertEqual(changed.count, 4)
        _ = SwiftUINodeView(node: card).body
    }
}
