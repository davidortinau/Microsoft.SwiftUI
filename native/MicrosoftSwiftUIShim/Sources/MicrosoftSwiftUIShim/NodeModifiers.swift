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
        hiddenInPlace(reportingAccessibility(reportingKeyboard(
            announced(targeted(transformed(dragged(doubleTapped(spoken(content)))))))))
    }

    @ViewBuilder
    private func hiddenInPlace<V: View>(_ view: V) -> some View {
        if node.hasHiddenState {
            view.modifier(HiddenInPlaceModifier(node: node))
        } else {
            view
        }
    }

    @ViewBuilder
    private func reportingKeyboard<V: View>(_ view: V) -> some View {
        if node.keyboardOverlapChangedHandler == nil {
            view
        } else {
            view.modifier(KeyboardOverlapReporter(node: node))
        }
    }

    @ViewBuilder
    private func reportingAccessibility<V: View>(_ view: V) -> some View {
        if node.accessibilitySettingsChangedHandler == nil {
            view
        } else {
            view.modifier(AccessibilitySettingsReporter(node: node))
        }
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

/// A Scroll's vertical geometry in points: the raw content offset (negative
/// the top inset at the start), content and container heights, and the
/// content insets SwiftUI applies (safe area and margins).
struct MSUScrollMetrics: Equatable {
    var offsetY: Double
    var contentHeight: Double
    var containerHeight: Double
    var insetTop: Double
    var insetBottom: Double

    init(offsetY: Double, contentHeight: Double, containerHeight: Double,
         insetTop: Double, insetBottom: Double) {
        self.offsetY = offsetY
        self.contentHeight = contentHeight
        self.containerHeight = containerHeight
        self.insetTop = insetTop
        self.insetBottom = insetBottom
    }

    @available(iOS 18.0, macOS 15.0, *)
    init(_ geometry: ScrollGeometry) {
        self.init(offsetY: Double(geometry.contentOffset.y),
                  contentHeight: Double(geometry.contentSize.height),
                  containerHeight: Double(geometry.containerSize.height),
                  insetTop: Double(geometry.contentInsets.top),
                  insetBottom: Double(geometry.contentInsets.bottom))
    }

    var isFinite: Bool {
        offsetY.isFinite && contentHeight.isFinite && containerHeight.isFinite
            && insetTop.isFinite && insetBottom.isFinite
    }

    /// True when any value moved by at least `points`.
    func differs(from other: MSUScrollMetrics, by points: Double) -> Bool {
        abs(offsetY - other.offsetY) >= points
            || abs(contentHeight - other.contentHeight) >= points
            || abs(containerHeight - other.containerHeight) >= points
            || abs(insetTop - other.insetTop) >= points
            || abs(insetBottom - other.insetBottom) >= points
    }
}

/// Reports a Scroll's geometry (SwiftUI onScrollGeometryChange, iOS 18 and
/// macOS 15 or later) while the node has a handler; the node drops changes
/// under a point.
struct ScrollGeometryReporter: ViewModifier {
    @ObservedObject var node: MSUNode

    @ViewBuilder
    func body(content: Content) -> some View {
        if node.scrollGeometryChangedHandler == nil {
            content
        } else if #available(iOS 18.0, macOS 15.0, *) {
            content.onScrollGeometryChange(for: MSUScrollMetrics.self) { geometry in
                MSUScrollMetrics(geometry)
            } action: { _, metrics in
                node.reportScrollGeometry(metrics)
            }
        } else {
            content
        }
    }
}

/// Whether a hidden view also slides: "slideDown" does, unless Reduce Motion is on.
func msuHideSlides(transition: String, reduceMotion: Bool) -> Bool {
    transition == "slideDown" && !reduceMotion
}

/// SwiftUI `hidden()` semantics with an animated change: the view keeps its
/// layout space, cannot be hit and is hidden from accessibility while hidden.
/// It fades; "slideDown" also moves it down by its own height (a visual
/// effect, so layout never changes), and with Reduce Motion it only fades.
struct HiddenInPlaceModifier: ViewModifier {
    @ObservedObject var node: MSUNode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let hidden = node.hiddenInPlace
        let slides = msuHideSlides(transition: node.hiddenTransition, reduceMotion: reduceMotion)
        content
            .opacity(hidden ? 0 : 1)
            .visualEffect { effect, proxy in
                effect.offset(y: hidden && slides ? proxy.size.height : 0)
            }
            .animation(.easeInOut(duration: node.hiddenAnimationDuration), value: hidden)
            .allowsHitTesting(!hidden)
            .accessibilityHidden(hidden)
    }
}

/// The bottom of a proxy's safe area in global coordinates.
func msuSafeAreaBottom(_ proxy: GeometryProxy) -> Double {
    Double(proxy.frame(in: .global).maxY - proxy.safeAreaInsets.bottom)
}

/// How far the on-screen keyboard reaches into a view, from SwiftUI's safe
/// area alone: one reader respects the keyboard region, a second ignores it,
/// and the gap between their safe-area bottoms is the keyboard. No keyboard,
/// a hardware keyboard or a floating keyboard leaves no gap.
struct KeyboardOverlapReporter: ViewModifier {
    @ObservedObject var node: MSUNode
    @State private var withKeyboard: Double?
    @State private var withoutKeyboard: Double?

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: msuSafeAreaBottom(proxy), initial: true) { _, bottom in
                            withKeyboard = bottom
                            report(with: bottom, without: withoutKeyboard)
                        }
                }
                .accessibilityHidden(true)
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: msuSafeAreaBottom(proxy), initial: true) { _, bottom in
                            withoutKeyboard = bottom
                            report(with: withKeyboard, without: bottom)
                        }
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .accessibilityHidden(true)
            }
    }

    private func report(with: Double?, without: Double?) {
        guard let with, let without else { return }
        node.reportKeyboardOverlap(max(0, without - with))
    }
}

/// Reports VoiceOver and Reduce Motion (SwiftUI accessibility environment)
/// when the view appears and whenever either changes.
struct AccessibilitySettingsReporter: ViewModifier {
    @ObservedObject var node: MSUNode
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onChange(of: voiceOver, initial: true) { _, enabled in
                node.reportAccessibilitySettings(voiceOver: enabled, reduceMotion: reduceMotion)
            }
            .onChange(of: reduceMotion) { _, enabled in
                node.reportAccessibilitySettings(voiceOver: voiceOver, reduceMotion: enabled)
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
