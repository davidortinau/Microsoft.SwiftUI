import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class SearchTokensTests: XCTestCase {
    @MainActor
    func testSearchableRendersWithAndWithoutTokens() {
        let search = MSUBridge.makeNode(kind: "searchable")
        search.insertChild(MSUBridge.makeNode(kind: "vstack"), at: 0)
        XCTAssertEqual(search.searchTokenIds, [])
        _ = SwiftUINodeView(node: search).body
        search.searchTokenTitles = ["Korean", "Video"]
        search.searchTokenIds = ["language", "type"]
        search.focusRequested = true
        _ = SwiftUINodeView(node: search).body
        XCTAssertEqual(search.searchTokenIds, ["language", "type"])
    }
}
