import Combine
import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class AdaptiveTabsTests: XCTestCase {
    @MainActor
    private func tab(_ title: String, _ symbol: String) -> MSUNode {
        let tab = MSUBridge.makeNode(kind: "tab")
        tab.text = title
        tab.imageName = symbol
        tab.insertChild(MSUBridge.makeNode(kind: "navigationStack"), at: 0)
        return tab
    }

    @MainActor
    func testPlainTabViewKeepsTheTabItemRendering() {
        let tabs = MSUBridge.makeNode(kind: "tabView")
        let study = tab("Study", "graduationcap")
        tabs.insertChild(study, at: 0)
        XCTAssertEqual(study.tabRole, "")
        XCTAssertFalse(study.tabHidden)
        XCTAssertFalse(study.hasTabHiddenState)
        XCTAssertEqual(tabs.tabViewStyle, "")
        XCTAssertFalse(tabs.usesAdaptiveTabs)
        _ = SwiftUINodeView(node: tabs).body
    }

    @MainActor
    func testRoleHiddenStateOrStyleSelectsTheTabAPI() {
        let roleTabs = MSUBridge.makeNode(kind: "tabView")
        let sam = tab("Sam", "bubble.left.and.bubble.right.fill")
        sam.tabRole = "search"
        roleTabs.insertChild(tab("Study", "graduationcap"), at: 0)
        roleTabs.insertChild(sam, at: 1)
        XCTAssertTrue(roleTabs.usesAdaptiveTabs)
        _ = SwiftUINodeView(node: roleTabs).body

        let hiddenTabs = MSUBridge.makeNode(kind: "tabView")
        let hidden = tab("Sam", "bubble.left.and.bubble.right.fill")
        hidden.tabHidden = false
        XCTAssertTrue(hidden.hasTabHiddenState)
        hiddenTabs.insertChild(hidden, at: 0)
        XCTAssertTrue(hiddenTabs.usesAdaptiveTabs)

        let styled = MSUBridge.makeNode(kind: "tabView")
        styled.insertChild(tab("Study", "graduationcap"), at: 0)
        styled.tabViewStyle = "sidebarAdaptable"
        XCTAssertTrue(styled.usesAdaptiveTabs)
        _ = SwiftUINodeView(node: styled).body
    }

    @MainActor
    func testTabViewRedrawsWhenATabChangesAndForgetsRemovedTabs() {
        let tabs = MSUBridge.makeNode(kind: "tabView")
        let study = tab("Study", "graduationcap")
        let sam = tab("Sam", "bubble.left.and.bubble.right.fill")
        sam.tabRole = "search"
        tabs.insertChild(study, at: 0)
        tabs.insertChild(sam, at: 1)
        var changes = 0
        let observation = tabs.objectWillChange.sink { changes += 1 }

        sam.tabHidden = true
        XCTAssertEqual(changes, 1)
        study.text = "Learn"
        XCTAssertEqual(changes, 2)

        tabs.removeChild(at: 1)
        XCTAssertEqual(changes, 3)
        sam.tabHidden = false
        XCTAssertEqual(changes, 3)

        tabs.clearChildren()
        let afterClear = changes
        study.text = "Study"
        XCTAssertEqual(changes, afterClear)
        observation.cancel()
    }

    @MainActor
    func testOnlyATabViewForwardsChildChanges() {
        let stack = MSUBridge.makeNode(kind: "vstack")
        let text = MSUBridge.makeNode(kind: "text")
        stack.insertChild(text, at: 0)
        var changes = 0
        let observation = stack.objectWillChange.sink { changes += 1 }
        text.text = "Changed"
        XCTAssertEqual(changes, 0)
        observation.cancel()
    }
}
