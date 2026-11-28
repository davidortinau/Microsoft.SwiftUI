import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class SearchTokensTests: XCTestCase {
    @MainActor
    func testSearchableRendersWithAndWithoutTokens() {
        let search = MSUBridge.makeNode(kind: "searchable")
        search.insertChild(MSUBridge.makeNode(kind: "vstack"), at: 0)
        XCTAssertEqual(search.searchTokenIds, [])
        buildHosted(search)
        search.searchTokenTitles = ["Korean", "Video"]
        search.searchTokenIds = ["language", "type"]
        search.focusRequested = true
        buildHosted(search)
        XCTAssertEqual(search.searchTokenIds, ["language", "type"])
        search.searchPlacement = "bottomBar"
        search.searchKeepsToolbar = true
        buildHosted(search)
        let titled = MSUBridge.makeNode(kind: "vstack")
        titled.navigationTitle = "Resources"
        titled.navigationSubtitle = "92 resources"
        buildHosted(titled)
    }
}
