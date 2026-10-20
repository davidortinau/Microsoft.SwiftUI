import Combine
import Foundation
import ImageIO
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
    @objc public var focusRequested = false { willSet { objectWillChange.send() } }
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
    @objc public var route = "" { willSet { objectWillChange.send() } }
    @objc public var fontStyle = "" { willSet { objectWillChange.send() } }
    @objc public var fontSize = 0.0 { willSet { objectWillChange.send() } }
    @objc public var fontWeight = 400 { willSet { objectWillChange.send() } }
    @objc public var fontPostScriptName = "" { willSet { objectWillChange.send() } }
    @objc public var lineHeightMultiple = 0.0 { willSet { objectWillChange.send() } }
    @objc public var preferredScheme = "" { willSet { objectWillChange.send() } }
    @objc public var buttonStyle = "" { willSet { objectWillChange.send() } }
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
    @objc public var horizontalAlignment = "leading" { willSet { objectWillChange.send() } }
    @objc public var adaptiveStackBelowWidth = 0.0 { willSet { objectWillChange.send() } }
    @objc public var minimumHeight = 0.0 { willSet { objectWillChange.send() } }
    @objc public var gridColumns = 2 { willSet { objectWillChange.send() } }
    @objc public var gridColumnMinimumWidths: [NSNumber] = [] { willSet { objectWillChange.send() } }
    @objc public var navigationTitle = "" { willSet { objectWillChange.send() } }
    @objc public var inlineNavigationTitle = false { willSet { objectWillChange.send() } }
    @objc public var centerWhenShort = false { willSet { objectWillChange.send() } }
    @objc public var nativeListCanvasHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListCanvasDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListRowHex = "" { willSet { objectWillChange.send() } }
    @objc public var nativeListRowDarkHex = "" { willSet { objectWillChange.send() } }
    @objc public var placeholderColorHex = "" { willSet { objectWillChange.send() } }
    @objc public var placeholderColorDarkHex = "" { willSet { objectWillChange.send() } }
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
    private var lastViewport: (width: Double, dynamicTypeSize: Int)?
    private(set) var decodedPhoto: CGImage? { willSet { objectWillChange.send() } }
    private var photoWasReported = false

    @objc public init(kind: String) {
        precondition([
            "text", "inlineText", "button", "buttonGroup", "textField", "textEditor", "vstack", "hstack",
            "scroll", "list", "navigation", "navigationLink", "sheet",
            "image", "toggle", "slider", "picker", "navigationStack",
            "tabView", "tab", "form", "section", "secureField",
            "valuePicker", "searchable", "menu", "alert",
            "confirmationDialog", "grid", "horizontalGrid", "fileImporter", "toolbar",
            "progress", "bottomInset", "circle", "divider", "indeterminateProgress",
            "photo", "zoomPhoto", "photoCover", "quickSuggestions",
            "starterOverlay", "deleteConfirmation"
        ].contains(kind), "Unsupported SwiftUI node kind: \(kind)")
        self.kind = kind
        super.init()
        if kind == "buttonGroup" {
            spacing = -2
            selectedIndex = -1
        }
    }

    @objc(insertChild:atIndex:)
    public func insertChild(_ child: MSUNode, at index: Int) {
        precondition(index >= 0 && index <= children.count, "Child index out of range")
        precondition(kind != "inlineText" || (child.kind == "text" && children.count < 2),
                     "Inline text accepts only two Text nodes")
        children.insert(child, at: index)
    }

    @objc(removeChildAtIndex:)
    public func removeChild(at index: Int) {
        precondition(index >= 0 && index < children.count, "Child index out of range")
        children.remove(at: index)
    }

    @objc public func clearChildren() {
        children.removeAll()
        path.removeAll()
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
        lastViewport = nil
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
    }

    @ViewBuilder
    var body: some View {
        if node.centerWhenShort {
            if #available(iOS 18.0, macOS 15.0, *) {
                ScrollView { rows }
                    .defaultScrollAnchor(.center, for: .alignment)
            } else {
                GeometryReader { viewport in
                    ScrollView {
                        rows.frame(minHeight: viewport.size.height, alignment: .center)
                    }
                }
            }
        } else {
            ScrollView { rows }
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
                                .frame(minWidth: CGFloat(truncating:
                                    node.gridColumnMinimumWidths[index]), alignment: .leading)
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

    @ViewBuilder
    var body: some View {
        if node.kind == "form" {
            canvas(Form {
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
            })
        } else {
            canvas(List {
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
            })
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
            SwiftUINodeView(node: node.children[1])
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            SwiftUINodeView(node: node.children[2])
                .frame(minWidth: 44, minHeight: 44)
                .background(.white.opacity(0.15), in: Circle())
                .padding(16)
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
    @Environment(\.fillsMSUButtonGroupWidth) private var fillsButtonGroupWidth
    @ScaledMetric(relativeTo: .body) private var bodyFontScale: CGFloat = 1

    private var textContent: Text {
        Text(node.text).underline(node.isUnderlined)
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

    var body: some View {
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
            .frame(maxWidth: node.fillsWidth
                ? node.maxWidth > 0 ? node.maxWidth : .infinity : nil,
                   alignment: horizontalAlignment)

        return surface(padded)
            .frame(maxWidth: node.fillsWidth && node.maxWidth > 0 ? .infinity : nil,
                   alignment: horizontalAlignment)
            .opacity(node.opacity)
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
        else if node.kind == "bottomInset" || node.kind == "hstack" ||
                    node.kind == "vstack" || node.kind == "buttonGroup" ||
                    node.kind == "quickSuggestions" || node.kind == "starterOverlay" ||
                    node.kind == "deleteConfirmation" || node.kind == "photoCover" {
            view.accessibilityElement(children: .contain)
                .accessibilityIdentifier(node.automationId)
        }
        else { view.accessibilityIdentifier(node.automationId) }
    }

    @ViewBuilder
    private func titled<V: View>(_ view: V) -> some View {
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
        if node.hidesTabBar { view.toolbar(.hidden, for: .tabBar) }
        else { view }
        #else
        view
        #endif
    }

    @ViewBuilder
    private func accessible<V: View>(_ view: V) -> some View {
        if node.accessibilityLabelText.isEmpty || node.kind == "textEditor" { view }
        else { view.accessibilityLabel(node.accessibilityLabelText) }
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
        let button = Button(action: { node.invokeAction() }) {
            if let label = node.children.first {
                buttonLabel(SwiftUINodeView(node: label), ellipticalShape: ellipse)
                    .accessibilityElement(children: .combine)
            } else {
                buttonLabel(Text(node.text), ellipticalShape: ellipse)
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
            ForEach(node.children.indices, id: \.self) { index in
                PickerOptionNodeView(node: node.children[index], index: index)
            }
        }
        .accessibilityIdentifier(node.automationId)
    }

    @ViewBuilder
    private func styledPicker<V: View>(_ picker: V) -> some View {
        if node.pickerStyle == "segmented" {
            picker.pickerStyle(.segmented)
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

    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case "text":
            if node.lineLimit > 0 {
                AnyView(textContent.lineLimit(node.lineLimit)
                    .accessibilityIdentifier(node.automationId))
            } else {
                textContent.accessibilityIdentifier(node.automationId)
            }
        case "inlineText":
            if node.children.count == 2 {
                InlineTextNodeView(leading: node.children[0], trailing: node.children[1])
            }
        case "divider":
            Divider().accessibilityHidden(true)
        case "button":
            styledButton
                .accessibilityAddTraits(node.accessibilitySelected ? .isSelected : [])
        case "textField", "textEditor", "secureField":
            TextInputNodeView(node: node)
        case "vstack":
            VStack(alignment: .leading, spacing: node.spacing) {
                ForEach(node.children, id: \.id) {
                    SwiftUINodeView(node: $0).id($0.id)
                }
            }
        case "hstack":
            if node.adaptiveStackBelowWidth > 0 {
                AdaptiveStackNodeView(node: node)
            } else {
                HStack(spacing: node.spacing) {
                    ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                }
            }
        case "buttonGroup":
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
        case "scroll":
            ScrollNodeView(node: node)
        case "bottomInset":
            if node.children.count == 2 {
                SwiftUINodeView(node: node.children[0])
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        SwiftUINodeView(node: node.children[1])
                    }
            }
        case "list", "form":
            NativeCollectionNodeView(node: node)
        case "section":
            Section {
                ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
            } header: {
                Text(node.text)
            }
        case "grid":
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: node.gridColumns),
                      spacing: node.spacing) {
                ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
            }
        case "horizontalGrid":
            HorizontalGridNodeView(node: node)
        case "navigationStack":
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
        case "tabView":
            TabView(selection: Binding(
                get: { node.selectedIndex },
                set: { next in
                    node.selectedIndex = next
                    node.selectionChangedHandler?(next)
                }
            )) {
                ForEach(node.children.indices, id: \.self) { index in
                    SwiftUINodeView(node: node.children[index]).tag(index)
                }
            }
        case "tab":
            if let root = node.children.first {
                SwiftUINodeView(node: root)
                    .tabItem { Label(node.text, systemImage: node.imageName) }
            }
        case "navigation":
            NavigationStack {
                if let root = node.children.first {
                    SwiftUINodeView(node: root).navigationTitle(node.text)
                }
            }
        case "navigationLink":
            if let destination = node.children.first {
                NavigationLink(destination: SwiftUINodeView(node: destination)) {
                    Text(node.text)
                }
            }
        case "sheet":
            if let content = node.children.first, node.children.count == 2 {
                SwiftUINodeView(node: content)
                    .sheet(isPresented: Binding(
                        get: { node.isPresented },
                        set: { next in node.isPresented = next }
                    ), onDismiss: {
                        node.dismissedHandler?()
                    }) {
                        #if os(iOS)
                        if node.sheetDetentFraction > 0 {
                            SwiftUINodeView(node: node.children[1])
                                .presentationDetents([.fraction(node.sheetDetentFraction)])
                                .presentationBackgroundInteraction(.disabled)
                        } else {
                            SwiftUINodeView(node: node.children[1])
                        }
                        #else
                        SwiftUINodeView(node: node.children[1])
                        #endif
                    }
            }
        case "photoCover":
            PhotoCoverNodeView(node: node)
        case "image":
            symbolImage
        case "photo":
            PhotoNodeView(node: node)
        case "zoomPhoto":
            ZoomPhotoNodeView(node: node)
        case "circle":
            Circle()
                .fill(adaptiveColor(node.foregroundHex, node.foregroundDarkHex) ?? .clear)
                .frame(width: node.diameter, height: node.diameter)
                .accessibilityElement(children: .ignore)
                .accessibilityHidden(node.accessibilityLabelText.isEmpty)
        case "toggle":
            Toggle(node.text, isOn: Binding(
                get: { node.isOn },
                set: { next in
                    node.isOn = next
                    node.boolChangedHandler?(next)
                }
            )).accessibilityIdentifier(node.automationId)
        case "slider":
            Slider(value: Binding(
                get: { node.value },
                set: { next in
                    node.value = next
                    node.valueChangedHandler?(next)
                }
            ), in: node.minimum...node.maximum) {
                Text(node.accessibilityLabelText)
            }
            .accessibilityLabel(node.accessibilityLabelText)
            .accessibilityIdentifier(node.automationId)
        case "progress":
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
        case "indeterminateProgress":
            ProgressView()
                .progressViewStyle(.circular)
                .accessibilityLabel(node.accessibilityLabelText)
                .accessibilityIdentifier(node.automationId)
        case "quickSuggestions":
            if let content = node.children.first, node.children.count == 2,
               let field = quickAddField(in: content, id: node.quickAddAnchorId) {
                QuickAddSuggestionsNodeView(node: node, field: field)
            }
        case "starterOverlay":
            StarterBlockingOverlayNodeView(node: node)
        case "deleteConfirmation":
            ResourceDeleteConfirmationNodeView(node: node)
        case "picker":
            styledPicker(indexPicker)
        case "valuePicker":
            styledPicker(valuePicker)
        case "searchable":
            if let root = node.children.first {
                SwiftUINodeView(node: root)
                    .searchable(text: Binding(
                        get: { node.text },
                        set: { next in
                            node.text = next
                            node.textChangedHandler?(next)
                        }
                    ), prompt: node.placeholder)
            }
        case "menu":
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
        case "toolbar":
            if let root = node.children.first {
                SwiftUINodeView(node: root)
                    .toolbar {
                        ToolbarItemGroup(placement: .automatic) {
                            ForEach(node.children.dropFirst(), id: \.id) { item in
                                SwiftUINodeView(node: item)
                            }
                        }
                    }
            }
        case "alert":
            if let root = node.children.first {
                SwiftUINodeView(node: root)
                    .alert(node.text, isPresented: Binding(
                        get: { node.isPresented },
                        set: { node.isPresented = $0 }
                    )) {
                        ForEach(node.children.dropFirst(), id: \.id) { SwiftUINodeView(node: $0) }
                    } message: {
                        Text(node.placeholder)
                    }
            }
        case "confirmationDialog":
            if let root = node.children.first {
                SwiftUINodeView(node: root)
                    .confirmationDialog(node.text, isPresented: Binding(
                        get: { node.isPresented },
                        set: { node.isPresented = $0 }
                    ), titleVisibility: .visible) {
                        ForEach(node.children.dropFirst(), id: \.id) { SwiftUINodeView(node: $0) }
                    }
            }
        case "fileImporter":
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
        default:
            EmptyView()
        }
    }
}
