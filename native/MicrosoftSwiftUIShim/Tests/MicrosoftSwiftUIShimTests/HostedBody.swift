import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Builds a view the way an app does: installed in a hosting controller and measured once.
///
/// A test that only needs to know a node's body can be built used to call
/// `SwiftUINodeView(node:).body` directly. Outside a hosted view SwiftUI answers every
/// `@Environment` read with the default and warns ("Accessing Environment's value outside of
/// being installed on a View"); a passing run printed 54 such lines, which hid any new one.
/// Hosted, the environment is real, nothing is printed, and the children's bodies are built as
/// well, which the direct call never did.
///
/// XCTest runs these on the main thread; `assumeIsolated` traps if that ever stops being true.
func buildHosted(_ view: some View) {
    MainActor.assumeIsolated {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        _ = NSHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: 400, height: 800))
        #else
        // These tests run on macOS (`swift test`). Anywhere else the body is built as it was
        // before this helper, which is all the callers need there.
        _ = view.body
        #endif
    }
}

/// For a tab view, which has to be in a window: asked what it fits in with none, AppKit's tab
/// view answers "Invalid view geometry: width is negative". The window is never shown.
/// A window lays its content out, so geometry callbacks fire as they do in an app; a test that
/// counts those uses `buildHosted(_:)`.
func buildHostedInWindow(_ view: some View) {
    MainActor.assumeIsolated {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 800),
                              styleMask: [.titled], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        window.layoutIfNeeded()
        #else
        _ = view.body
        #endif
    }
}

/// The node's own view, in a window. See `buildHostedInWindow(_:)`.
func buildHostedInWindow(_ node: MSUNode) {
    buildHostedInWindow(SwiftUINodeView(node: node))
}

/// The node's own view, hosted. See `buildHosted(_:)`.
func buildHosted(_ node: MSUNode) {
    buildHosted(SwiftUINodeView(node: node))
}

/// The helper replaces a direct `body` call, so it has to run the body, and with an
/// environment that is the host's and not the default.
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
final class HostedBodyTests: XCTestCase {
    private struct Probe: View {
        @Environment(\.msuBodyTextScale) private var scale
        let seen: (CGFloat) -> Void

        var body: some View {
            seen(scale)
            return Text("Probe")
        }
    }

    func testAHostedViewRunsItsBodyWithTheEnvironmentItWasGiven() {
        var scales: [CGFloat] = []
        buildHosted(Probe { scales.append($0) }.environment(\.msuBodyTextScale, 1.75))
        XCTAssertFalse(scales.isEmpty, "Hosting did not run the body.")
        XCTAssertEqual(scales.last, 1.75)
    }

    func testAViewInAWindowRunsItsBodyWithTheEnvironmentItWasGiven() {
        var scales: [CGFloat] = []
        buildHostedInWindow(Probe { scales.append($0) }.environment(\.msuBodyTextScale, 1.75))
        XCTAssertFalse(scales.isEmpty, "Hosting in a window did not run the body.")
        XCTAssertEqual(scales.last, 1.75)
    }

    func testBuildingAHostedNodeDoesNotChangeIt() {
        let child = MSUBridge.makeNode(kind: "text")
        child.text = "Child"
        let stack = MSUBridge.makeNode(kind: "vstack")
        stack.insertChild(child, at: 0)
        var changes = 0
        let observation = child.objectWillChange.sink { changes += 1 }
        buildHosted(stack)
        XCTAssertEqual(changes, 0, "Building a hosted node must not change it.")
        observation.cancel()
    }
}
#endif
