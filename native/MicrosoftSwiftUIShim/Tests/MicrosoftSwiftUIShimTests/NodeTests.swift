import XCTest
@testable import MicrosoftSwiftUIShim
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftUI
#endif

final class NodeTests: XCTestCase {
    func testNodesRetainStateAndChildren() {
        let root = MSUBridge.makeNode(kind: "vstack")
        let title = MSUBridge.makeNode(kind: "text")
        title.text = "Before"
        root.insertChild(title, at: 0)

        title.text = "After"
        XCTAssertEqual(root.children.first?.text, "After")
        XCTAssertEqual(root.children.count, 1)
        root.removeChild(at: 0)
        XCTAssertTrue(root.children.isEmpty)
    }

    func testCallbacksAndSelectionState() {
        let picker = MSUBridge.makeNode(kind: "picker")
        var selected = -1
        picker.setSelectionChangedHandler { selected = $0 }
        picker.selectedIndex = 1
        picker.selectionChangedHandler?(picker.selectedIndex)

        XCTAssertEqual(selected, 1)
        XCTAssertEqual(picker.selectedIndex, 1)
    }

    func testButtonInvokesRegisteredAction() {
        let button = MSUBridge.makeNode(kind: "button")
        var taps = 0
        button.setTapHandler { taps += 1 }
        button.invokeAction()
        XCTAssertEqual(taps, 1)
        button.clearHandlers()
        button.invokeAction()
        XCTAssertEqual(taps, 1)
    }

    func testSliderHasSemanticAccessibilityLabel() {
        let slider = MSUBridge.makeNode(kind: "slider")
        slider.accessibilityLabelText = "Practice level"
        XCTAssertEqual(slider.accessibilityLabelText, "Practice level")
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        XCTAssertNotNil(MSUBridge.hostView(forRoot: slider))
        #endif
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testAppKitHostCreatesViewAndController() {
        let root = MSUBridge.makeNode(kind: "text")
        root.text = "Hosted"
        XCTAssertNotNil(MSUBridge.hostView(forRoot: root))
        XCTAssertNotNil(MSUBridge.hostController(forRoot: root))
    }

    @MainActor
    func testDeactivatedHostCannotRedisplayTheOldRoot() {
        let root = MSUBridge.makeNode(kind: "button")
        guard let view = MSUBridge.hostView(forRoot: root) as? NSHostingView<SwiftUINodeView>,
              let controller = MSUBridge.hostController(forRoot: root) as? NSHostingController<SwiftUINodeView>
        else {
            XCTFail("Expected the native SwiftUI hosting types")
            return
        }

        XCTAssertTrue(MSUBridge.deactivateHost(view))
        XCTAssertTrue(MSUBridge.deactivateHost(controller))
        XCTAssertFalse(view.rootView.node === root)
        XCTAssertFalse(controller.rootView.node === root)
        XCTAssertEqual(view.rootView.node.kind, "text")
        XCTAssertEqual(controller.rootView.node.kind, "text")
        XCTAssertFalse(MSUBridge.deactivateHost(NSView()))
    }
    #endif
}
