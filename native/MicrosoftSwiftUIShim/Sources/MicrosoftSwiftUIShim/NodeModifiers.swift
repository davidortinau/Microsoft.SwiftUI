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
        targeted(doubleTapped(spoken(content)))
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
