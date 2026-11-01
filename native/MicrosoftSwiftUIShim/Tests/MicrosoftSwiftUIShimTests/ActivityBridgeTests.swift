import Combine
import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import MicrosoftSwiftUIShim

/// Speech language, double tap, scroll-to-target, photo picker and YouTube
/// player additions (0.1.0-preview.32). Each is opt-in: nodes that never set
/// them keep their existing rendering.
final class ActivityBridgeTests: XCTestCase {
    @MainActor
    func testSpeechLanguageDefaultsEmptyAndTagsTheSpokenText() {
        let word = MSUBridge.makeNode(kind: "text")
        word.text = "학교"
        XCTAssertEqual(word.speechLanguage, "")
        _ = SwiftUINodeView(node: word).body

        var changes = 0
        let observation = word.objectWillChange.sink { changes += 1 }
        word.speechLanguage = "ko-KR"
        XCTAssertEqual(changes, 1)
        _ = SwiftUINodeView(node: word).body
        observation.cancel()

        let attributed = msuSpeechAttributedString("학교", language: "ko-KR")
        XCTAssertEqual(String(attributed.characters), "학교")
        XCTAssertEqual(attributed.languageIdentifier, "ko-KR")
        XCTAssertEqual(attributed[MSUSpeechLanguageAttribute.self], "ko-KR")
        XCTAssertEqual(MSUSpeechLanguageAttribute.name, "accessibilitySpeechLanguage",
                       "Must match UIAccessibilitySpeechAttributeLanguage.")
        let plain = msuSpeechAttributedString("school", language: "")
        XCTAssertNil(plain.languageIdentifier)
        XCTAssertNil(plain[MSUSpeechLanguageAttribute.self])

        let button = MSUBridge.makeNode(kind: "button")
        button.accessibilityLabelText = "학교, In your vocab"
        button.speechLanguage = "ko-KR"
        _ = SwiftUINodeView(node: button).body
    }

    @MainActor
    func testDoubleTapIsOptInRespectsDisabledAndClearsWithHandlers() {
        let button = MSUBridge.makeNode(kind: "button")
        var taps = 0
        var doubleTaps = 0
        button.setTapHandler { taps += 1 }
        _ = SwiftUINodeView(node: button).body
        XCTAssertNil(button.doubleTapHandler)

        var changes = 0
        let observation = button.objectWillChange.sink { changes += 1 }
        button.setDoubleTapHandler { doubleTaps += 1 }
        XCTAssertEqual(changes, 1, "Attaching the gesture must re-render the node.")
        button.doubleTapActionName = "Play from here"
        _ = SwiftUINodeView(node: button).body
        observation.cancel()

        button.invokeDoubleTap()
        XCTAssertEqual(doubleTaps, 1)
        button.invokeAction()
        XCTAssertEqual(taps, 1, "The single-tap action stays independent of the double tap.")
        button.isEnabled = false
        button.invokeDoubleTap()
        XCTAssertEqual(doubleTaps, 1)
        button.isEnabled = true
        button.clearHandlers()
        button.invokeDoubleTap()
        XCTAssertEqual(doubleTaps, 1)
    }

    @MainActor
    func testScrollToRequestsAreOptInCountedAndValidated() {
        let scroll = MSUBridge.makeNode(kind: "scroll")
        let target = MSUBridge.makeNode(kind: "text")
        target.automationId = "sentence.3"
        scroll.insertChild(target, at: 0)
        XCTAssertFalse(scroll.scrollTargetsEnabled)
        XCTAssertEqual(scroll.scrollRequest, 0)
        _ = SwiftUINodeView(node: scroll).body

        var changes = 0
        let observation = scroll.objectWillChange.sink { changes += 1 }
        scroll.requestScroll(to: "sentence.3", anchor: "center", animated: true)
        XCTAssertTrue(scroll.scrollTargetsEnabled)
        XCTAssertEqual(scroll.scrollTargetId, "sentence.3")
        XCTAssertEqual(scroll.scrollTargetAnchor, "center")
        XCTAssertEqual(scroll.scrollRequest, 1)
        scroll.requestScroll(to: "sentence.3", anchor: "top", animated: false)
        XCTAssertEqual(scroll.scrollRequest, 2, "Repeating a target is a new request.")
        XCTAssertFalse(scroll.scrollTargetAnimated)
        XCTAssertGreaterThanOrEqual(changes, 2)
        observation.cancel()
        _ = SwiftUINodeView(node: scroll).body
        XCTAssertEqual(scroll.children.map(\.id), [target.id])

        let list = MSUBridge.makeNode(kind: "list")
        list.requestScroll(to: "row.1", anchor: "bottom", animated: true)
        _ = SwiftUINodeView(node: list).body
        XCTAssertEqual(msuScrollAnchor("top"), .top)
        XCTAssertEqual(msuScrollAnchor("bottom"), .bottom)
        XCTAssertEqual(msuScrollAnchor("center"), .center)
    }

    @MainActor
    func testPhotoPickerReportsPickedBytesErrorsAndCancellationOnce() {
        let picker = MSUBridge.makeNode(kind: "photoPicker")
        picker.insertChild(MSUBridge.makeNode(kind: "button"), at: 0)
        var picked: [(Data, String, String)] = []
        var errors: [String] = []
        var cancelled = 0
        picker.setPhotoPickedHandler { picked.append(($0, $1, $2)) }
        picker.setPhotoPickErrorHandler { errors.append($0) }
        picker.setPhotoPickCancelledHandler { cancelled += 1 }
        _ = SwiftUINodeView(node: picker).body

        let bytes = Data([0xFF, 0xD8, 0xFF, 0xE0])
        picker.completePhotoPick(data: bytes, type: .jpeg)
        XCTAssertEqual(picked.count, 1)
        XCTAssertEqual(picked.first?.0, bytes)
        XCTAssertEqual(picked.first?.1, "image/jpeg")
        XCTAssertEqual(picked.first?.2, "public.jpeg")
        picker.completePhotoPick(data: nil, type: .png)
        picker.completePhotoPick(data: Data(count: MSUNode.maximumPickedPhotoBytes + 1), type: .png)
        XCTAssertEqual(errors, ["loadFailed", "tooLarge"])
        XCTAssertFalse(picker.photoPickPending)

        picker.isPresented = true
        picker.applyPhotoPickerPresentation(false)
        XCTAssertFalse(picker.isPresented)
        let closed = expectation(description: "cancellation reported on the next turn")
        DispatchQueue.main.async { closed.fulfill() }
        wait(for: [closed], timeout: 1)
        XCTAssertEqual(cancelled, 1)
        picker.applyPhotoPickerPresentation(false)
        let idle = expectation(description: "closing a closed picker is not a cancellation")
        DispatchQueue.main.async { idle.fulfill() }
        wait(for: [idle], timeout: 1)
        XCTAssertEqual(cancelled, 1)
    }

    func testYouTubeEmbedAcceptsOnlyVideoIdsAndKeepsTheMainFrameOnTheEmbed() {
        XCTAssertTrue(msuIsYouTubeVideoId("dQw4w9WgXcQ"))
        XCTAssertTrue(msuIsYouTubeVideoId("a-_0123456Z"))
        for invalid in ["", "dQw4w9WgXc", "dQw4w9WgXcQQ", "dQw4w9WgX/Q", "dQw4w9WgX Q",
                        "https://evil", "dQw4w9WgXc\u{00E9}", "../../etc/p"] {
            XCTAssertFalse(msuIsYouTubeVideoId(invalid), invalid)
            XCTAssertNil(msuYouTubeEmbedURL(invalid), invalid)
        }
        let url = msuYouTubeEmbedURL("dQw4w9WgXcQ")
        XCTAssertEqual(url?.absoluteString,
                       "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ?playsinline=1&rel=0")

        let id = "dQw4w9WgXcQ"
        XCTAssertTrue(msuYouTubeAllowsNavigation(to: url, isMainFrame: true, videoId: id))
        for denied in ["https://www.youtube.com/watch?v=dQw4w9WgXcQ",
                       "https://www.youtube-nocookie.com/embed/otherVideo1",
                       "http://www.youtube-nocookie.com/embed/dQw4w9WgXcQ",
                       "https://evil.example/embed/dQw4w9WgXcQ",
                       "https://www.youtube-nocookie.com.evil.example/embed/dQw4w9WgXcQ",
                       "about:blank"] {
            XCTAssertFalse(msuYouTubeAllowsNavigation(to: URL(string: denied), isMainFrame: true,
                                                      videoId: id), denied)
        }
        XCTAssertFalse(msuYouTubeAllowsNavigation(to: url, isMainFrame: true, videoId: "bad"))
        XCTAssertTrue(msuYouTubeAllowsNavigation(
            to: URL(string: "https://www.youtube.com/embed/x"), isMainFrame: false, videoId: id))
        XCTAssertTrue(msuYouTubeAllowsNavigation(
            to: URL(string: "about:blank"), isMainFrame: false, videoId: id))
        XCTAssertFalse(msuYouTubeAllowsNavigation(
            to: URL(string: "https://notyoutube.com/x"), isMainFrame: false, videoId: id))
        XCTAssertFalse(msuYouTubeAllowsNavigation(
            to: URL(string: "javascript:alert(1)"), isMainFrame: false, videoId: id))
        XCTAssertFalse(msuYouTubeAllowsNavigation(to: nil, isMainFrame: false, videoId: id))
    }

    @MainActor
    func testYouTubePlayerNodeRendersOnlyWithAValidId() {
        let player = MSUBridge.makeNode(kind: "youTubePlayer")
        _ = SwiftUINodeView(node: player).body
        player.videoId = "dQw4w9WgXcQ"
        player.accessibilityLabelText = "Lesson video"
        _ = SwiftUINodeView(node: player).body
        XCTAssertEqual(player.videoId, "dQw4w9WgXcQ")
        let coordinator = MSUYouTubeCoordinator()
        XCTAssertEqual(coordinator.videoId, "")
    }
}
