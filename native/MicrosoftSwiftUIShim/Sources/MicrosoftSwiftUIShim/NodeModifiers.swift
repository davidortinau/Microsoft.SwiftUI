import Foundation
import SwiftUI

/// The UIAccessibilitySpeechAttributeLanguage attributed-string key
/// ("accessibilitySpeechLanguage"): the language VoiceOver speaks a run in.
/// Foundation's AccessibilityAttributes scope has no Swift name for it.
enum MSUSpeechLanguageAttribute: CodableAttributedStringKey, ObjectiveCConvertibleAttributedStringKey {
    typealias Value = String
    typealias ObjectiveCValue = NSString
    static let name = "accessibilitySpeechLanguage"

    static func objectiveCValue(for value: String) throws -> NSString { value as NSString }
    static func value(for object: NSString) throws -> String { object as String }
}

/// Text whose spoken language is the given BCP 47 tag: the run carries the
/// speech-language and Foundation language-identifier attributes. The node
/// also scopes the environment locale to that language (NodeBehaviorModifier),
/// which SwiftUI uses for the element's accessibility language.
func msuSpeechText(_ string: String, language: String) -> Text {
    guard !language.isEmpty else { return Text(string) }
    return Text(msuSpeechAttributedString(string, language: language))
}

func msuSpeechAttributedString(_ string: String, language: String) -> AttributedString {
    var attributed = AttributedString(string)
    if !language.isEmpty {
        attributed[MSUSpeechLanguageAttribute.self] = language
        attributed.languageIdentifier = language
    }
    return attributed
}

private struct ScrollTargetsEnabledKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var msuScrollTargetsEnabled: Bool {
        get { self[ScrollTargetsEnabledKey.self] }
        set { self[ScrollTargetsEnabledKey.self] = newValue }
    }
}

func msuScrollAnchor(_ name: String) -> UnitPoint {
    switch name {
    case "top": .top
    case "bottom": .bottom
    default: .center
    }
}

/// Wraps a Scroll or List in a ScrollViewReader once the node has asked to
/// scroll to a target; other scrolls render unchanged.
struct ScrollTargetReader<Content: View>: View {
    @ObservedObject var node: MSUNode
    @ViewBuilder let content: () -> Content

    @ViewBuilder
    var body: some View {
        if node.scrollTargetsEnabled {
            ScrollViewReader { proxy in
                content()
                    .environment(\.msuScrollTargetsEnabled, true)
                    .onAppear { scroll(proxy, animated: false) }
                    .onChange(of: node.scrollRequest) { _, _ in
                        scroll(proxy, animated: node.scrollTargetAnimated)
                    }
            }
        } else {
            content()
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, animated: Bool) {
        let target = node.scrollTargetId
        guard !target.isEmpty else { return }
        let anchor = msuScrollAnchor(node.scrollTargetAnchor)
        // Let the update that introduced the target lay out first.
        DispatchQueue.main.async {
            if animated {
                withAnimation(.easeInOut) { proxy.scrollTo(target, anchor: anchor) }
            } else {
                proxy.scrollTo(target, anchor: anchor)
            }
        }
    }
}

/// Node behaviors added after the original modifier chain: a spoken-language
/// accessibility label, a double tap that takes priority over the view's own
/// tap (a Button's single-tap action runs once a double tap is ruled out, so
/// the first tap cannot present UI that swallows the second) and, inside a Scroll or List that scrolls to
/// targets, the automation id as the identity ScrollViewProxy.scrollTo finds.
/// Each applies only when its node property is set.
struct NodeBehaviorModifier: ViewModifier {
    @ObservedObject var node: MSUNode
    let scrollTargetsEnabled: Bool
    let ownsAccessibilityLabel: Bool

    func body(content: Content) -> some View {
        announced(targeted(transformed(dragged(doubleTapped(spoken(content))))))
    }

    /// Posts the opt-in announcement once when the view appears and again when
    /// its text changes; an empty text posts nothing (SwiftUI AccessibilityNotification).
    @ViewBuilder
    private func announced<V: View>(_ view: V) -> some View {
        if node.accessibilityAnnouncement.isEmpty {
            view
        } else {
            view.onAppear { msuPostAnnouncement(node.accessibilityAnnouncement) }
                .onChange(of: node.accessibilityAnnouncement) { _, text in
                    msuPostAnnouncement(text)
                }
        }
    }

    @ViewBuilder
    private func dragged<V: View>(_ view: V) -> some View {
        if node.hasHorizontalDrag {
            view.modifier(HorizontalDragModifier(node: node))
        } else {
            view
        }
    }

    /// Offset and rotation scoped to these two modifiers: a spring when the
    /// latest change asked for animation, otherwise immediate (finger tracking).
    @ViewBuilder
    private func transformed<V: View>(_ view: V) -> some View {
        if node.hasTransform {
            view.animation(node.transformAnimated ? .spring(response: 0.32, dampingFraction: 0.72) : nil) {
                $0.offset(x: node.offsetX, y: node.offsetY)
                    .rotationEffect(.degrees(node.rotationDegrees))
            }
        } else {
            view
        }
    }

    @ViewBuilder
    private func spoken<V: View>(_ view: V) -> some View {
        if node.speechLanguage.isEmpty {
            view
        } else {
            labeled(view).environment(\.locale, Locale(identifier: node.speechLanguage))
        }
    }

    @ViewBuilder
    private func labeled<V: View>(_ view: V) -> some View {
        if node.accessibilityLabelText.isEmpty || ownsAccessibilityLabel {
            view
        } else {
            view.accessibilityLabel(msuSpeechText(node.accessibilityLabelText,
                                                  language: node.speechLanguage))
        }
    }

    @ViewBuilder
    private func doubleTapped<V: View>(_ view: V) -> some View {
        if node.doubleTapHandler == nil {
            view
        } else if node.doubleTapActionName.isEmpty {
            view.highPriorityGesture(TapGesture(count: 2).onEnded { node.invokeDoubleTap() })
        } else {
            view.highPriorityGesture(TapGesture(count: 2).onEnded { node.invokeDoubleTap() })
                .accessibilityAction(named: Text(node.doubleTapActionName)) { node.invokeDoubleTap() }
        }
    }

    @ViewBuilder
    private func targeted<V: View>(_ view: V) -> some View {
        if scrollTargetsEnabled && !node.automationId.isEmpty {
            view.id(node.automationId)
        } else {
            view
        }
    }
}

/// A horizontal DragGesture with high priority over the view's own tap: a
/// touch that moves less than the minimum distance stays a tap (a Button's
/// action or a double tap), a longer one becomes the drag. Translations are
/// measured in the global space so the view's own offset or rotation does not
/// feed back into them. A drag the system cancels (no onEnded) is reported
/// once its gesture state resets.
struct HorizontalDragModifier: ViewModifier {
    @ObservedObject var node: MSUNode
    @GestureState private var isDragging = false

    func body(content: Content) -> some View {
        content.highPriorityGesture(
            DragGesture(minimumDistance: max(0, node.horizontalDragMinimumDistance),
                        coordinateSpace: .global)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged { node.reportHorizontalDragChanged($0.translation.width) }
                .onEnded {
                    node.reportHorizontalDragEnded($0.translation.width,
                                                   predicted: $0.predictedEndTranslation.width)
                },
            including: node.isEnabled ? .all : .subviews)
            .onChange(of: isDragging) { _, dragging in
                guard !dragging else { return }
                // onEnded, when it runs, runs in the same turn; only a cancelled drag is still active.
                DispatchQueue.main.async { node.reportHorizontalDragCancelled() }
            }
    }
}

/// Announcements posted through `msuPostAnnouncement`, newest last (tests read it).
@MainActor var msuPostedAnnouncements: [String] = []

@MainActor func msuPostAnnouncement(_ text: String) {
    guard !text.isEmpty else { return }
    msuPostedAnnouncements.append(text)
    AccessibilityNotification.Announcement(text).post()
}
