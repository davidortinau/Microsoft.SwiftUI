import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

/// Hide on scroll (0.1.0-preview.37): a Scroll reports its geometry, a view
/// reports the keyboard overlap and the accessibility settings, and a view can
/// hide in place (keeps its space, slides and fades, or only fades with Reduce Motion).
final class HideOnScrollTests: XCTestCase {
    @MainActor
    func testHiddenInPlaceDefaultsOffAndPublishesOnce() {
        let node = MSUBridge.makeNode(kind: "hstack")
        XCTAssertFalse(node.hasHiddenState)
        XCTAssertFalse(node.hiddenInPlace)
        XCTAssertEqual(node.hiddenTransition, "fade")
        XCTAssertEqual(node.hiddenAnimationDuration, 0.2)
        _ = SwiftUINodeView(node: node).body
        var changes = 0
        let observation = node.objectWillChange.sink { changes += 1 }
        node.setHidden(true, transition: "slideDown", duration: 0.25)
        XCTAssertEqual(changes, 1)
        observation.cancel()
        XCTAssertTrue(node.hasHiddenState)
        XCTAssertTrue(node.hiddenInPlace)
        XCTAssertEqual(node.hiddenTransition, "slideDown")
        XCTAssertEqual(node.hiddenAnimationDuration, 0.25)
        _ = SwiftUINodeView(node: node).body
        node.setHidden(false, transition: "slideDown", duration: 0.25)
        XCTAssertTrue(node.hasHiddenState)
        XCTAssertFalse(node.hiddenInPlace)
    }

    func testOnlySlideDownSlidesAndReduceMotionOnlyFades() {
        XCTAssertTrue(msuHideSlides(transition: "slideDown", reduceMotion: false))
        XCTAssertFalse(msuHideSlides(transition: "slideDown", reduceMotion: true))
        XCTAssertFalse(msuHideSlides(transition: "fade", reduceMotion: false))
        XCTAssertFalse(msuHideSlides(transition: "fade", reduceMotion: true))
    }

    @MainActor
    func testScrollGeometryReportsOnlyChangesOfAPointOrMore() {
        let scroll = MSUBridge.makeNode(kind: "scroll")
        scroll.reportScrollGeometry(offsetY: 0, contentHeight: 900, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        var reports: [[Double]] = []
        var changes = 0
        let observation = scroll.objectWillChange.sink { changes += 1 }
        scroll.setScrollGeometryChangedHandler { offset, content, container, top, bottom in
            reports.append([offset, content, container, top, bottom])
        }
        XCTAssertEqual(changes, 1, "Attaching the reporter re-renders the scroll")
        observation.cancel()
        _ = SwiftUINodeView(node: scroll).body

        scroll.reportScrollGeometry(offsetY: -100, contentHeight: 900, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        scroll.reportScrollGeometry(offsetY: -99.4, contentHeight: 900, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        scroll.reportScrollGeometry(offsetY: -99, contentHeight: 900, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        scroll.reportScrollGeometry(offsetY: -99, contentHeight: 1200, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        scroll.reportScrollGeometry(offsetY: .nan, contentHeight: 1200, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        XCTAssertEqual(reports, [[-100, 900, 600, 100, 80], [-99, 900, 600, 100, 80],
                                 [-99, 1200, 600, 100, 80]])

        scroll.clearHandlers()
        scroll.reportScrollGeometry(offsetY: 300, contentHeight: 1200, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        XCTAssertEqual(reports.count, 3)
    }

    @MainActor
    func testKeyboardOverlapReportsEdgesAndChangesOfAPointOrMore() {
        let page = MSUBridge.makeNode(kind: "bottomInset")
        var reports: [Double] = []
        page.reportKeyboardOverlap(300)
        page.setKeyboardOverlapChangedHandler { reports.append($0) }
        _ = SwiftUINodeView(node: page).body
        page.reportKeyboardOverlap(0)
        page.reportKeyboardOverlap(0.6)
        page.reportKeyboardOverlap(291)
        page.reportKeyboardOverlap(291.5)
        page.reportKeyboardOverlap(-3)
        page.reportKeyboardOverlap(.infinity)
        XCTAssertEqual(reports, [0, 291, 0])
    }

    @MainActor
    func testAccessibilitySettingsReportFlagsOnceEach() {
        let page = MSUBridge.makeNode(kind: "vstack")
        var reports: [Int] = []
        page.setAccessibilitySettingsChangedHandler { reports.append($0) }
        _ = SwiftUINodeView(node: page).body
        page.reportAccessibilitySettings(voiceOver: false, reduceMotion: false)
        page.reportAccessibilitySettings(voiceOver: false, reduceMotion: false)
        page.reportAccessibilitySettings(voiceOver: true, reduceMotion: false)
        page.reportAccessibilitySettings(voiceOver: true, reduceMotion: true)
        page.reportAccessibilitySettings(voiceOver: false, reduceMotion: true)
        XCTAssertEqual(reports, [0, 1, 3, 2])
        page.clearHandlers()
        page.reportAccessibilitySettings(voiceOver: true, reduceMotion: true)
        XCTAssertEqual(reports.count, 4)
    }

    func testScrollMetricsDiffersOnAnyValue() {
        let base = MSUScrollMetrics(offsetY: 10, contentHeight: 900, containerHeight: 600,
                                    insetTop: 100, insetBottom: 80)
        XCTAssertFalse(base.differs(from: base, by: 1))
        var moved = base
        moved.insetBottom = 81
        XCTAssertTrue(moved.differs(from: base, by: 1))
        moved = base
        moved.containerHeight = 600.5
        XCTAssertFalse(moved.differs(from: base, by: 1))
        XCTAssertFalse(MSUScrollMetrics(offsetY: .nan, contentHeight: 1, containerHeight: 1,
                                        insetTop: 0, insetBottom: 0).isFinite)
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testHiddenViewKeepsItsLayoutSpace() {
        func row(hidden: Bool?) -> MSUNode {
            let text = MSUBridge.makeNode(kind: "text")
            text.text = "Ask Sam"
            text.paddingPoints = 12
            let stack = MSUBridge.makeNode(kind: "hstack")
            stack.insertChild(text, at: 0)
            if let hidden { stack.setHidden(hidden, transition: "slideDown", duration: 0.2) }
            return stack
        }
        func fitting(_ node: MSUNode) -> CGSize {
            let host = NSHostingView(rootView: SwiftUINodeView(node: node))
            host.frame = CGRect(x: 0, y: 0, width: 320, height: 200)
            host.layoutSubtreeIfNeeded()
            return host.fittingSize
        }
        let plain = fitting(row(hidden: nil))
        let shown = fitting(row(hidden: false))
        let hidden = fitting(row(hidden: true))
        XCTAssertEqual(shown.width, plain.width, accuracy: 0.5)
        XCTAssertEqual(shown.height, plain.height, accuracy: 0.5)
        XCTAssertEqual(hidden.width, plain.width, accuracy: 0.5)
        XCTAssertEqual(hidden.height, plain.height, accuracy: 0.5)
    }

    /// The managed SwiftScrollGeometry end (content - container - top inset) relies on
    /// SwiftUI's containerSize excluding both insets; a scroll at its last row proves it.
    @MainActor
    func testScrollGeometryAtTheEndIsContentMinusContainerMinusTopInset() {
        guard #available(macOS 15.0, *) else { return }
        let scroll = MSUBridge.makeNode(kind: "scroll")
        scroll.spacing = 0
        for index in 0..<20 {
            let row = MSUBridge.makeNode(kind: "vstack")
            row.minimumHeight = 100
            row.fillsWidth = true
            row.automationId = "probe.row.\(index)"
            scroll.insertChild(row, at: index)
        }
        let footer = MSUBridge.makeNode(kind: "vstack")
        footer.minimumHeight = 80
        footer.fillsWidth = true
        let page = MSUBridge.makeNode(kind: "bottomInset")
        page.insertChild(scroll, at: 0)
        page.insertChild(footer, at: 1)
        var reports: [MSUScrollMetrics] = []
        scroll.setScrollGeometryChangedHandler { offset, content, container, top, bottom in
            reports.append(MSUScrollMetrics(offsetY: offset, contentHeight: content,
                                            containerHeight: container, insetTop: top,
                                            insetBottom: bottom))
        }
        let host = NSHostingView(rootView: SwiftUINodeView(node: page))
        host.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled],
                              backing: .buffered, defer: false)
        window.contentView = host
        window.orderFront(nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        scroll.requestScroll(to: "probe.row.19", anchor: "bottom", animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        window.orderOut(nil)
        guard let end = reports.last else { return XCTFail("No scroll geometry was reported") }
        XCTAssertEqual(end.contentHeight, 2000, accuracy: 1)
        XCTAssertEqual(end.insetBottom, 80, accuracy: 1)
        XCTAssertEqual(end.containerHeight, 600 - end.insetTop - end.insetBottom, accuracy: 1)
        XCTAssertEqual(end.offsetY, end.contentHeight - end.containerHeight - end.insetTop, accuracy: 1)
    }

    @MainActor
    func testHostedReportersReportOnAppearWithoutAKeyboard() {
        let text = MSUBridge.makeNode(kind: "text")
        text.text = "Row"
        let scroll = MSUBridge.makeNode(kind: "scroll")
        scroll.insertChild(text, at: 0)
        let footer = MSUBridge.makeNode(kind: "hstack")
        footer.setHidden(false, transition: "slideDown", duration: 0.2)
        let page = MSUBridge.makeNode(kind: "bottomInset")
        page.insertChild(scroll, at: 0)
        page.insertChild(footer, at: 1)
        var geometry = 0
        var overlaps: [Double] = []
        var settings: [Int] = []
        scroll.setScrollGeometryChangedHandler { _, _, _, _, _ in geometry += 1 }
        page.setKeyboardOverlapChangedHandler { overlaps.append($0) }
        page.setAccessibilitySettingsChangedHandler { settings.append($0) }
        let host = NSHostingView(rootView: SwiftUINodeView(node: page))
        host.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(overlaps, [0])
        XCTAssertEqual(settings.count, 1)
        XCTAssertEqual((settings.first ?? 1) & 1, 0, "VoiceOver is off under XCTest")
        XCTAssertGreaterThanOrEqual(geometry, 0)
    }
    #endif
}
