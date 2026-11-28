import SwiftUI
import XCTest
@testable import MicrosoftSwiftUIShim

final class ListRowBackgroundTests: XCTestCase {
    @MainActor
    func testRowBackgroundIsOffByDefaultAndRendersWhenHidden() {
        let form = MSUBridge.makeNode(kind: "form")
        let section = MSUBridge.makeNode(kind: "section")
        let header = MSUBridge.makeNode(kind: "text")
        header.text = "SentenceStudio"
        XCTAssertFalse(header.listRowBackgroundHidden)
        header.listRowBackgroundHidden = true
        section.insertChild(header, at: 0)
        form.insertChild(section, at: 0)
        buildHosted(form)
        buildHosted(header)
        XCTAssertTrue(header.listRowBackgroundHidden)
    }
}
