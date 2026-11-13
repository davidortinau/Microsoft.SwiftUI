import Combine
import Foundation
import ImageIO
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

@objc(MSUNode)
public final class MSUNode: NSObject, ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    public let id = UUID()

    @objc public let kind: String
    @objc public var text = "" { willSet { objectWillChange.send() } }
    @objc public var lineLimit = 0 { willSet { objectWillChange.send() } }
    @objc public var placeholder = "" { willSet { objectWillChange.send() } }
    @objc public var hidesTextEditorScrollBackground = false { willSet { objectWillChange.send() } }
    var showsTextEditorPlaceholder: Bool {
        kind == "textEditor" && text.isEmpty && !placeholder.isEmpty
    }
    @objc public var imageName = "" { willSet { objectWillChange.send() } }
    @objc public var fixedSymbolSize = 0.0 { willSet { objectWillChange.send() } }
    @objc public var photoData: NSData? { didSet { decodePhoto() } }
    @objc public private(set) var photoStatus = "loading" { willSet { objectWillChange.send() } }
    @objc public var photoMaxHeight = 0.0 { willSet { objectWillChange.send() } }
    @objc public var automationId = "" { willSet { objectWillChange.send() } }
    @objc public var quickAddAnchorId = "" { willSet { objectWillChange.send() } }
    @objc public var accessibilityLabelText = "" { willSet { objectWillChange.send() } }
    @objc public var accessibilitySelected = false { willSet { objectWillChange.send() } }
    @objc public var isOn = false { willSet { objectWillChange.send() } }
    @objc public var isPresented = false { willSet { objectWillChange.send() } }
    @objc public var deletePending = false { willSet { objectWillChange.send() } }
    @objc public var transparentDeleteBackdrop = false { willSet { objectWillChange.send() } }
    @objc public var deleteCloseLabel = "" { willSet { objectWillChange.send() } }
    @objc public var deleteCancelLabel = "" { willSet { objectWillChange.send() } }
    @objc public var deleteConfirmLabel = "" { willSet { objectWillChange.send() } }
    @objc public var sheetDetentFraction = 0.0 { willSet { objectWillChange.send() } }
    @objc public var inspectorMinWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var inspectorIdealWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var inspectorMaxWidth = 0.0 { willSet { objectWillChange.send() } }
    /// Split view (`NavigationSplitView`) column visibility: "automatic", "all",
    /// "doubleColumn" or "detailOnly". SwiftUI writes it back when the person shows or hides
    /// the sidebar; that change is reported through the selected-value handler.
    @objc public var splitColumnVisibility = "automatic" {
        willSet {
            precondition(["automatic", "all", "doubleColumn", "detailOnly"].contains(newValue),
                         "Unsupported split view column visibility: \(newValue)")
            objectWillChange.send()
        }
    }
    /// The split view column shown on top when it collapses to one column (compact width):
    /// "sidebar", "content" or "detail". SwiftUI writes it back when the person goes back;
    /// that change is reported through the selection handler (0, 1 or 2).
    @objc public var splitCompactColumn = "sidebar" {
        willSet {
            precondition(["sidebar", "content", "detail"].contains(newValue),
                         "Unsupported split view column: \(newValue)")
            objectWillChange.send()
        }
    }
    /// Split view style: "" (automatic), "balanced" or "prominentDetail".
    @objc public var splitViewStyle = "" {
        willSet {
            precondition(["", "balanced", "prominentDetail"].contains(newValue),
                         "Unsupported split view style: \(newValue)")
            objectWillChange.send()
        }
    }
    /// A split view without its sidebar toggle (`toolbar(removing: .sidebarToggle)` on the
    /// sidebar column), for a host that shows the sidebar's contents elsewhere.
    @objc public var splitSidebarToggleHidden = false { willSet { objectWillChange.send() } }
    /// A split view column's width (`navigationSplitViewColumnWidth(min:ideal:max:)`), set on the
    /// column's own node; 0 leaves a bound system-defined, and no ideal width sets none.
    @objc public var splitColumnMinWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var splitColumnIdealWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var splitColumnMaxWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var focusRequested = false { willSet { objectWillChange.send() } }
    /// A searchable's tokens (`searchable(text:tokens:)`): ids and the titles shown in the
    /// field, in order. Deleting a token in the field reports the remaining ids through
    /// `selectedValueChangedHandler`, joined by U+001F.
    @objc public var searchTokenIds: [String] = [] { willSet { objectWillChange.send() } }
    @objc public var searchTokenTitles: [String] = [] { willSet { objectWillChange.send() } }
    @objc public var value = 0.0 { willSet { objectWillChange.send() } }
    @objc public var minimum = 0.0 { willSet { objectWillChange.send() } }
    @objc public var maximum = 1.0 { willSet { objectWillChange.send() } }
    @objc public var spacing = 8.0 { willSet { objectWillChange.send() } }
    @objc public var buttonGroupWraps = false { willSet { objectWillChange.send() } }
    @objc public var buttonGroupOverlap = 2.0 { willSet { objectWillChange.send() } }
    @objc public var buttonGroupFillAvailableWidth = false { willSet { objectWillChange.send() } }
    @objc public var selectedIndex = 0 { willSet { objectWillChange.send() } }
    @objc public var selectedValue = "" { willSet { objectWillChange.send() } }
    @objc public var isEnabled = true { willSet { objectWillChange.send() } }
    @objc public var canNavigateBack = true { willSet { objectWillChange.send() } }
    @objc public var hidesTabBar = false { willSet { objectWillChange.send() } }
    /// Left out in a compact horizontal size class (iPhone, the folded iPhone Duo), for a control
    /// that only makes sense beside other columns, such as a split view's full-screen button.
    @objc public var hiddenInCompactWidth = false { willSet { objectWillChange.send() } }
    /// With `hidesTabBar`, hides the tab bar only in a compact horizontal size class (iPhone,
    /// the folded iPhone Duo), so a page shown in a regular-width split view keeps the tabs.
    @objc public var hidesTabBarOnlyInCompactWidth = false { willSet { objectWillChange.send() } }
    /// Tab role: "" (none) or "search". A search tab sits apart from the others
    /// (iOS 26: the trailing slot of the tab bar) and keeps its own title and symbol.
    @objc public var tabRole = "" {
        willSet {
            precondition(newValue.isEmpty || newValue == "search", "Unsupported tab role: \(newValue)")
            objectWillChange.send()
        }
    }
    /// A tab left out of the tab bar and sidebar (TabContent `hidden`); applied only once set.
    @objc public var tabHidden = false {
        willSet {
            hasTabHiddenState = true
            objectWillChange.send()
        }
    }
    @objc public private(set) var hasTabHiddenState = false
    /// Tab view style: "" (automatic), "sidebarAdaptable" (a sidebar on iPad and Mac) or
    /// "tabBarOnly" (a tab bar wherever possible, never the sidebar form).
    @objc public var tabViewStyle = "" {
        willSet {
            precondition(["", "sidebarAdaptable", "tabBarOnly"].contains(newValue),
                         "Unsupported tab view style: \(newValue)")
            objectWillChange.send()
        }
    }
    /// Tab bar minimize behavior (iOS 26): "" (automatic), "onScrollDown", "onScrollUp" or "never".
    @objc public var tabBarMinimizeBehavior = "" {
        willSet {
            precondition(["", "onScrollDown", "onScrollUp", "never"].contains(newValue),
                         "Unsupported tab bar minimize behavior: \(newValue)")
            objectWillChange.send()
        }
    }
    /// True when a tab view needs the iOS 18 `Tab` API: a style, a minimize behavior,
    /// a role or a hidden tab.
    var usesAdaptiveTabs: Bool {
        kind == "tabView" && (!tabViewStyle.isEmpty || !tabBarMinimizeBehavior.isEmpty
            || children.contains { !$0.tabRole.isEmpty || $0.hasTabHiddenState })
    }
    /// A tab view draws each tab's title, symbol, role and visibility itself, so a
    /// change to a tab node is forwarded to the tab view.
    private var tabObservations: [UUID: AnyCancellable] = [:]
    @objc public var route = "" { willSet { objectWillChange.send() } }
    @objc public var fontStyle = "" { willSet { objectWillChange.send() } }
    @objc public var fontSize = 0.0 { willSet { objectWillChange.send() } }
    @objc public var fontWeight = 400 { willSet { objectWillChange.send() } }
    @objc public var fontPostScriptName = "" { willSet { objectWillChange.send() } }
    @objc public var lineHeightMultiple = 0.0 { willSet { objectWillChange.send() } }
    @objc public var preferredScheme = "" { willSet { objectWillChange.send() } }
    @objc public var buttonStyle = "" { willSet { objectWillChange.send() } }
    /// A button's role: "" (none), "destructive" or "cancel" (`Button(role:)`).
    @objc public var buttonRole = "" {
        willSet {
            precondition(["", "destructive", "cancel"].contains(newValue),
                         "Unsupported button role: \(newValue)")
            objectWillChange.send()
        }
    }
    /// A swipe row's leading actions: its last `swipeLeadingCount` children (after the content
    /// and the trailing actions).
    @objc public var swipeLeadingCount = 0 { willSet { objectWillChange.send() } }
    @objc public var hasButtonAppearance = false { willSet { objectWillChange.send() } }
    @objc public var buttonFillHex = "" { willSet { objectWillChange.send() } }
    @objc public var buttonFillDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var buttonBorderHex = "" { willSet { objectWillChange.send() } }
    @objc public var buttonBorderDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var buttonBorderWidth = 1.0 { willSet { objectWillChange.send() } }
    var buttonGroupPressed = false { willSet { objectWillChange.send() } }
    var clearButtonBorderInset: CGFloat {
        hasButtonAppearance && buttonBorderHex.isEmpty && buttonBorderDarkHex.isEmpty
            ? CGFloat(buttonBorderWidth) : 0
    }
    @objc public var buttonCornerRadius = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCircleDiameter = 0.0 { willSet { objectWillChange.send() } }
    @objc public var hasButtonEllipticalCornerRadii = false { willSet { objectWillChange.send() } }
    @objc public var buttonCornerTopLeftX = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerTopLeftY = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerTopRightX = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerTopRightY = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerBottomRightX = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerBottomRightY = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerBottomLeftX = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonCornerBottomLeftY = 0.0 { willSet { objectWillChange.send() } }
    @objc public var buttonDisabledOpacity = 0.65 { willSet { objectWillChange.send() } }
    @objc public var isUnderlined = false { willSet { objectWillChange.send() } }
    @objc public var isStrikethrough = false { willSet { objectWillChange.send() } }
    @objc public var opacity = 1.0 { willSet { objectWillChange.send() } }
    @objc public var diameter = 0.0 { willSet { objectWillChange.send() } }
    @objc public var pickerStyle = "" { willSet { objectWillChange.send() } }
    @objc public var paddingPoints = 0.0 { willSet { objectWillChange.send() } }
    @objc public var paddingTop = 0.0 { willSet { objectWillChange.send() } }
    @objc public var paddingRight = 0.0 { willSet { objectWillChange.send() } }
    @objc public var paddingBottom = 0.0 { willSet { objectWillChange.send() } }
    @objc public var paddingLeft = 0.0 { willSet { objectWillChange.send() } }
    @objc public var foregroundHex = "" { willSet { objectWillChange.send() } }
    @objc public var foregroundDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var backgroundHex = "" { willSet { objectWillChange.send() } }
    @objc public var backgroundDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var tintHex = "" { willSet { objectWillChange.send() } }
    @objc public var tintDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var progressTrackHex = "" { willSet { objectWillChange.send() } }
    @objc public var progressTrackDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var progressThickness = 0.0 { willSet { objectWillChange.send() } }
    @objc public var cornerRadius = 0.0 { willSet { objectWillChange.send() } }
    @objc public var borderHex = "" { willSet { objectWillChange.send() } }
    @objc public var borderDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var borderWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var shadowHex = "" { willSet { objectWillChange.send() } }
    @objc public var shadowDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var shadowRadius = 0.0 { willSet { objectWillChange.send() } }
    @objc public var shadowOpacity = 0.0 { willSet { objectWillChange.send() } }
    @objc public var shadowOffsetX = 0.0 { willSet { objectWillChange.send() } }
    @objc public var shadowOffsetY = 0.0 { willSet { objectWillChange.send() } }
    @objc public var fillsWidth = false { willSet { objectWillChange.send() } }
    @objc public var maxWidth = 0.0 { willSet { objectWillChange.send() } }
    /// Opt-in `frame(maxHeight: .infinity)`: the view takes the height its container proposes.
    @objc public var fillsHeight = false { willSet { objectWillChange.send() } }
    /// Lays the view out under the safe areas too (SwiftUI `ignoresSafeArea()`).
    @objc public var ignoresSafeArea = false { willSet { objectWillChange.send() } }
    /// Opt-in SwiftUI `fixedSize(horizontal:vertical:)`: the view keeps its ideal width (or
    /// height) whatever its container proposes, so a badge or a short button beside a flexible
    /// title keeps its text on one line instead of taking an equal share of the row.
    @objc public var fixedHorizontalSize = false { willSet { objectWillChange.send() } }
    @objc public var fixedVerticalSize = false { willSet { objectWillChange.send() } }
    /// Opt-in SwiftUI `frame(width:)` in points (0 = none): the view is exactly this wide
    /// whatever its container proposes, for example a fixed sidebar column beside a flexible one.
    @objc public var fixedWidth = 0.0 { willSet { objectWillChange.send() } }
    /// Edge of an `overlay` node's second child: "bottom" (default) or "top".
    @objc public var overlayEdge = "bottom" { willSet { objectWillChange.send() } }
    /// Opt-in VoiceOver announcement posted when the view appears or this text changes.
    @objc public var accessibilityAnnouncement = "" { willSet { objectWillChange.send() } }
    @objc public var horizontalAlignment = "leading" { willSet { objectWillChange.send() } }
    @objc public var adaptiveStackBelowWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var minimumHeight = 0.0 { willSet { objectWillChange.send() } }
    @objc public var gridColumns = 2 { willSet { objectWillChange.send() } }
    @objc public var gridColumnMinimumWidths: [NSNumber] = [] { willSet { objectWillChange.send() } }
    @objc public var navigationTitle = "" { willSet { objectWillChange.send() } }
    /// A subtitle under the navigation title (`navigationSubtitle`, iOS 26), e.g. a count.
    @objc public var navigationSubtitle = "" { willSet { objectWillChange.send() } }
    /// Where a searchable's field goes: "" (the system's choice) or "bottomBar" (the bottom
    /// toolbar, as in Notes and Mail; it rises above the keyboard while typing).
    /// While searching, keep the toolbar's other items (filters, add) instead of hiding them
    /// (`searchPresentationToolbarBehavior(.avoidHidingContent)`, iOS 17.1).
    @objc public var searchKeepsToolbar = false { willSet { objectWillChange.send() } }
    @objc public var searchPlacement = "" {
        willSet {
            precondition(["", "bottomBar"].contains(newValue),
                         "Unsupported search placement: \(newValue)")
            objectWillChange.send()
        }
    }
    @objc public var inlineNavigationTitle = false { willSet { objectWillChange.send() } }
    @objc public var centerWhenShort = false { willSet { objectWillChange.send() } }
    @objc public var anchorsToBottom = false { willSet { objectWillChange.send() } }
    /// A toggle node draws only its switch (SwiftUI `labelsHidden`); its text stays the
    /// accessible name. Off by default, so existing toggles keep their label.
    @objc public var labelsHidden = false { willSet { objectWillChange.send() } }
    /// A Form or List row draws no row background (SwiftUI `listRowBackground(Color.clear)`),
    /// so a header such as an app mark sits on the page above the grouped rows. Off by
    /// default, so existing rows keep the system background.
    @objc public var listRowBackgroundHidden = false { willSet { objectWillChange.send() } }
    /// How dragging a scroll node dismisses the software keyboard (SwiftUI
    /// `scrollDismissesKeyboard`): "" keeps the system's automatic behavior, or "immediately",
    /// "interactively" or "never".
    @objc public var scrollDismissesKeyboard = "" {
        willSet {
            precondition(["", "immediately", "interactively", "never"].contains(newValue),
                         "Unsupported keyboard dismissal: \(newValue)")
            objectWillChange.send()
        }
    }
    @objc public var nativeListCanvasHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListCanvasDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListRowHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListRowDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var placeholderColorHex = "" { willSet { objectWillChange.send() } }
    @objc public var placeholderColorDarkHex = "" { willSet { objectWillChange.send() } }
    /// BCP 47 tag VoiceOver uses to speak this Text or Button label; empty keeps the system language.
    @objc public var speechLanguage = "" { willSet { objectWillChange.send() } }
    /// Accessibility action name that also exposes the double-tap handler to assistive technology.
    @objc public var doubleTapActionName = "" { willSet { objectWillChange.send() } }
    /// Card transform (offset in points, rotation in degrees); applied only once set.
    @objc public private(set) var hasTransform = false
    @objc public private(set) var offsetX = 0.0
    @objc public private(set) var offsetY = 0.0
    @objc public private(set) var rotationDegrees = 0.0
    /// Whether the latest transform change animates (a spring) or follows immediately.
    @objc public private(set) var transformAnimated = false
    /// Minimum horizontal-drag distance in points before the drag begins.
    @objc public var horizontalDragMinimumDistance = 10.0 { willSet { objectWillChange.send() } }
    /// True between a drag's first change and its end or cancellation.
    @objc public private(set) var horizontalDragActive = false
    /// Scroll or List: descendants with an automation id become scrollTo targets.
    @objc public private(set) var scrollTargetsEnabled = false { willSet { objectWillChange.send() } }
    @objc public private(set) var scrollTargetId = ""
    @objc public private(set) var scrollTargetAnchor = "center"
    @objc public private(set) var scrollTargetAnimated = true
    @objc public private(set) var scrollRequest = 0 { willSet { objectWillChange.send() } }
    /// Opt-in hide in place (SwiftUI `hidden()` semantics, animated): applied only once set.
    @objc public private(set) var hasHiddenState = false
    @objc public private(set) var hiddenInPlace = false
    /// "fade", or "slideDown" (also moves down by the view's own height; fades only with Reduce Motion).
    @objc public private(set) var hiddenTransition = "fade"
    @objc public private(set) var hiddenAnimationDuration = 0.2
    /// YouTube player: an 11-character video id, never a URL.
    @objc public var videoId: String = "" {
        willSet {
            precondition(newValue.isEmpty || msuIsYouTubeVideoId(newValue),
                         "Invalid YouTube video id")
            objectWillChange.send()
        }
    }
    public private(set) var children: [MSUNode] = [] { willSet { objectWillChange.send() } }
    private var path: [String] = [] { willSet { objectWillChange.send() } }
    @objc public var pathDepth: Int { path.count }

    var tapHandler: (() -> Void)?
    var textChangedHandler: ((String) -> Void)?
    var boolChangedHandler: ((Bool) -> Void)?
    var valueChangedHandler: ((Double) -> Void)?
    var selectionChangedHandler: ((Int) -> Void)?
    var focusChangedHandler: ((Bool) -> Void)?
    var dismissedHandler: (() -> Void)?
    var selectedValueChangedHandler: ((String) -> Void)?
    var navigationChangedHandler: ((Int) -> Void)?
    var appearedHandler: (() -> Void)?
    var escapeHandler: (() -> Void)?
    var submitHandler: (() -> Void)?
    var keyHandler: ((String) -> Bool)?
    var photoRenderedHandler: (() -> Void)?
    var photoFailedHandler: ((String) -> Void)?
    var deleteCancelledHandler: (() -> Void)?
    var deleteConfirmedHandler: (() -> Void)?
    var fileImportedHandler: ((Data, String, String) -> Void)?
    var fileImportErrorHandler: ((String) -> Void)?
    var fileImportCancelledHandler: (() -> Void)?
    var viewportChangedHandler: ((Double, Int) -> Void)?
    var doubleTapHandler: (() -> Void)?
    var dragChangedHandler: ((Double) -> Void)?
    var dragEndedHandler: ((Double, Double) -> Void)?
    var dragCancelledHandler: (() -> Void)?
    var photoPickedHandler: ((Data, String, String) -> Void)?
    var photoPickErrorHandler: ((String) -> Void)?
    var photoPickCancelledHandler: (() -> Void)?
    var scrollGeometryChangedHandler: ((Double, Double, Double, Double, Double) -> Void)?
    var keyboardOverlapChangedHandler: ((Double) -> Void)?
    var accessibilitySettingsChangedHandler: ((Int) -> Void)?
    private(set) var photoPickPending = false
    private var lastViewport: (width: Double, dynamicTypeSize: Int)?
    private var lastScrollGeometry: MSUScrollMetrics?
    private var lastKeyboardOverlap: Double?
    private var lastAccessibilitySettings: Int?
    private(set) var decodedPhoto: CGImage? { willSet { objectWillChange.send() } }
    private var photoWasReported = false

    @objc public init(kind: String) {
        precondition([
            "text", "inlineText", "button", "buttonGroup", "textField", "textEditor", "vstack", "hstack",
            "scroll", "list", "navigation", "navigationLink", "sheet", "inspector",
            "image", "assetImage", "toggle", "slider", "picker", "navigationStack",
            "tabView", "tab", "form", "section", "secureField",
            "valuePicker", "searchable", "menu", "alert",
            "confirmationDialog", "grid", "horizontalGrid", "fileImporter", "toolbar",
            "progress", "bottomInset", "circle", "divider", "indeterminateProgress",
            "photo", "zoomPhoto", "photoCover", "quickSuggestions",
            "starterOverlay", "deleteConfirmation", "photoPicker", "youTubePlayer",
            "overlay", "splitView", "swipeRow", "label", "labeledContent"
        ].contains(kind), "Unsupported SwiftUI node kind: \(kind)")
        self.kind = kind
        super.init()
        if kind == "buttonGroup" {
            spacing = -2
            selectedIndex = -1
        }
    }

    /// The child at `index`, or nil when there is none: for view bodies SwiftUI builds after
    /// the guard that checked the count (a sheet's content, an overlay), when the children may
    /// have changed in between.
    func child(_ index: Int) -> MSUNode? {
        index >= 0 && index < children.count ? children[index] : nil
    }

    @objc(insertChild:atIndex:)
    public func insertChild(_ child: MSUNode, at index: Int) {
        precondition(index >= 0 && index <= children.count, "Child index out of range")
        precondition(kind != "inlineText" || (child.kind == "text" && children.count < 2),
                     "Inline text accepts only two Text nodes")
        children.insert(child, at: index)
        if kind == "tabView" {
            tabObservations[child.id] = child.objectWillChange.sink { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }

    @objc(removeChildAtIndex:)
    public func removeChild(at index: Int) {
        precondition(index >= 0 && index < children.count, "Child index out of range")
        let child = children.remove(at: index)
        tabObservations.removeValue(forKey: child.id)?.cancel()
    }

    @objc public func clearChildren() {
        children.removeAll()
        path.removeAll()
        tabObservations.values.forEach { $0.cancel() }
        tabObservations.removeAll()
    }

    @objc(appendRoute:)
    public func appendRoute(_ value: String) {
        precondition(kind == "navigationStack" && children.dropFirst().contains(where: { $0.route == value }))
        path.append(value)
    }

    @objc public func popRoute() {
        precondition(kind == "navigationStack" && !path.isEmpty)
        path.removeLast()
    }

    @objc public func clearPath() {
        precondition(kind == "navigationStack")
        path.removeAll()
    }

    /// SwiftUI writes the inspector binding when the person closes it (for
    /// example, swipes the compact sheet away); a programmatic close does not
    /// pass through here, so it never reports a dismissal.
    func applyInspectorPresentation(_ next: Bool) {
        let closing = isPresented && !next
        isPresented = next
        if closing { dismissedHandler?() }
    }

    @objc public func invokeAction() {
        if isEnabled { tapHandler?() }
    }

    @objc public func clearHandlers() {
        tapHandler = nil
        textChangedHandler = nil
        boolChangedHandler = nil
        valueChangedHandler = nil
        selectionChangedHandler = nil
        focusChangedHandler = nil
        dismissedHandler = nil
        selectedValueChangedHandler = nil
        navigationChangedHandler = nil
        appearedHandler = nil
        escapeHandler = nil
        submitHandler = nil
        keyHandler = nil
        photoRenderedHandler = nil
        photoFailedHandler = nil
        deleteCancelledHandler = nil
        deleteConfirmedHandler = nil
        fileImportedHandler = nil
        fileImportErrorHandler = nil
        fileImportCancelledHandler = nil
        viewportChangedHandler = nil
        doubleTapHandler = nil
        dragChangedHandler = nil
        dragEndedHandler = nil
        dragCancelledHandler = nil
        horizontalDragActive = false
        photoPickedHandler = nil
        photoPickErrorHandler = nil
        photoPickCancelledHandler = nil
        scrollGeometryChangedHandler = nil
        keyboardOverlapChangedHandler = nil
        accessibilitySettingsChangedHandler = nil
        lastViewport = nil
        lastScrollGeometry = nil
        lastKeyboardOverlap = nil
        lastAccessibilitySettings = nil
    }

    @objc(setDoubleTapHandler:)
    public func setDoubleTapHandler(_ handler: @escaping @convention(block) () -> Void) {
        // The gesture is attached only while a handler exists.
        objectWillChange.send()
        doubleTapHandler = handler
    }

    @objc public func invokeDoubleTap() {
        if isEnabled { doubleTapHandler?() }
    }

    /// Sets the view's offset and rotation together. With animated true the
    /// change animates with a spring (for example back to zero); otherwise it
    /// follows immediately, as a dragged card does.
    @objc(setTransformOffsetX:offsetY:rotation:animated:)
    public func setTransform(offsetX x: Double, offsetY y: Double, rotation degrees: Double, animated: Bool) {
        precondition(x.isFinite && y.isFinite && degrees.isFinite, "A transform needs finite values")
        objectWillChange.send()
        hasTransform = true
        transformAnimated = animated
        offsetX = x
        offsetY = y
        rotationDegrees = degrees
    }

    /// The gesture is attached only while a changed or ended handler exists.
    @objc(setHorizontalDragChangedHandler:endedHandler:cancelledHandler:)
    public func setHorizontalDragHandlers(
        _ changed: @escaping @convention(block) (Double) -> Void,
        endedHandler ended: @escaping @convention(block) (Double, Double) -> Void,
        cancelledHandler cancelled: (@convention(block) () -> Void)?) {
        objectWillChange.send()
        dragChangedHandler = changed
        dragEndedHandler = ended
        dragCancelledHandler = cancelled
    }

    var hasHorizontalDrag: Bool { dragChangedHandler != nil || dragEndedHandler != nil }

    /// A DragGesture change: the horizontal translation from the touch-down point.
    @objc public func reportHorizontalDragChanged(_ translationX: Double) {
        guard isEnabled, hasHorizontalDrag else { return }
        horizontalDragActive = true
        dragChangedHandler?(translationX)
    }

    /// The finger lifted: the final and the velocity-predicted end translation.
    /// Delivered only for a drag that began while the view was enabled, even if
    /// it was disabled meanwhile, so the owner can always settle the view.
    @objc public func reportHorizontalDragEnded(_ translationX: Double, predicted predictedX: Double) {
        guard horizontalDragActive else { return }
        horizontalDragActive = false
        dragEndedHandler?(translationX, predictedX)
    }

    /// The system cancelled the drag (for example a scroll took the touch).
    @objc public func reportHorizontalDragCancelled() {
        guard horizontalDragActive else { return }
        horizontalDragActive = false
        dragCancelledHandler?()
    }

    /// Scrolls the enclosing Scroll or List to the descendant whose automation id
    /// matches, with SwiftUI ScrollViewProxy.scrollTo(_:anchor:). A newly mounted
    /// scroll applies the latest request without animation.
    @objc(requestScrollTo:anchor:animated:)
    public func requestScroll(to target: String, anchor: String, animated: Bool) {
        precondition(kind == "scroll" || kind == "list", "Only a Scroll or List can scroll to a target")
        precondition(!target.isEmpty, "A scroll target needs an automation id")
        precondition(["top", "center", "bottom"].contains(anchor), "Unsupported scroll anchor")
        scrollTargetsEnabled = true
        scrollTargetId = target
        scrollTargetAnchor = anchor
        scrollTargetAnimated = animated
        scrollRequest += 1
    }

    @objc(setPhotoPickedHandler:)
    public func setPhotoPickedHandler(_ handler: @escaping @convention(block) (Data, String, String) -> Void) {
        photoPickedHandler = handler
    }

    @objc(setPhotoPickErrorHandler:)
    public func setPhotoPickErrorHandler(_ handler: @escaping @convention(block) (String) -> Void) {
        photoPickErrorHandler = handler
    }

    @objc(setPhotoPickCancelledHandler:)
    public func setPhotoPickCancelledHandler(_ handler: @escaping @convention(block) () -> Void) {
        photoPickCancelledHandler = handler
    }

    static let maximumPickedPhotoBytes = 25 * 1_048_576

    /// SwiftUI writes the binding false both when the person cancels and when
    /// a pick completes; a pick sets the selection in the same turn, so a close
    /// with no pick pending on the next turn is a cancellation.
    func applyPhotoPickerPresentation(_ next: Bool) {
        let closing = isPresented && !next
        isPresented = next
        guard closing else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.photoPickPending else { return }
            self.photoPickCancelledHandler?()
        }
    }

    func receivePickedPhoto(_ item: PhotosPickerItem) {
        photoPickPending = true
        let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) })
            ?? item.supportedContentTypes.first
        item.loadTransferable(type: Data.self) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self?.completePhotoPick(data: data, type: type)
                case .failure:
                    self?.completePhotoPick(data: nil, type: type)
                }
            }
        }
    }

    func completePhotoPick(data: Data?, type: UTType?) {
        photoPickPending = false
        guard let data, !data.isEmpty else {
            photoPickErrorHandler?("loadFailed")
            return
        }
        guard data.count <= MSUNode.maximumPickedPhotoBytes else {
            photoPickErrorHandler?("tooLarge")
            return
        }
        photoPickedHandler?(data, type?.preferredMIMEType ?? "application/octet-stream",
                            type?.identifier ?? UTType.image.identifier)
    }

    @objc(setTapHandler:)
    public func setTapHandler(_ handler: @escaping @convention(block) () -> Void) {
        tapHandler = handler
    }

    @objc(setTextChangedHandler:)
    public func setTextChangedHandler(_ handler: @escaping @convention(block) (String) -> Void) {
        textChangedHandler = handler
    }

    @objc(setBoolChangedHandler:)
    public func setBoolChangedHandler(_ handler: @escaping @convention(block) (Bool) -> Void) {
        boolChangedHandler = handler
    }

    @objc(setValueChangedHandler:)
    public func setValueChangedHandler(_ handler: @escaping @convention(block) (Double) -> Void) {
        valueChangedHandler = handler
    }

    @objc(setSelectionChangedHandler:)
    public func setSelectionChangedHandler(_ handler: @escaping @convention(block) (Int) -> Void) {
        selectionChangedHandler = handler
    }

    @objc(setFocusChangedHandler:)
    public func setFocusChangedHandler(_ handler: @escaping @convention(block) (Bool) -> Void) {
        focusChangedHandler = handler
    }

    @objc(setDismissedHandler:)
    public func setDismissedHandler(_ handler: @escaping @convention(block) () -> Void) {
        dismissedHandler = handler
    }

    @objc(setSelectedValueChangedHandler:)
    public func setSelectedValueChangedHandler(_ handler: @escaping @convention(block) (String) -> Void) {
        selectedValueChangedHandler = handler
    }

    @objc(setNavigationChangedHandler:)
    public func setNavigationChangedHandler(_ handler: @escaping @convention(block) (Int) -> Void) {
        navigationChangedHandler = handler
    }

    @objc(setAppearedHandler:)
    public func setAppearedHandler(_ handler: @escaping @convention(block) () -> Void) {
        appearedHandler = handler
    }

    @objc(setEscapeHandler:)
    public func setEscapeHandler(_ handler: @escaping @convention(block) () -> Void) {
        escapeHandler = handler
    }

    @objc(setSubmitHandler:)
    public func setSubmitHandler(_ handler: @escaping @convention(block) () -> Void) {
        submitHandler = handler
    }

    @objc(setKeyHandler:)
    public func setKeyHandler(_ handler: @escaping @convention(block) (String) -> Bool) {
        keyHandler = handler
    }

    @objc(setPhotoRenderedHandler:)
    public func setPhotoRenderedHandler(_ handler: @escaping @convention(block) () -> Void) {
        photoRenderedHandler = handler
    }

    @objc(setPhotoFailedHandler:)
    public func setPhotoFailedHandler(_ handler: @escaping @convention(block) (String) -> Void) {
        photoFailedHandler = handler
    }

    @objc(setDeleteCancelledHandler:)
    public func setDeleteCancelledHandler(_ handler: @escaping @convention(block) () -> Void) {
        deleteCancelledHandler = handler
    }

    @objc(setDeleteConfirmedHandler:)
    public func setDeleteConfirmedHandler(_ handler: @escaping @convention(block) () -> Void) {
        deleteConfirmedHandler = handler
    }

    func reportPhotoRendered() {
        guard decodedPhoto != nil && !photoWasReported else { return }
        photoWasReported = true
        photoStatus = "displayed"
        photoRenderedHandler?()
    }

    func submitTextField() {
        if keyHandler?("enter") != true {
            submitHandler?()
        }
    }

    func updateTextInput(_ next: String) {
        let value = kind == "textField"
            ? next.trimmingCharacters(in: .newlines) : next
        guard value != text else { return }
        text = value
        textChangedHandler?(value)
    }

    func handleTextKey(_ key: String) -> Bool {
        keyHandler?(key) ?? false
    }

    func dismissQuickSuggestions() {
        guard isPresented else { return }
        isPresented = false
        dismissedHandler?()
    }

    func cancelDelete() {
        guard !deletePending else { return }
        isPresented = false
    }

    func confirmDelete() {
        guard !deletePending else { return }
        deletePending = true
        deleteConfirmedHandler?()
    }

    func reportDeleteDismissed() {
        let wasDeleting = deletePending
        deletePending = false
        if !wasDeleting { deleteCancelledHandler?() }
    }

    private func decodePhoto() {
        photoWasReported = false
        decodedPhoto = nil
        photoStatus = "loading"
        guard let data = photoData, data.length > 0,
              let source = CGImageSourceCreateWithData(data as Data as CFData, nil)
        else {
            photoStatus = "failed"
            photoFailedHandler?("decodeFailed")
            return
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 2048
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source, 0, options as CFDictionary) else {
            photoStatus = "failed"
            photoFailedHandler?("decodeFailed")
            return
        }
        decodedPhoto = image
    }

    @objc(setFileImportedHandler:)
    public func setFileImportedHandler(_ handler: @escaping @convention(block) (Data, String, String) -> Void) {
        fileImportedHandler = handler
    }

    @objc(setFileImportErrorHandler:)
    public func setFileImportErrorHandler(_ handler: @escaping @convention(block) (String) -> Void) {
        fileImportErrorHandler = handler
    }

    @objc(setFileImportCancelledHandler:)
    public func setFileImportCancelledHandler(_ handler: @escaping @convention(block) () -> Void) {
        fileImportCancelledHandler = handler
    }

    @objc(setViewportChangedHandler:)
    public func setViewportChangedHandler(
        _ handler: @escaping @convention(block) (Double, Int) -> Void
    ) {
        objectWillChange.send()
        lastViewport = nil
        viewportChangedHandler = handler
    }

    func reportViewport(width: Double, dynamicTypeSize: Int) {
        guard width.isFinite && width > 0, let callback = viewportChangedHandler else { return }
        if let last = lastViewport,
           last.width == width && last.dynamicTypeSize == dynamicTypeSize { return }
        lastViewport = (width, dynamicTypeSize)
        callback(width, dynamicTypeSize)
    }

    /// Hides the view in place: it keeps its layout space, cannot be hit, and
    /// is hidden from accessibility. The change animates (ease in-out over
    /// `duration` seconds); "slideDown" also moves it down by its own height,
    /// except with Reduce Motion, where it only fades.
    @objc(setHidden:transition:duration:)
    public func setHidden(_ hidden: Bool, transition: String, duration: Double) {
        precondition(transition == "fade" || transition == "slideDown", "Unsupported hide transition")
        precondition(duration.isFinite && duration >= 0, "A hide animation needs a finite duration")
        objectWillChange.send()
        hasHiddenState = true
        hiddenInPlace = hidden
        hiddenTransition = transition
        hiddenAnimationDuration = duration
    }

    /// The Scroll reports its vertical geometry (SwiftUI onScrollGeometryChange)
    /// whenever a value moves by one point or more. The reporter is attached
    /// only while a handler exists.
    @objc(setScrollGeometryChangedHandler:)
    public func setScrollGeometryChangedHandler(
        _ handler: @escaping @convention(block) (Double, Double, Double, Double, Double) -> Void
    ) {
        precondition(kind == "scroll", "Only a Scroll reports its scroll geometry")
        objectWillChange.send()
        lastScrollGeometry = nil
        scrollGeometryChangedHandler = handler
    }

    /// Reports a scroll geometry as SwiftUI would (also for tests and automation).
    @objc(reportScrollGeometryOffsetY:contentHeight:containerHeight:insetTop:insetBottom:)
    public func reportScrollGeometry(offsetY: Double, contentHeight: Double, containerHeight: Double,
                                     insetTop: Double, insetBottom: Double) {
        reportScrollGeometry(MSUScrollMetrics(offsetY: offsetY, contentHeight: contentHeight,
                                              containerHeight: containerHeight,
                                              insetTop: insetTop, insetBottom: insetBottom))
    }

    func reportScrollGeometry(_ metrics: MSUScrollMetrics) {
        guard metrics.isFinite, let callback = scrollGeometryChangedHandler else { return }
        if let last = lastScrollGeometry, !metrics.differs(from: last, by: 1) { return }
        lastScrollGeometry = metrics
        callback(metrics.offsetY, metrics.contentHeight, metrics.containerHeight,
                 metrics.insetTop, metrics.insetBottom)
    }

    /// The view reports how far the on-screen keyboard reaches into its bottom
    /// edge (the SwiftUI keyboard safe-area region): when it appears and on each
    /// change of a point or more. The reporter is attached only while a handler exists.
    @objc(setKeyboardOverlapChangedHandler:)
    public func setKeyboardOverlapChangedHandler(_ handler: @escaping @convention(block) (Double) -> Void) {
        objectWillChange.send()
        lastKeyboardOverlap = nil
        keyboardOverlapChangedHandler = handler
    }

    /// Reports a keyboard overlap as SwiftUI would (also for tests and automation).
    /// Less than one point counts as none.
    @objc(reportKeyboardOverlap:)
    public func reportKeyboardOverlap(_ points: Double) {
        guard points.isFinite, let callback = keyboardOverlapChangedHandler else { return }
        let overlap = points >= 1 ? points : 0
        if let last = lastKeyboardOverlap, (last == 0) == (overlap == 0), abs(last - overlap) < 1 { return }
        lastKeyboardOverlap = overlap
        callback(overlap)
    }

    /// The view reports VoiceOver (1) and Reduce Motion (2) as flags when it
    /// appears and when either changes. The reporter is attached only while a handler exists.
    @objc(setAccessibilitySettingsChangedHandler:)
    public func setAccessibilitySettingsChangedHandler(_ handler: @escaping @convention(block) (Int) -> Void) {
        objectWillChange.send()
        lastAccessibilitySettings = nil
        accessibilitySettingsChangedHandler = handler
    }

    /// Reports the assistive settings as SwiftUI would (also for tests and automation).
    @objc(reportAccessibilitySettingsVoiceOver:reduceMotion:)
    public func reportAccessibilitySettings(voiceOver: Bool, reduceMotion: Bool) {
        guard let callback = accessibilitySettingsChangedHandler else { return }
        let flags = (voiceOver ? 1 : 0) | (reduceMotion ? 2 : 0)
        if lastAccessibilitySettings == flags { return }
        lastAccessibilitySettings = flags
        callback(flags)
    }

    var routeBinding: Binding<[String]> {
        Binding(
            get: { self.path },
            set: { next in
                if next.count < self.path.count && !self.canNavigateBack {
                    self.objectWillChange.send()
                    return
                }
                if next == self.path { return }
                self.path = next
                self.navigationChangedHandler?(next.count)
            }
        )
    }
}

@objc(MSUBridge)
public final class MSUBridge: NSObject {
    @objc(makeNodeWithKind:)
    public static func makeNode(kind: String) -> MSUNode {
        MSUNode(kind: kind)
    }
}

private func msuColor(_ hex: String) -> Color? {
    guard hex.count == 7, hex.first == "#",
          let value = UInt64(hex.dropFirst(), radix: 16) else { return nil }
    return Color(.sRGB,
                 red: Double((value >> 16) & 0xff) / 255,
                 green: Double((value >> 8) & 0xff) / 255,
                 blue: Double(value & 0xff) / 255,
                 opacity: 1)
}

private func msuAdaptiveColor(_ light: String, _ dark: String,
                              scheme: ColorScheme) -> Color? {
    msuColor(scheme == .dark && !dark.isEmpty ? dark : light)
}

private func msuFont(_ node: MSUNode, bodyFontScale: CGFloat) -> Font? {
    guard node.fontSize > 0 else {
        switch node.fontStyle {
        case "largeTitle": return .largeTitle
        case "title": return .title
        case "title2": return .title2
        case "headline": return .headline
        case "subheadline": return .subheadline
        case "caption": return .caption
        case "body": return .body
        case "": return nil
        default: return .body
        }
    }
    let weight: Font.Weight = switch node.fontWeight {
    case 100: .ultraLight
    case 200: .thin
    case 300: .light
    case 500: .medium
    case 600: .semibold
    case 700: .bold
    case 800: .heavy
    case 900: .black
    default: .regular
    }
    let size = CGFloat(node.fontSize)
    if node.fontPostScriptName.isEmpty {
        return .system(size: size * bodyFontScale, weight: weight)
    }
    return .custom(node.fontPostScriptName, size: size, relativeTo: .body)
        .weight(weight)
}

@ViewBuilder
private func msuLineHeight<V: View>(_ view: V, node: MSUNode,
                                    bodyFontScale: CGFloat) -> some View {
    if node.fontSize > 0 && node.lineHeightMultiple > 0 {
        if #available(iOS 26, macOS 26, *) {
            view.lineHeight(.multiple(factor: node.lineHeightMultiple))
        } else {
            view.lineSpacing(max(0, (node.lineHeightMultiple - 1)
                * CGFloat(node.fontSize) * bodyFontScale))
        }
    } else {
        view
    }
}

private struct QuickAddAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>],
                       nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newer in newer })
    }
}

private struct TextInputNodeView: View {
    @ObservedObject var node: MSUNode
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var hasFocus: Bool

    private var prompt: Text? {
        guard let tint = msuAdaptiveColor(node.placeholderColorHex,
                                          node.placeholderColorDarkHex,
                                          scheme: colorScheme) else { return nil }
        return Text(node.placeholder).foregroundColor(tint)
    }

    private var text: Binding<String> {
        Binding(
            get: { node.text },
            set: { next in node.updateTextInput(next) }
        )
    }

    @ViewBuilder
    private func labeledEditor<V: View>(_ editor: V) -> some View {
        if node.accessibilityLabelText.isEmpty { editor }
        else { editor.accessibilityLabel(node.accessibilityLabelText) }
    }

    private var textEditorPlaceholderInsets: EdgeInsets {
        #if os(iOS)
        // Native text placement uses an 8pt top inset and 5pt line-fragment padding.
        return EdgeInsets(top: 8, leading: 5, bottom: 0, trailing: 0)
        #else
        return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        #endif
    }

    @ViewBuilder
    private var nativeTextEditor: some View {
        if node.hidesTextEditorScrollBackground {
            TextEditor(text: text).scrollContentBackground(.hidden)
        } else {
            TextEditor(text: text)
        }
    }

    var body: some View {
        Group {
            if node.kind == "textEditor" {
                labeledEditor(nativeTextEditor
                    .accessibilityIdentifier(node.automationId))
                    .overlay(alignment: .topLeading) {
                        if node.showsTextEditorPlaceholder {
                            Text(node.placeholder)
                                .foregroundColor(
                                    msuAdaptiveColor(node.placeholderColorHex,
                                                     node.placeholderColorDarkHex,
                                                     scheme: colorScheme) ?? .secondary)
                                .padding(textEditorPlaceholderInsets)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                                .accessibilityRepresentation { EmptyView() }
                        }
                    }
            } else if node.kind == "secureField" {
                SecureField(node.placeholder, text: text, prompt: prompt)
                    .accessibilityIdentifier(node.automationId)
            } else {
                TextField(node.placeholder, text: text, prompt: prompt)
                    .accessibilityIdentifier(node.automationId)
                    .anchorPreference(key: QuickAddAnchorKey.self, value: .bounds) {
                        node.automationId.isEmpty ? [:] : [node.automationId: $0]
                    }
                    .onSubmit { node.submitTextField() }
                    .onKeyPress(phases: .down) { press in
                        let key: String
                        switch press.key {
                        case .upArrow: key = "up"
                        case .downArrow: key = "down"
                        case .return: key = "enter"
                        case .escape: key = "escape"
                        default:
                            switch press.characters {
                            case "\r", "\n": key = "enter"
                            case "\u{1B}": key = "escape"
                            default: return .ignored
                            }
                        }
                        if node.handleTextKey(key) { return .handled }
                        if key == "escape", let escape = node.escapeHandler {
                            escape()
                            return .handled
                        }
                        return .ignored
                    }
            }
        }
        .focused($hasFocus)
        .onChange(of: node.focusRequested, initial: true) { _, next in hasFocus = next }
        .onChange(of: hasFocus) { _, next in
            if node.focusRequested != next {
                node.focusRequested = next
            }
            node.focusChangedHandler?(next)
        }
    }
}

private struct PickerOptionNodeView: View {
    @ObservedObject var node: MSUNode
    let index: Int

    var body: some View {
        Text(node.text).tag(index)
    }
}

private struct SourceHeightProgressStyle: ProgressViewStyle {
    let thickness: CGFloat
    let tint: Color
    let track: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            let fraction = CGFloat(min(1, max(0, configuration.fractionCompleted ?? 0)))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: thickness / 2).fill(track)
                RoundedRectangle(cornerRadius: thickness / 2).fill(tint)
                    .frame(width: geometry.size.width * fraction)
            }
        }
        .frame(height: thickness)
    }
}

struct ButtonEllipticalCornerShape: InsettableShape {
    let topLeft: CGSize
    let topRight: CGSize
    let bottomRight: CGSize
    let bottomLeft: CGSize
    private let insetAmount: CGFloat

    init(topLeft: CGSize, topRight: CGSize, bottomRight: CGSize, bottomLeft: CGSize,
         insetAmount: CGFloat = 0) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        self.insetAmount = insetAmount
    }

    func inset(by amount: CGFloat) -> Self {
        Self(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight,
             bottomLeft: bottomLeft, insetAmount: insetAmount + amount)
    }

    func usedRadii(in borderBox: CGRect) -> (topLeft: CGSize, topRight: CGSize,
                                            bottomRight: CGSize, bottomLeft: CGSize) {
        func paired(_ radius: CGSize) -> CGSize {
            radius.width > 0 && radius.height > 0 ? radius : .zero
        }
        let tl = paired(topLeft), tr = paired(topRight)
        let br = paired(bottomRight), bl = paired(bottomLeft)
        func ratio(_ length: CGFloat, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
            let largest = max(a, b)
            return largest == 0 ? 1 : min(1, (length / largest) / (a / largest + b / largest))
        }
        // CSS reduces every axis by the same factor against the original border box.
        let factor = min(1, ratio(borderBox.width, tl.width, tr.width),
                         ratio(borderBox.height, tr.height, br.height),
                         ratio(borderBox.width, bl.width, br.width),
                         ratio(borderBox.height, tl.height, bl.height))
        func inner(_ radius: CGSize) -> CGSize {
            let x = max(0, radius.width * factor - insetAmount)
            let y = max(0, radius.height * factor - insetAmount)
            return x > 0 && y > 0 ? CGSize(width: x, height: y) : .zero
        }
        return (inner(tl), inner(tr), inner(br), inner(bl))
    }

    func path(in rect: CGRect) -> Path {
        let box = rect.insetBy(dx: insetAmount, dy: insetAmount)
        guard box.width > 0 && box.height > 0 else { return Path() }
        let (tl, tr, br, bl) = usedRadii(in: rect)
        let k: CGFloat = 0.5522847498307936
        var path = Path()
        path.move(to: CGPoint(x: box.minX + tl.width, y: box.minY))
        path.addLine(to: CGPoint(x: box.maxX - tr.width, y: box.minY))
        path.addCurve(to: CGPoint(x: box.maxX, y: box.minY + tr.height),
                      control1: CGPoint(x: box.maxX - tr.width * (1 - k), y: box.minY),
                      control2: CGPoint(x: box.maxX, y: box.minY + tr.height * (1 - k)))
        path.addLine(to: CGPoint(x: box.maxX, y: box.maxY - br.height))
        path.addCurve(to: CGPoint(x: box.maxX - br.width, y: box.maxY),
                      control1: CGPoint(x: box.maxX, y: box.maxY - br.height * (1 - k)),
                      control2: CGPoint(x: box.maxX - br.width * (1 - k), y: box.maxY))
        path.addLine(to: CGPoint(x: box.minX + bl.width, y: box.maxY))
        path.addCurve(to: CGPoint(x: box.minX, y: box.maxY - bl.height),
                      control1: CGPoint(x: box.minX + bl.width * (1 - k), y: box.maxY),
                      control2: CGPoint(x: box.minX, y: box.maxY - bl.height * (1 - k)))
        path.addLine(to: CGPoint(x: box.minX, y: box.minY + tl.height))
        path.addCurve(to: CGPoint(x: box.minX + tl.width, y: box.minY),
                      control1: CGPoint(x: box.minX, y: box.minY + tl.height * (1 - k)),
                      control2: CGPoint(x: box.minX + tl.width * (1 - k), y: box.minY))
        path.closeSubpath()
        return path
    }
}

private struct ButtonGroupMembershipKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ButtonGroupFillKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var isMSUButtonGroupMember: Bool {
        get { self[ButtonGroupMembershipKey.self] }
        set { self[ButtonGroupMembershipKey.self] = newValue }
    }

    var fillsMSUButtonGroupWidth: Bool {
        get { self[ButtonGroupFillKey.self] }
        set { self[ButtonGroupFillKey.self] = newValue }
    }
}

private struct CustomButtonAppearanceStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isMSUButtonGroupMember) private var isButtonGroupMember
    let node: MSUNode
    let fill: Color
    let border: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let circleDiameter: CGFloat
    let ellipticalCorners: ButtonEllipticalCornerShape?
    let disabledOpacity: Double
    let minimumHeight: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let shadowOffsetX: CGFloat
    let shadowOffsetY: CGFloat

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if circleDiameter > 0 {
            styledLabel(configuration, shape: Circle())
        } else if let ellipticalCorners {
            styledLabel(configuration, shape: ellipticalCorners)
        } else {
            styledLabel(configuration, shape: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    private func styledLabel<S: InsettableShape>(
        _ configuration: Configuration, shape: S
    ) -> some View {
        if circleDiameter > 0 {
            paintedLabel(
                configuration.label.frame(width: circleDiameter, height: circleDiameter),
                configuration, shape: shape)
        } else if node.clearButtonBorderInset > 0 {
            paintedLabel(configuration.label.padding(node.clearButtonBorderInset),
                         configuration, shape: shape)
        } else {
            paintedLabel(configuration.label, configuration, shape: shape)
        }
    }

    private func paintedLabel<Label: View, S: InsettableShape>(
        _ label: Label, _ configuration: Configuration, shape: S
    ) -> some View {
        label
            .frame(minHeight: minimumHeight > 0 ? minimumHeight : nil)
            .background {
                if shadowOpacity > 0 {
                    shape.fill(.black)
                        .shadow(color: shadowColor.opacity(shadowOpacity),
                                radius: shadowRadius, x: shadowOffsetX, y: shadowOffsetY)
                        .overlay { shape.fill(.black).blendMode(.destinationOut) }
                        .compositingGroup()
                }
                shape.fill(fill).brightness(configuration.isPressed ? 0.08 : 0)
            }
            .overlay { shape.strokeBorder(border, lineWidth: borderWidth) }
            .contentShape(shape)
            .compositingGroup()
            .opacity(isEnabled ? 1 : disabledOpacity)
            .onChange(of: configuration.isPressed) { _, pressed in
                if isButtonGroupMember && node.buttonGroupPressed != pressed {
                    node.buttonGroupPressed = pressed
                }
            }
    }
}

struct ButtonGroupLayout: Layout {
    let wraps: Bool
    let overlap: CGFloat
    let fillAvailableWidth: Bool

    struct Plan {
        let positions: [CGPoint]
        let size: CGSize
    }

    static func plan(sizes: [CGSize], availableWidth: CGFloat?, wraps: Bool,
                     overlap: CGFloat = 2) -> Plan {
        var positions = Array(repeating: CGPoint.zero, count: sizes.count)
        var rowIndices: [Int] = []
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var rowY: CGFloat = 0
        var widestRow: CGFloat = 0

        func finishRow() {
            for index in rowIndices {
                positions[index].y += (rowHeight - sizes[index].height) / 2
            }
            widestRow = max(widestRow, rowWidth)
            rowY += rowHeight
            rowWidth = 0
            rowHeight = 0
            rowIndices.removeAll()
        }

        for (index, size) in sizes.enumerated() {
            let margin: CGFloat = index == 0 ? 0 : -overlap
            if wraps, !rowIndices.isEmpty, let availableWidth,
               rowWidth + margin + size.width > availableWidth + 0.001 {
                finishRow()
            }
            positions[index] = CGPoint(x: rowWidth + margin, y: rowY)
            rowWidth += margin + size.width
            rowHeight = max(rowHeight, size.height)
            rowIndices.append(index)
        }
        if !rowIndices.isEmpty { finishRow() }
        return Plan(positions: positions,
                    size: CGSize(width: widestRow, height: rowY))
    }

    static func fillingWidths(sizes: [CGSize], availableWidth: CGFloat,
                              overlap: CGFloat) -> [CGFloat] {
        let naturalWidth = plan(sizes: sizes, availableWidth: nil, wraps: false,
                                overlap: overlap).size.width
        guard !sizes.isEmpty, availableWidth.isFinite, availableWidth > naturalWidth else {
            return sizes.map(\.width)
        }
        let extra = (availableWidth - naturalWidth) / CGFloat(sizes.count)
        return sizes.map { $0.width + extra }
    }

    private func measures(subviews: Subviews, width: CGFloat?) ->
        [(size: CGSize, proposal: ProposedViewSize)] {
        subviews.indices.map { index in
            let ideal = subviews[index].sizeThatFits(.unspecified)
            guard wraps, let width, ideal.width > width + (index == 0 ? 0 : overlap) else {
                return (ideal, .unspecified)
            }
            let constrained = ProposedViewSize(
                width: max(0, width + (index == 0 ? 0 : overlap)), height: nil)
            return (subviews[index].sizeThatFits(constrained), constrained)
        }
    }

    private func expandedMeasures(subviews: Subviews,
        intrinsic: [(size: CGSize, proposal: ProposedViewSize)],
        width: CGFloat?) -> [(size: CGSize, proposal: ProposedViewSize)] {
        guard !wraps, fillAvailableWidth, let width, width.isFinite else { return intrinsic }
        let widths = Self.fillingWidths(sizes: intrinsic.map(\.size),
                                        availableWidth: width, overlap: overlap)
        return subviews.indices.map { index in
            guard widths[index] > intrinsic[index].size.width else { return intrinsic[index] }
            let proposed = ProposedViewSize(width: widths[index], height: nil)
            return (subviews[index].sizeThatFits(proposed), proposed)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                      cache: inout ()) -> CGSize {
        let intrinsic = measures(subviews: subviews, width: nil)
        let naturalWidth = Self.plan(sizes: intrinsic.map { $0.size }, availableWidth: nil,
                                     wraps: false, overlap: overlap).size.width
        let available = proposal.width.flatMap { $0.isFinite ? max(0, $0) : nil }
        let width: CGFloat
        if wraps {
            width = min(naturalWidth, available ?? naturalWidth)
        } else if fillAvailableWidth, let available {
            width = max(naturalWidth, available)
        } else {
            width = naturalWidth
        }
        let fitted = wraps ? measures(subviews: subviews, width: width)
            : expandedMeasures(subviews: subviews, intrinsic: intrinsic, width: width)
        let result = Self.plan(sizes: fitted.map { $0.size }, availableWidth: width,
                               wraps: wraps, overlap: overlap)
        return CGSize(width: max(width, result.size.width), height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let available = bounds.width.isFinite ? max(0, bounds.width) : nil
        let intrinsic = measures(subviews: subviews, width: nil)
        let fitted = wraps ? measures(subviews: subviews, width: available)
            : expandedMeasures(subviews: subviews, intrinsic: intrinsic, width: available)
        let result = Self.plan(sizes: fitted.map { $0.size },
                               availableWidth: available, wraps: wraps, overlap: overlap)
        for index in subviews.indices {
            let position = result.positions[index]
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                anchor: .topLeading, proposal: fitted[index].proposal)
        }
    }
}

private struct ButtonGroupChildView: View {
    @ObservedObject var node: MSUNode
    let selected: Bool
    let accessibilityOrder: Double
    let fillsAvailableWidth: Bool
    @State private var hovered = false
    @FocusState private var focused: Bool

    var body: some View {
        SwiftUINodeView(node: node)
            .environment(\.isMSUButtonGroupMember, true)
            .environment(\.fillsMSUButtonGroupWidth, fillsAvailableWidth)
            .focused($focused)
            .onHover { hovered = $0 }
            .zIndex(selected || hovered || focused || node.buttonGroupPressed ? 1 : 0)
            .accessibilitySortPriority(accessibilityOrder)
    }
}

private struct AdaptiveStackNodeView: View {
    @ObservedObject var node: MSUNode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var availableWidth: CGFloat = .greatestFiniteMagnitude

    var body: some View {
        let vertical = dynamicTypeSize >= .xLarge || availableWidth < node.adaptiveStackBelowWidth
        let layout = vertical
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: node.spacing))
            : AnyLayout(HStackLayout(alignment: .center, spacing: node.spacing))
        layout {
            ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { availableWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, width in availableWidth = width }
            }
        }
    }
}

private struct ScrollNodeView: View {
    @ObservedObject var node: MSUNode

    private var rows: some View {
        LazyVStack(alignment: .leading, spacing: node.spacing) {
            ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
        }
        // The scroll view's own keyboard dismissal: scrollable views inside the content (a
        // TextEditor, a nested scroll) keep the system default.
        .modifier(ScrollKeyboardDismissal(mode: node.scrollDismissesKeyboard.isEmpty
            ? "" : "automatic"))
    }

    var body: some View {
        ScrollTargetReader(node: node) {
            scrollView.modifier(ScrollKeyboardDismissal(mode: node.scrollDismissesKeyboard))
        }
    }

    @ViewBuilder
    private var scrollView: some View {
        if node.centerWhenShort {
            if #available(iOS 18.0, macOS 15.0, *) {
                ScrollView { rows }
                    .defaultScrollAnchor(.center, for: .alignment)
                    .modifier(BottomScrollAnchor(enabled: node.anchorsToBottom))
                    .modifier(ScrollGeometryReporter(node: node))
            } else {
                GeometryReader { viewport in
                    ScrollView {
                        rows.frame(minHeight: viewport.size.height, alignment: .center)
                    }
                    .modifier(BottomScrollAnchor(enabled: node.anchorsToBottom))
                }
            }
        } else {
            ScrollView { rows }
                .modifier(BottomScrollAnchor(enabled: node.anchorsToBottom))
                .modifier(ScrollGeometryReporter(node: node))
        }
    }
}

/// SwiftUI `scrollDismissesKeyboard` for a scroll node's mode; "" applies nothing, so the
/// environment's (the system's automatic) behavior stays.
struct ScrollKeyboardDismissal: ViewModifier {
    let mode: String

    static func resolved(_ mode: String) -> ScrollDismissesKeyboardMode? {
        switch mode {
        case "automatic": return .automatic
        case "immediately": return .immediately
        case "interactively": return .interactively
        case "never": return .never
        default: return nil
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if let resolved = Self.resolved(mode) {
            content.scrollDismissesKeyboard(resolved)
        } else {
            content
        }
    }
}

/// Opens a scroll view at its end and keeps the end visible when content or
/// container size changes, as a chat transcript does. Only the initial-offset
/// and size-change roles are anchored, so short content keeps its alignment.
private struct BottomScrollAnchor: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if !enabled {
            content
        } else if #available(iOS 18.0, macOS 15.0, *) {
            content
                .defaultScrollAnchor(.bottom, for: .initialOffset)
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
        } else {
            content.defaultScrollAnchor(.bottom)
        }
    }
}

private struct HorizontalGridNodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .leading, horizontalSpacing: node.spacing,
                 verticalSpacing: node.spacing) {
                ForEach(node.children, id: \.id) { row in
                    GridRow {
                        ForEach(Array(row.children.enumerated()), id: \.element.id) { index, cell in
                            SwiftUINodeView(node: cell)
                                .frame(minWidth: index < node.gridColumnMinimumWidths.count
                                    ? CGFloat(truncating: node.gridColumnMinimumWidths[index]) : 0,
                                    alignment: .leading)
                        }
                    }
                    .id(row.id)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(row.automationId)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityIdentifier(node.automationId)
    }
}

private struct NativeCollectionNodeView: View {
    @ObservedObject var node: MSUNode
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder
    private func canvas<V: View>(_ collection: V) -> some View {
        if node.nativeListCanvasHex.isEmpty {
            collection
        } else {
            collection.scrollContentBackground(.hidden)
                .background(msuAdaptiveColor(node.nativeListCanvasHex,
                                              node.nativeListCanvasDarkHex,
                                              scheme: colorScheme) ?? .clear)
        }
    }

    /// A row keeps the system default for its own scrolling views (a TextEditor) when the
    /// collection sets a keyboard dismissal mode.
    private var rowKeyboardMode: String {
        node.scrollDismissesKeyboard.isEmpty ? "" : "automatic"
    }

    @ViewBuilder
    var body: some View {
        if node.kind == "form" {
            canvas(Form {
                ForEach(node.children, id: \.id) { child in
                    if node.nativeListRowHex.isEmpty {
                        SwiftUINodeView(node: child)
                            .modifier(ScrollKeyboardDismissal(mode: rowKeyboardMode))
                    } else {
                        SwiftUINodeView(node: child)
                            .modifier(ScrollKeyboardDismissal(mode: rowKeyboardMode))
                            .listRowBackground(msuAdaptiveColor(node.nativeListRowHex,
                                                                node.nativeListRowDarkHex,
                                                                scheme: colorScheme))
                    }
                }
            }.modifier(ScrollKeyboardDismissal(mode: node.scrollDismissesKeyboard)))
        } else {
            ScrollTargetReader(node: node) { canvas(List {
                ForEach(node.children, id: \.id) { child in
                    if node.nativeListRowHex.isEmpty {
                        SwiftUINodeView(node: child)
                    } else {
                        SwiftUINodeView(node: child)
                            .listRowBackground(msuAdaptiveColor(node.nativeListRowHex,
                                                                node.nativeListRowDarkHex,
                                                                scheme: colorScheme))
                    }
                }
            }) }
        }
    }
}

private struct PhotoNodeView: View {
    @ObservedObject var node: MSUNode

    @ViewBuilder
    var body: some View {
        if let image = node.decodedPhoto {
            ZStack {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: node.photoMaxHeight)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(node.accessibilityLabelText)
            .accessibilityAddTraits(.isImage)
            .onAppear { node.reportPhotoRendered() }
        }
    }
}

private struct ZoomPhotoNodeView: View {
    @ObservedObject var node: MSUNode
    @State private var scale: CGFloat = 1
    @State private var settledScale: CGFloat = 1
    @State private var translation: CGSize = .zero
    @State private var settledTranslation: CGSize = .zero

    private func imageSize(_ image: CGImage, in viewport: CGSize) -> CGSize {
        guard viewport.width > 0 && viewport.height > 0 else { return .zero }
        let ratio = min(viewport.width / CGFloat(image.width),
                        viewport.height / CGFloat(image.height))
        return CGSize(width: CGFloat(image.width) * ratio,
                      height: CGFloat(image.height) * ratio)
    }

    private func bounded(_ proposed: CGSize, image: CGSize, viewport: CGSize,
                         at scale: CGFloat) -> CGSize {
        let limitX = max(0, (image.width * scale - viewport.width) / 2)
        let limitY = max(0, (image.height * scale - viewport.height) / 2)
        return CGSize(width: min(limitX, max(-limitX, proposed.width)),
                      height: min(limitY, max(-limitY, proposed.height)))
    }

    @ViewBuilder
    var body: some View {
        if let image = node.decodedPhoto {
            GeometryReader { viewport in
                let size = imageSize(image, in: viewport.size)
                let magnify = MagnifyGesture()
                    .onChanged { value in
                        scale = min(4, max(1, settledScale * value.magnification))
                        translation = bounded(translation, image: size,
                                              viewport: viewport.size, at: scale)
                    }
                    .onEnded { _ in settledScale = scale }
                let drag = DragGesture()
                    .onChanged { value in
                        let proposed = CGSize(
                            width: settledTranslation.width + value.translation.width,
                            height: settledTranslation.height + value.translation.height)
                        translation = bounded(proposed, image: size,
                                              viewport: viewport.size, at: scale)
                    }
                    .onEnded { _ in settledTranslation = translation }
                ZStack {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size.width, height: size.height)
                        .scaleEffect(scale)
                        .offset(translation)
                }
                    .frame(width: size.width, height: size.height)
                    .position(x: viewport.size.width / 2, y: viewport.size.height / 2)
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(node.accessibilityLabelText)
                    .accessibilityAddTraits(.isImage)
                    .gesture(magnify.simultaneously(with: drag))
                    .onAppear {
                        scale = 1
                        settledScale = 1
                        translation = .zero
                        settledTranslation = .zero
                        node.reportPhotoRendered()
                    }
            }
            .clipped()
        }
    }
}

private struct PhotoCoverNodeView: View {
    @ObservedObject var node: MSUNode
    @FocusState private var viewerFocused: Bool

    var body: some View {
        Group {
            if node.children.count == 3 {
                let presented = Binding(
                    get: { node.isPresented },
                    set: { node.isPresented = $0 })
                #if os(iOS)
                SwiftUINodeView(node: node.children[0])
                    .fullScreenCover(isPresented: presented,
                                     onDismiss: { node.dismissedHandler?() }) {
                        modalContent
                    }
                #else
                SwiftUINodeView(node: node.children[0])
                    .sheet(isPresented: presented,
                           onDismiss: { node.dismissedHandler?() }) {
                        modalContent
                    }
                #endif
            }
        }
    }

    private var modalContent: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.92)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { node.isPresented = false }
            if let photo = node.child(1) {
                SwiftUINodeView(node: photo)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let close = node.child(2) {
                SwiftUINodeView(node: close)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(.white.opacity(0.15), in: Circle())
                    .padding(16)
            }
        }
        .focusable()
        .focused($viewerFocused)
        .onAppear { viewerFocused = true }
        .onKeyPress(.escape) {
            node.isPresented = false
            return .handled
        }
    }
}

private func quickAddField(in root: MSUNode, id: String) -> MSUNode? {
    if root.kind == "textField" && root.automationId == id { return root }
    for child in root.children {
        if let found = quickAddField(in: child, id: id) { return found }
    }
    return nil
}

struct QuickAddSuggestionsNodeView: View {
    @ObservedObject var node: MSUNode
    @ObservedObject var field: MSUNode
    @ScaledMetric(relativeTo: .body) private var suggestionRowHeight: CGFloat = 60
    @State private var fieldRect: CGRect = .null
    @State private var listRect: CGRect = .null

    init(node: MSUNode, field: MSUNode) {
        _node = ObservedObject(wrappedValue: node)
        _field = ObservedObject(wrappedValue: field)
    }

    private var mountedChildren: (content: MSUNode, suggestions: MSUNode)? {
        let children = node.children
        guard children.count == 2 else { return nil }
        return (children[0], children[1])
    }

    private func isMounted(content: MSUNode, suggestions: MSUNode) -> Bool {
        guard let current = mountedChildren else { return false }
        return current.content === content && current.suggestions === suggestions
    }

    func selectedCandidate(content: MSUNode, suggestions: MSUNode) -> UUID? {
        guard node.isPresented, isMounted(content: content, suggestions: suggestions) else {
            return nil
        }
        return suggestions.children.first(where: { $0.accessibilitySelected })?.id
    }

    @ViewBuilder
    var body: some View {
        if let snapshot = mountedChildren {
            let content = snapshot.content
            let suggestions = snapshot.suggestions
            // Form scrolls the focused field above both the keyboard and the open listbox.
            SwiftUINodeView(node: content)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: node.isPresented
                        && isMounted(content: content, suggestions: suggestions) ? 288 : 0)
                }
                .coordinateSpace(name: node.id)
                .overlayPreferenceValue(QuickAddAnchorKey.self) { anchors in
                    GeometryReader { proxy in
                        if node.isPresented,
                           isMounted(content: content, suggestions: suggestions),
                           let anchor = anchors[node.quickAddAnchorId] {
                            let frame = proxy[anchor]
                            let rows = suggestions.children.count
                            let height = min(288, max(52, CGFloat(rows) * suggestionRowHeight))
                            ScrollViewReader { scroll in
                                ScrollView {
                                    SwiftUINodeView(node: suggestions)
                                        .frame(width: frame.width, alignment: .leading)
                                }
                                .frame(width: frame.width, height: height)
                                .accessibilityIdentifier(node.automationId.isEmpty
                                    ? "swiftui.quick.add.scroll"
                                    : node.automationId + ".scroll")
                                .onReceive(Publishers.MergeMany(
                                    suggestions.children.map { $0.objectWillChange })) { _ in
                                        DispatchQueue.main.async {
                                            guard let selected = selectedCandidate(
                                                content: content,
                                                suggestions: suggestions) else { return }
                                            scroll.scrollTo(selected)
                                        }
                                    }
                            }
                            .frame(width: frame.width, height: height)
                            .background(.regularMaterial,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.35))
                            }
                            .shadow(radius: 8)
                            .position(x: frame.midX, y: frame.maxY + height / 2 + 4)
                            .zIndex(100)
                            .onChange(of: frame, initial: true) { _, next in
                                fieldRect = next
                                listRect = CGRect(x: next.minX, y: next.maxY + 4,
                                                  width: next.width, height: height)
                            }
                            .onChange(of: height) { _, next in
                                listRect.size.height = next
                            }
                        }
                    }
                }
                .simultaneousGesture(SpatialTapGesture(coordinateSpace: .named(node.id))
                    .onEnded { tap in
                        guard node.isPresented,
                              isMounted(content: content, suggestions: suggestions),
                              !fieldRect.isNull else { return }
                        if !fieldRect.contains(tap.location) && !listRect.contains(tap.location) {
                            node.dismissQuickSuggestions()
                        }
                    }, including: node.isPresented
                        && isMounted(content: content, suggestions: suggestions) ? .all : .none)
                .onChange(of: field.focusRequested) { _, focused in
                    guard !focused && node.isPresented,
                          isMounted(content: content, suggestions: suggestions) else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        if isMounted(content: content, suggestions: suggestions)
                            && !field.focusRequested {
                            node.dismissQuickSuggestions()
                        }
                    }
                }
        }
    }
}

private struct StarterBlockingOverlayNodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        ZStack {
            if let content = node.children.first {
                SwiftUINodeView(node: content)
                    .allowsHitTesting(!node.isPresented)
                    .accessibilityHidden(node.isPresented)
            }
            if node.isPresented {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .accessibilityLabel(node.text)
                        .accessibilityIdentifier(node.automationId.isEmpty
                            ? "swiftui.starter.busy.spinner"
                            : node.automationId + ".spinner")
                    Text(node.text)
                        .foregroundStyle(.white)
                        .accessibilityIdentifier(node.automationId.isEmpty
                            ? "swiftui.starter.busy.status"
                            : node.automationId + ".status")
                    // An optional action (for example Cancel) the busy content cannot offer.
                    if node.children.count > 1 {
                        SwiftUINodeView(node: node.children[1])
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(node.automationId.isEmpty
                    ? "swiftui.starter.busy" : node.automationId)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ResourceDeleteConfirmationNodeView: View {
    @ObservedObject var node: MSUNode
    @FocusState private var dialogFocused: Bool

    private var idPrefix: String {
        node.automationId.isEmpty ? "swiftui.resource.delete" : node.automationId
    }

    var body: some View {
        Group {
            if let content = node.children.first {
                let presented = Binding(
                    get: { node.isPresented },
                    set: { node.isPresented = $0 })
                #if os(iOS)
                SwiftUINodeView(node: content)
                    .fullScreenCover(isPresented: presented,
                                     onDismiss: { node.reportDeleteDismissed() }) {
                        if node.transparentDeleteBackdrop {
                            modalContent.presentationBackground(Color.clear)
                        } else {
                            modalContent
                        }
                    }
                #else
                SwiftUINodeView(node: content)
                    .sheet(isPresented: presented,
                           onDismiss: { node.reportDeleteDismissed() }) {
                        modalContent
                    }
                #endif
            }
        }
    }

    private var modalContent: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { node.cancelDelete() }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .accessibilityHidden(true)
                    Text(node.text).font(.headline)
                    Spacer()
                    Button(action: { node.cancelDelete() }) {
                        Image(systemName: "xmark")
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel(node.deleteCloseLabel)
                    .accessibilityIdentifier(idPrefix + ".close")
                    .disabled(node.deletePending)
                }
                Text(node.placeholder)
                HStack {
                    Spacer()
                    Button(node.deleteCancelLabel) { node.cancelDelete() }
                        .accessibilityIdentifier(idPrefix + ".cancel")
                        .disabled(node.deletePending)
                    Button(role: .destructive, action: { node.confirmDelete() }) {
                        HStack {
                            if node.deletePending {
                                ProgressView().progressViewStyle(.circular)
                            }
                            Text(node.deleteConfirmLabel)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .accessibilityIdentifier(idPrefix + ".confirm")
                    .disabled(node.deletePending)
                }
            }
            .padding(20)
            .frame(maxWidth: 440)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: 12))
            .padding(24)
        }
        .focusable()
        .focused($dialogFocused)
        .onAppear { dialogFocused = true }
        .onKeyPress(.escape) {
            node.cancelDelete()
            return .handled
        }
        .interactiveDismissDisabled(node.deletePending)
    }
}

struct InlineTextNodeView: View {
    @ObservedObject var leading: MSUNode
    @ObservedObject var trailing: MSUNode
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var bodyFontScale: CGFloat = 1

    private static func run(_ node: MSUNode, colorScheme: ColorScheme,
                            bodyFontScale: CGFloat) -> AttributedString {
        var literal = AttributedString(node.text)
        if let font = msuFont(node, bodyFontScale: bodyFontScale) {
            literal.font = font
        }
        if let color = msuAdaptiveColor(node.foregroundHex, node.foregroundDarkHex,
                                        scheme: colorScheme) {
            literal.foregroundColor = color
        }
        return literal
    }

    static func attributedText(leading: MSUNode, trailing: MSUNode,
                               colorScheme: ColorScheme,
                               bodyFontScale: CGFloat) -> AttributedString {
        var text = run(leading, colorScheme: colorScheme,
                       bodyFontScale: bodyFontScale)
        text.append(run(trailing, colorScheme: colorScheme,
                        bodyFontScale: bodyFontScale))
        return text
    }

    var body: some View {
        msuLineHeight(
            Text(Self.attributedText(leading: leading, trailing: trailing,
                                     colorScheme: colorScheme,
                                     bodyFontScale: bodyFontScale))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1),
            node: leading, bodyFontScale: bodyFontScale)
    }
}

struct SwiftUINodeView: View {
    @ObservedObject var node: MSUNode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @Environment(\.msuInSplitColumn) private var inSplitColumn
    @Environment(\.fillsMSUButtonGroupWidth) private var fillsButtonGroupWidth
    @Environment(\.msuScrollTargetsEnabled) private var scrollTargetsEnabled
    @ScaledMetric(relativeTo: .body) private var bodyFontScale: CGFloat = 1

    private var textContent: Text {
        msuSpeechText(node.text, language: node.speechLanguage).underline(node.isUnderlined)
            .strikethrough(node.isStrikethrough)
    }

    private var symbolImage: AnyView {
        if node.fixedSymbolSize > 0 {
            return AnyView(Image(systemName: node.imageName)
                .font(.system(size: node.fixedSymbolSize))
                .accessibilityIdentifier(node.automationId))
        }
        return AnyView(Image(systemName: node.imageName).imageScale(.large)
            .accessibilityIdentifier(node.automationId))
    }

    // A separate property keeps the iOS type checker from failing with
    // "opaque type defined in terms of itself" on one long modifier chain.
    @ViewBuilder
    var body: some View {
        if node.hiddenInCompactWidth && isCompactWidth {
            EmptyView()
        } else {
            decorated.modifier(NodeBehaviorModifier(node: node, scrollTargetsEnabled: scrollTargetsEnabled,
                                                    ownsAccessibilityLabel: ownsAccessibilityLabel))
        }
    }

    private var isCompactWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    private var decorated: some View {
        requestingScheme(identified(accessible(titled(tabBarVisibility(
            reportingViewport(styledContent(content)))))))
            .disabled(!node.isEnabled)
            .onAppear { node.appearedHandler?() }
            .onKeyPress(.escape) {
                if node.kind == "textField" && node.handleTextKey("escape") {
                    return .handled
                }
                guard let escape = node.escapeHandler else { return .ignored }
                escape()
                return .handled
            }
    }

    private var preferredScheme: ColorScheme? {
        switch node.preferredScheme {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    @ViewBuilder
    private func requestingScheme<V: View>(_ view: V) -> some View {
        if node.preferredScheme.isEmpty { view }
        else { view.preferredColorScheme(preferredScheme) }
    }

    private var horizontalAlignment: Alignment {
        switch node.horizontalAlignment {
        case "center": .center
        case "trailing": .trailing
        default: .leading
        }
    }

    private var dynamicTypeIndex: Int {
        switch dynamicTypeSize {
        case .xSmall: 0
        case .small: 1
        case .medium: 2
        case .large: 3
        case .xLarge: 4
        case .xxLarge: 5
        case .xxxLarge: 6
        case .accessibility1: 7
        case .accessibility2: 8
        case .accessibility3: 9
        case .accessibility4: 10
        case .accessibility5: 11
        @unknown default: 3
        }
    }

    @ViewBuilder
    private func reportingViewport<V: View>(_ view: V) -> some View {
        if node.viewportChangedHandler != nil {
            view.background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            node.reportViewport(width: proxy.size.width,
                                                dynamicTypeSize: dynamicTypeIndex)
                        }
                        .onChange(of: proxy.size.width) { _, width in
                            node.reportViewport(width: width, dynamicTypeSize: dynamicTypeIndex)
                        }
                        .onChange(of: dynamicTypeSize) { _, _ in
                            node.reportViewport(width: proxy.size.width,
                                                dynamicTypeSize: dynamicTypeIndex)
                        }
                }
            }
        } else {
            view
        }
    }

    private func styledContent<V: View>(_ view: V) -> some View {
        let padded = lineHeight(tinted(foreground(configuredFont(view))))
            .padding(EdgeInsets(
                top: node.paddingPoints + node.paddingTop,
                leading: node.paddingPoints + node.paddingLeft,
                bottom: node.paddingPoints + node.paddingBottom,
                trailing: node.paddingPoints + node.paddingRight))
            .frame(minHeight: node.minimumHeight > 0 ? node.minimumHeight : nil)
            .modifier(FixedWidthFrame(width: node.fixedWidth, alignment: horizontalAlignment))
            .frame(maxWidth: node.fillsWidth
                ? node.maxWidth > 0 ? node.maxWidth : .infinity : nil,
                   maxHeight: node.fillsHeight ? .infinity : nil,
                   alignment: horizontalAlignment)

        return ignoringSafeArea(surface(padded)
            .frame(maxWidth: node.fillsWidth && node.maxWidth > 0 ? .infinity : nil,
                   alignment: horizontalAlignment)
            .opacity(node.opacity))
            .modifier(FixedSizing(horizontal: node.fixedHorizontalSize,
                                  vertical: node.fixedVerticalSize))
            .modifier(ListRowBackgroundHidden(hidden: node.listRowBackgroundHidden))
    }

    @ViewBuilder
    private func ignoringSafeArea<V: View>(_ view: V) -> some View {
        if node.ignoresSafeArea { view.ignoresSafeArea() }
        else { view }
    }

    @ViewBuilder
    private func configuredFont<V: View>(_ view: V) -> some View {
        if let font = resolvedFont { view.font(font) }
        else { view }
    }

    @ViewBuilder
    private func foreground<V: View>(_ view: V) -> some View {
        if let color = adaptiveColor(node.foregroundHex, node.foregroundDarkHex) {
            view.foregroundColor(color)
        } else {
            view
        }
    }

    @ViewBuilder
    private func tinted<V: View>(_ view: V) -> some View {
        if let color = adaptiveColor(node.tintHex, node.tintDarkHex) {
            view.tint(color)
        } else {
            view
        }
    }

    @ViewBuilder
    private func lineHeight<V: View>(_ view: V) -> some View {
        msuLineHeight(view, node: node, bodyFontScale: bodyFontScale)
    }

    private var resolvedFont: Font? { msuFont(node, bodyFontScale: bodyFontScale) }

    @ViewBuilder
    private func surface<V: View>(_ view: V) -> some View {
        let fill = adaptiveColor(node.backgroundHex, node.backgroundDarkHex) ?? .clear
        let shadow = (adaptiveColor(node.shadowHex, node.shadowDarkHex) ?? .clear)
            .opacity(node.shadowOpacity)
        if node.cornerRadius > 0 {
            let shape = RoundedRectangle(cornerRadius: node.cornerRadius)
            view.background {
                shape.fill(fill)
                    .shadow(color: shadow, radius: node.shadowRadius,
                            x: 0, y: node.shadowOffsetY)
            }
            .overlay {
                if node.borderWidth > 0 {
                    shape.strokeBorder(
                        adaptiveColor(node.borderHex, node.borderDarkHex) ?? .clear,
                        lineWidth: node.borderWidth)
                }
            }
        } else {
            view.background(fill)
        }
    }

    @ViewBuilder
    private func identified<V: View>(_ view: V) -> some View {
        if node.automationId.isEmpty || node.kind == "textEditor" ||
            node.kind == "horizontalGrid" { view }
        else if node.kind == "bottomInset" || node.kind == "overlay" || node.kind == "hstack" ||
                    node.kind == "vstack" || node.kind == "buttonGroup" ||
                    node.kind == "quickSuggestions" || node.kind == "starterOverlay" ||
                    node.kind == "deleteConfirmation" || node.kind == "photoCover" {
            view.accessibilityElement(children: .contain)
                .accessibilityIdentifier(node.automationId)
        }
        else { view.accessibilityIdentifier(node.automationId) }
    }

    /// The title, and under it the subtitle. A titled node always carries the subtitle
    /// modifier (its text may be empty), so a subtitle coming and going never changes the view's
    /// identity; an untitled node never sets one, so it cannot clear a parent's.
    @ViewBuilder
    private func titled<V: View>(_ view: V) -> some View {
        if node.navigationTitle.isEmpty {
            view
        } else {
            AnyView(titledWithoutSubtitle(view)
                .modifier(NavigationSubtitle(text: node.navigationSubtitle)))
        }
    }

    @ViewBuilder
    private func titledWithoutSubtitle<V: View>(_ view: V) -> some View {
        if node.navigationTitle.isEmpty { view }
        else {
            #if os(iOS)
            if node.inlineNavigationTitle {
                view.navigationTitle(node.navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                view.navigationTitle(node.navigationTitle)
            }
            #else
            view.navigationTitle(node.navigationTitle)
            #endif
        }
    }

    @ViewBuilder
    private func tabBarVisibility<V: View>(_ view: V) -> some View {
        #if os(iOS)
        if node.hidesTabBar
            && (!(node.hidesTabBarOnlyInCompactWidth || inSplitColumn)
                || horizontalSizeClass == .compact) {
            view.toolbar(.hidden, for: .tabBar)
        } else { view }
        #else
        view
        #endif
    }

    @ViewBuilder
    private func accessible<V: View>(_ view: V) -> some View {
        // These kinds apply their own label inside content; a second
        // .accessibilityLabel makes SwiftUI read it twice. A label with a
        // speech language is applied by NodeBehaviorModifier instead.
        if node.accessibilityLabelText.isEmpty || ownsAccessibilityLabel ||
            !node.speechLanguage.isEmpty { view }
        else { view.accessibilityLabel(node.accessibilityLabelText) }
    }

    /// These kinds apply their own label inside content.
    private var ownsAccessibilityLabel: Bool {
        node.kind == "textEditor" || node.kind == "slider" || node.kind == "progress" ||
            node.kind == "indeterminateProgress"
    }

    private var ellipticalButtonShape: ButtonEllipticalCornerShape? {
        guard node.hasButtonAppearance && node.hasButtonEllipticalCornerRadii else { return nil }
        return ButtonEllipticalCornerShape(
            topLeft: CGSize(width: node.buttonCornerTopLeftX, height: node.buttonCornerTopLeftY),
            topRight: CGSize(width: node.buttonCornerTopRightX, height: node.buttonCornerTopRightY),
            bottomRight: CGSize(width: node.buttonCornerBottomRightX, height: node.buttonCornerBottomRightY),
            bottomLeft: CGSize(width: node.buttonCornerBottomLeftX, height: node.buttonCornerBottomLeftY))
    }

    @ViewBuilder
    private func buttonLabel<V: View>(
        _ label: V, ellipticalShape: ButtonEllipticalCornerShape?
    ) -> some View {
        if let ellipticalShape {
            label.frame(minHeight: node.minimumHeight > 0 ? node.minimumHeight : nil)
                .frame(maxWidth: fillsButtonGroupWidth ? .infinity : nil)
                .contentShape(.interaction, ellipticalShape)
        } else {
            label.frame(minHeight: node.minimumHeight > 0 ? node.minimumHeight : nil)
                .frame(maxWidth: fillsButtonGroupWidth ? .infinity : nil)
                .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private var styledButton: some View {
        let ellipse = ellipticalButtonShape
        let role: ButtonRole? = node.buttonRole == "destructive" ? .destructive
            : node.buttonRole == "cancel" ? .cancel : nil
        let button = Button(role: role, action: { node.invokeAction() }) {
            if let label = node.children.first {
                buttonLabel(SwiftUINodeView(node: label), ellipticalShape: ellipse)
                    .accessibilityElement(children: .combine)
            } else {
                buttonLabel(msuSpeechText(node.text, language: node.speechLanguage),
                            ellipticalShape: ellipse)
            }
        }
        if node.hasButtonAppearance {
            button.buttonStyle(CustomButtonAppearanceStyle(
                node: node,
                fill: adaptiveColor(node.buttonFillHex, node.buttonFillDarkHex) ?? .clear,
                border: adaptiveColor(node.buttonBorderHex, node.buttonBorderDarkHex) ?? .clear,
                borderWidth: node.buttonBorderWidth,
                cornerRadius: node.buttonCornerRadius,
                circleDiameter: node.buttonCircleDiameter,
                ellipticalCorners: ellipse,
                disabledOpacity: node.buttonDisabledOpacity,
                minimumHeight: node.minimumHeight,
                shadowColor: adaptiveColor(node.shadowHex, node.shadowDarkHex) ?? .clear,
                shadowRadius: node.shadowRadius,
                shadowOpacity: node.shadowOpacity,
                shadowOffsetX: node.shadowOffsetX,
                shadowOffsetY: node.shadowOffsetY))
        } else if node.buttonStyle == "prominent" {
            button.buttonStyle(.borderedProminent)
        } else if node.buttonStyle == "bordered" {
            button.buttonStyle(.bordered)
        } else if node.buttonStyle == "plain" {
            button.buttonStyle(.plain)
        } else {
            button
        }
    }

    private var valuePicker: some View {
        Picker(node.text, selection: Binding(
            get: { node.selectedValue },
            set: { next in
                node.selectedValue = next
                node.selectedValueChangedHandler?(next)
            }
        )) {
            ForEach(node.children, id: \.id) { option in
                Text(option.text).tag(option.route)
            }
        }
        .accessibilityIdentifier(node.automationId)
    }

    private var indexPicker: some View {
        Picker(node.text, selection: Binding(
            get: { node.selectedIndex },
            set: { next in
                node.selectedIndex = next
                node.selectionChangedHandler?(next)
            }
        )) {
            // By child, not by index: a stale index read after the options change traps.
            ForEach(Array(node.children.enumerated()), id: \.element.id) { index, option in
                PickerOptionNodeView(node: option, index: index)
            }
        }
        .accessibilityIdentifier(node.automationId)
    }

    @ViewBuilder
    private func styledPicker<V: View>(_ picker: V) -> some View {
        if node.pickerStyle == "segmented" {
            // Segmented pickers do not expose their title to accessibility.
            if node.accessibilityLabelText.isEmpty && !node.text.isEmpty {
                picker.pickerStyle(.segmented).accessibilityLabel(node.text)
            } else {
                picker.pickerStyle(.segmented)
            }
        } else if node.pickerStyle == "menu" {
            picker.pickerStyle(.menu)
        } else {
            picker
        }
    }

    private func importFile(_ result: Result<URL, Error>) {
        guard case let .success(url) = result else {
            node.fileImportErrorHandler?("readFailed")
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            node.fileImportErrorHandler?("accessDenied")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        var coordinationError: NSError?
        var imported: Data?
        var readError = false
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { coordinated in
            do {
                let reader = try FileHandle(forReadingFrom: coordinated)
                defer { try? reader.close() }
                imported = try reader.read(upToCount: 1_048_577) ?? Data()
            } catch {
                readError = true
            }
        }
        guard coordinationError == nil, !readError, let imported else {
            node.fileImportErrorHandler?("readFailed")
            return
        }
        guard imported.count <= 1_048_576 else {
            node.fileImportErrorHandler?("tooLarge")
            return
        }
        let type = UTType(filenameExtension: url.pathExtension)
        node.fileImportedHandler?(imported, url.lastPathComponent, type?.preferredMIMEType ?? "text/plain")
    }

    private func adaptiveColor(_ light: String, _ dark: String) -> Color? {
        msuAdaptiveColor(light, dark, scheme: colorScheme)
    }

    /// Each kind is type-erased on its own. One `@ViewBuilder` switch over every
    /// kind makes a single nested `_ConditionalContent` type holding all of them,
    /// and every conditional modifier helper in `decorated` repeats that type
    /// again; SwiftUI resolved the whole type through `swift_getTypeByMangledName`
    /// on the first commit, which took seconds. A node's kind never changes, so a
    /// node keeps one erased type and its identity and state as before; a case's
    /// own branches stay inside its erased view, unchanged.
    private var content: AnyView {
        switch node.kind {
        case "text":
            return erased {
                if node.lineLimit > 0 {
                    AnyView(textContent.lineLimit(node.lineLimit)
                        .accessibilityIdentifier(node.automationId))
                } else {
                    textContent.accessibilityIdentifier(node.automationId)
                }
            }
        case "inlineText":
            return erased {
                if node.children.count == 2 {
                    InlineTextNodeView(leading: node.children[0], trailing: node.children[1])
                }
            }
        case "divider":
            return erased {
                Divider().accessibilityHidden(true)
            }
        case "button":
            return erased {
                styledButton
                    .accessibilityAddTraits(node.accessibilitySelected ? .isSelected : [])
            }
        case "textField", "textEditor", "secureField":
            return erased {
                TextInputNodeView(node: node)
            }
        case "vstack":
            return erased {
                VStack(alignment: .leading, spacing: node.spacing) {
                    ForEach(node.children, id: \.id) {
                        SwiftUINodeView(node: $0).id($0.id)
                    }
                }
            }
        case "hstack":
            return erased {
                if node.adaptiveStackBelowWidth > 0 {
                    AdaptiveStackNodeView(node: node)
                } else {
                    HStack(spacing: node.spacing) {
                        ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                    }
                }
            }
        case "buttonGroup":
            return erased {
                ButtonGroupLayout(wraps: node.buttonGroupWraps,
                                  overlap: node.buttonGroupOverlap,
                                  fillAvailableWidth: node.buttonGroupFillAvailableWidth) {
                    ForEach(node.children, id: \.id) { child in
                        let index = node.children.firstIndex(where: { $0 === child }) ?? 0
                        ButtonGroupChildView(node: child,
                            selected: index == node.selectedIndex,
                            accessibilityOrder: Double(node.children.count - index),
                            fillsAvailableWidth: !node.buttonGroupWraps
                                && node.buttonGroupFillAvailableWidth)
                    }
                }
            }
        case "scroll":
            return erased {
                ScrollNodeView(node: node)
            }
        case "overlay":
            return erased {
                if node.children.count == 2 {
                    OverlayNodeView(node: node)
                }
            }
        case "bottomInset":
            return erased {
                if node.children.count == 2 {
                    SwiftUINodeView(node: node.children[0])
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            if let inset = node.child(1) { SwiftUINodeView(node: inset) }
                        }
                }
            }
        case "list", "form":
            return erased {
                NativeCollectionNodeView(node: node)
            }
        case "section":
            return erased {
                Section {
                    ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                } header: {
                    // An untitled Section has no header (a Form's first rows, a lone button).
                    if !node.text.isEmpty { Text(node.text) }
                }
            }
        case "grid":
            return erased {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: node.gridColumns),
                          spacing: node.spacing) {
                    ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                }
            }
        case "horizontalGrid":
            return erased {
                HorizontalGridNodeView(node: node)
            }
        case "navigationStack":
            return erased {
                NavigationStack(path: node.routeBinding) {
                    if let root = node.children.first {
                        SwiftUINodeView(node: root)
                            .navigationDestination(for: String.self) { route in
                                if let destination = node.children.dropFirst().first(where: { $0.route == route }) {
                                    SwiftUINodeView(node: destination)
                                        .navigationBarBackButtonHidden(!node.canNavigateBack)
                                }
                            }
                    }
                }
            }
        case "tabView":
            if #available(iOS 18.0, macOS 15.0, *), node.usesAdaptiveTabs {
                return erased {
                    AdaptiveTabViewNodeView(node: node)
                }
            }
            return erased {
                TabView(selection: Binding(
                    get: { node.selectedIndex },
                    set: { next in
                        node.selectedIndex = next
                        node.selectionChangedHandler?(next)
                    }
                )) {
                    ForEach(Array(node.children.enumerated()), id: \.element.id) { index, tab in
                        SwiftUINodeView(node: tab).tag(index)
                    }
                }
            }
        case "splitView":
            return erased {
                SplitViewNodeView(node: node)
            }
        case "tab":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .tabItem { Label(node.text, systemImage: node.imageName) }
                }
            }
        case "navigation":
            return erased {
                NavigationStack {
                    if let root = node.children.first {
                        SwiftUINodeView(node: root).navigationTitle(node.text)
                    }
                }
            }
        case "navigationLink":
            return erased {
                if let destination = node.children.first {
                    NavigationLink(destination: SwiftUINodeView(node: destination)) {
                        Text(node.text)
                    }
                }
            }
        case "sheet":
            return erased {
                if let content = node.children.first, node.children.count == 2 {
                    SwiftUINodeView(node: content)
                        .sheet(isPresented: Binding(
                            get: { node.isPresented },
                            set: { next in node.isPresented = next }
                        ), onDismiss: {
                            node.dismissedHandler?()
                        }) {
                            // The sheet body is built later than the guard above; the children
                            // can change in between (a theme redraw), so it reads them again.
                            if let modal = node.child(1) {
                                #if os(iOS)
                                if node.sheetDetentFraction > 0 {
                                    SwiftUINodeView(node: modal)
                                        .presentationDetents([.fraction(node.sheetDetentFraction)])
                                        .presentationBackgroundInteraction(.disabled)
                                } else {
                                    SwiftUINodeView(node: modal)
                                }
                                #else
                                SwiftUINodeView(node: modal)
                                #endif
                            }
                        }
                }
            }
        case "inspector":
            return erased {
                if let content = node.children.first, node.children.count == 2 {
                    SwiftUINodeView(node: content)
                        .inspector(isPresented: Binding(
                            get: { node.isPresented },
                            set: { next in node.applyInspectorPresentation(next) }
                        )) {
                            if let inspector = node.child(1) {
                                InspectorContentView(node: node, content: inspector)
                            }
                        }
                }
            }
        case "photoCover":
            return erased {
                PhotoCoverNodeView(node: node)
            }
        case "image":
            return symbolImage
        case "assetImage":
            // An image from the app's asset catalog at its own size (for example the launch
            // screen's logo); no label makes it decorative.
            return AnyView(Image(node.imageName)
                .accessibilityLabel(Text(node.text))
                .accessibilityHidden(node.text.isEmpty)
                .accessibilityIdentifier(node.automationId))
        case "photo":
            return erased {
                PhotoNodeView(node: node)
            }
        case "zoomPhoto":
            return erased {
                ZoomPhotoNodeView(node: node)
            }
        case "circle":
            return erased {
                Circle()
                    .fill(adaptiveColor(node.foregroundHex, node.foregroundDarkHex) ?? .clear)
                    .frame(width: node.diameter, height: node.diameter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityHidden(node.accessibilityLabelText.isEmpty)
            }
        case "toggle":
            return erased {
                Toggle(node.text, isOn: Binding(
                    get: { node.isOn },
                    set: { next in
                        node.isOn = next
                        node.boolChangedHandler?(next)
                    }
                ))
                .modifier(ToggleLabelsHidden(hidden: node.labelsHidden))
                .accessibilityIdentifier(node.automationId)
            }
        case "slider":
            return erased {
                Slider(value: Binding(
                    get: { node.value },
                    set: { next in
                        node.value = next
                        node.valueChangedHandler?(next)
                    }
                ), in: node.minimum...node.maximum) {
                    // The label view is the accessible name; adding .accessibilityLabel reads it twice.
                    Text(node.accessibilityLabelText)
                }
                .accessibilityIdentifier(node.automationId)
            }
        case "progress":
            return erased {
                let fraction = node.maximum > 0 ? node.value / node.maximum : 0
                ProgressView(value: node.maximum > 0 ? node.value : 0,
                             total: node.maximum > 0 ? node.maximum : 1)
                    .progressViewStyle(SourceHeightProgressStyle(
                        thickness: node.progressThickness,
                        tint: adaptiveColor(node.tintHex, node.tintDarkHex) ?? .accentColor,
                        track: adaptiveColor(node.progressTrackHex, node.progressTrackDarkHex)
                            ?? .secondary.opacity(0.2)))
                    .accessibilityLabel(node.accessibilityLabelText)
                    .accessibilityValue("\(Int((fraction * 100).rounded()))%")
                    .accessibilityIdentifier(node.automationId)
            }
        case "indeterminateProgress":
            return erased {
                ProgressView()
                    .progressViewStyle(.circular)
                    .accessibilityLabel(node.accessibilityLabelText)
                    .accessibilityIdentifier(node.automationId)
            }
        case "quickSuggestions":
            return erased {
                if let content = node.children.first, node.children.count == 2,
                   let field = quickAddField(in: content, id: node.quickAddAnchorId) {
                    QuickAddSuggestionsNodeView(node: node, field: field)
                }
            }
        case "starterOverlay":
            return erased {
                StarterBlockingOverlayNodeView(node: node)
            }
        case "deleteConfirmation":
            return erased {
                ResourceDeleteConfirmationNodeView(node: node)
            }
        case "picker":
            return erased {
                styledPicker(indexPicker)
            }
        case "valuePicker":
            return erased {
                styledPicker(valuePicker)
            }
        case "searchable":
            return erased {
                SearchableNodeView(node: node)
            }
        case "swipeRow":
            return erased {
                SwipeRowNodeView(node: node)
            }
        case "labeledContent":
            return erased {
                if let content = node.children.first {
                    LabeledContent {
                        // A field's text sits at the trailing edge, beside its label, as in
                        // Settings (a value Text already does).
                        SwiftUINodeView(node: content)
                            .multilineTextAlignment(.trailing)
                    } label: {
                        Text(node.text)
                    }
                }
            }
        case "label":
            return erased {
                Label(node.text, systemImage: node.imageName)
            }
        case "menu":
            return erased {
                if let label = node.children.first, label.kind != "button" {
                    Menu {
                        ForEach(node.children.dropFirst(), id: \.id) { SwiftUINodeView(node: $0) }
                    } label: {
                        SwiftUINodeView(node: label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.interaction, Rectangle())
                    }
                    .accessibilityValue(node.text)
                    .accessibilityIdentifier(node.automationId)
                } else {
                    Menu(node.text) {
                        ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                    }.accessibilityIdentifier(node.automationId)
                }
            }
        case "toolbar":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .toolbar {
                            // A Cancel-role Button takes the system's cancellation place (a
                            // sheet's leading edge), as SwiftUI's own Cancel does.
                            if let cancel = node.children.dropFirst().first(where: {
                                $0.kind == "button" && $0.buttonRole == "cancel"
                            }) {
                                ToolbarItem(placement: .cancellationAction) {
                                    SwiftUINodeView(node: cancel)
                                        .accessibilityShowsLargeContentViewer()
                                }
                            }
                            ToolbarItemGroup(placement: .automatic) {
                                ForEach(node.children.dropFirst().filter {
                                    !($0.kind == "button" && $0.buttonRole == "cancel")
                                }, id: \.id) { item in
                                    // A toolbar item is drawn as a hosted view, so it does not get
                                    // the bar's own large content viewer; long press shows its
                                    // title and symbol (as a tab does) while the viewer is on.
                                    SwiftUINodeView(node: item)
                                        .accessibilityShowsLargeContentViewer()
                                }
                            }
                        }
                }
            }
        case "alert":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .alert(node.text, isPresented: Binding(
                            get: { node.isPresented },
                            set: { next in
                                node.isPresented = next
                                if !next { node.dismissedHandler?() }
                            }
                        )) {
                            ForEach(node.children.dropFirst(), id: \.id) { SwiftUINodeView(node: $0) }
                        } message: {
                            Text(node.placeholder)
                        }
                }
            }
        case "confirmationDialog":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .confirmationDialog(node.text, isPresented: Binding(
                            get: { node.isPresented },
                            set: { next in
                                node.isPresented = next
                                if !next { node.dismissedHandler?() }
                            }
                        ), titleVisibility: .visible) {
                            ForEach(node.children.dropFirst(), id: \.id) { SwiftUINodeView(node: $0) }
                        }
                }
            }
        case "fileImporter":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .fileImporter(isPresented: Binding(
                            get: { node.isPresented },
                            set: { node.isPresented = $0 }
                        ), allowedContentTypes: [.plainText, .commaSeparatedText],
                            allowsMultipleSelection: false,
                            onCompletion: { result in
                                switch result {
                                case .success(let urls):
                                    if let url = urls.first { importFile(.success(url)) }
                                    else { node.fileImportErrorHandler?("readFailed") }
                                case .failure(let error):
                                    let failure = error as NSError
                                    if failure.domain == NSCocoaErrorDomain && failure.code == NSUserCancelledError {
                                        node.fileImportCancelledHandler?()
                                    } else {
                                        node.fileImportErrorHandler?("readFailed")
                                    }
                                }
                            },
                            onCancellation: { node.fileImportCancelledHandler?() })
                }
            }
        case "photoPicker":
            return erased {
                if let root = node.children.first {
                    SwiftUINodeView(node: root)
                        .photosPicker(isPresented: Binding(
                            get: { node.isPresented },
                            set: { node.applyPhotoPickerPresentation($0) }
                        ), selection: Binding<PhotosPickerItem?>(
                            get: { nil },
                            set: { item in if let item { node.receivePickedPhoto(item) } }
                        ), matching: .images)
                }
            }
        case "youTubePlayer":
            return erased {
                if !node.videoId.isEmpty {
                    MSUYouTubePlayerView(videoId: node.videoId)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .accessibilityIdentifier(node.automationId)
                }
            }
        default:
            return AnyView(EmptyView())
        }
    }

    private func erased<V: View>(@ViewBuilder _ view: () -> V) -> AnyView {
        AnyView(view())
    }
}

/// Inspector content: a trailing column in a regular horizontal size class, a
/// sheet in a compact one. Column widths apply only to the column; the sheet
/// detent applies only when SwiftUI presents the inspector as a sheet.
private struct InspectorContentView: View {
    @ObservedObject var node: MSUNode
    @ObservedObject var content: MSUNode

    var body: some View {
        columnWidth(SwiftUINodeView(node: content))
            #if os(iOS)
            .modifier(InspectorCompactDetent(fraction: node.sheetDetentFraction))
            #endif
    }

    @ViewBuilder
    private func columnWidth<V: View>(_ view: V) -> some View {
        let ideal = node.inspectorIdealWidth
        if ideal > 0 {
            view.inspectorColumnWidth(
                min: node.inspectorMinWidth > 0 ? CGFloat(node.inspectorMinWidth) : nil,
                ideal: CGFloat(ideal),
                max: node.inspectorMaxWidth > 0 ? CGFloat(node.inspectorMaxWidth) : nil)
        } else {
            view
        }
    }
}

#if os(iOS)
private struct InspectorCompactDetent: ViewModifier {
    let fraction: Double

    func body(content: Content) -> some View {
        if fraction > 0 {
            // The selection moves an already-presented sheet when the fraction
            // changes; a new detent set alone is not applied after presentation.
            let detent = PresentationDetent.fraction(fraction)
            content
                .presentationDetents([detent], selection: .constant(detent))
                .presentationBackgroundInteraction(.disabled)
        } else {
            content
        }
    }
}
#endif

/// Content filling the proposed space with a second view layered over its top
/// or bottom edge, inside the safe area (SwiftUI `overlay(alignment:)`). The
/// layer does not change the content's layout; an empty layer shows nothing.
struct OverlayNodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        // A navigation pop can re-render this node while its children are being
        // rebuilt; index only once both are present.
        if node.children.count == 2 {
            SwiftUINodeView(node: node.children[0])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: node.overlayEdge == "top" ? .top : .bottom) {
                    if let overlay = node.child(1) { SwiftUINodeView(node: overlay) }
                }
        }
    }
}

/// A toggle that shows only its switch (`labelsHidden`), keeping its text as the accessible
/// name, so a row can place the switch beside other content without a label taking the width.
struct ToggleLabelsHidden: ViewModifier {
    let hidden: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if hidden {
            content.labelsHidden()
        } else {
            content
        }
    }
}

/// Opt-in `fixedSize(horizontal:vertical:)`: the view keeps its ideal width and/or height, so a
/// badge or a short button beside a flexible title keeps its text on one line. A modifier keeps
/// the node view's body type small.
struct FixedSizing: ViewModifier {
    let horizontal: Bool
    let vertical: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if horizontal || vertical {
            content.fixedSize(horizontal: horizontal, vertical: vertical)
        } else {
            content
        }
    }
}

/// Opt-in `listRowBackground(Color.clear)`: inside a Form or List the row draws no background;
/// outside one it has no effect. Nothing is applied when off, so existing rows keep theirs.
struct ListRowBackgroundHidden: ViewModifier {
    let hidden: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if hidden {
            content.listRowBackground(Color.clear)
        } else {
            content
        }
    }
}

/// Opt-in `frame(width:)`: the view is exactly this wide whatever its container proposes. No
/// frame at all when off, so existing views keep their layout. A modifier keeps the node view's
/// body type small.
struct FixedWidthFrame: ViewModifier {
    let width: Double
    let alignment: Alignment

    @ViewBuilder
    func body(content: Content) -> some View {
        if width > 0 {
            content.frame(width: CGFloat(width), alignment: alignment)
        } else {
            content
        }
    }
}


/// One search token (`searchable(text:tokens:)`).
struct MSUSearchToken: Identifiable, Hashable {
    let id: String
    let title: String
}

/// The system search field over its content, with the node's tokens shown inside the field
/// (deleting one reports the rest) and focus following `focusRequested`, as a text field's does.
private struct SearchableNodeView: View {
    @ObservedObject var node: MSUNode
    @FocusState private var focused: Bool

    private var text: Binding<String> {
        Binding(
            get: { node.text },
            set: { next in
                node.text = next
                node.textChangedHandler?(next)
            }
        )
    }

    private var tokens: Binding<[MSUSearchToken]> {
        Binding(
            get: {
                zip(node.searchTokenIds, node.searchTokenTitles).map {
                    MSUSearchToken(id: $0.0, title: $0.1)
                }
            },
            set: { next in
                let ids = next.map(\.id)
                if ids == node.searchTokenIds { return }
                node.searchTokenIds = ids
                node.searchTokenTitles = next.map(\.title)
                node.selectedValueChangedHandler?(ids.joined(separator: "\u{1F}"))
            }
        )
    }

    var body: some View {
        if let root = node.children.first {
            SwiftUINodeView(node: root)
                .searchable(text: text, tokens: tokens, prompt: Text(node.placeholder)) { token in
                    Text(token.title)
                }
                // Return (Search) in the field: the node's submit action, as a text field's.
                .onSubmit(of: .search) { node.submitTextField() }
                .modifier(SearchFocus(focused: $focused))
                .modifier(SearchBottomBar(enabled: node.searchPlacement == "bottomBar"))
                .modifier(SearchKeepsToolbar(enabled: node.searchKeepsToolbar))
                .onChange(of: node.focusRequested, initial: true) { _, next in focused = next }
                .onChange(of: focused) { _, next in
                    if node.focusRequested != next { node.focusRequested = next }
                    node.focusChangedHandler?(next)
                }
        }
    }
}

/// `searchFocused` where the system has it (iOS 18, macOS 15).
private struct SearchFocus: ViewModifier {
    var focused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content.searchFocused(focused)
        } else {
            content
        }
    }
}

/// A list row with swipe actions: its first child is the row, then the trailing actions, then
/// `swipeLeadingCount` leading actions (`swipeActions(edge:)`). Neither edge runs an action on
/// a full swipe: the person taps the revealed action, so a long swipe never acts by itself.
private struct SwipeRowNodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        if let content = node.children.first {
            let actions = Array(node.children.dropFirst())
            let leading = min(max(node.swipeLeadingCount, 0), actions.count)
            let trailing = Array(actions.dropLast(leading))
            let leadingActions = Array(actions.suffix(leading))
            SwiftUINodeView(node: content)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    ForEach(trailing, id: \.id) { SwiftUINodeView(node: $0) }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    ForEach(leadingActions, id: \.id) { SwiftUINodeView(node: $0) }
                }
        }
    }
}

/// The search field in the bottom toolbar (iOS 26, `DefaultToolbarItem(kind: .search,
/// placement: .bottomBar)`); elsewhere the system's placement.
private struct SearchBottomBar: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        #if os(iOS)
        if enabled, #available(iOS 26.0, *) {
            content.toolbar {
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// `navigationSubtitle` where the system has it (iOS 26, macOS 11).
private struct NavigationSubtitle: ViewModifier {
    let text: String

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content.navigationSubtitle(text)
        } else {
            content
        }
        #else
        content.navigationSubtitle(text)
        #endif
    }
}

/// Keeps a toolbar's other items while searching (iOS 17.1); otherwise the system default.
private struct SearchKeepsToolbar: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 17.1, *) {
            content.searchPresentationToolbarBehavior(enabled ? .avoidHidingContent : .automatic)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
