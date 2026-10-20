import Combine
import XCTest
@testable import MicrosoftSwiftUIShim
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
import SwiftUI
#endif

final class NodeTests: XCTestCase {
    func testNodesRetainStateAndChildren() {
        let root = MSUBridge.makeNode(kind: "vstack")
        let title = MSUBridge.makeNode(kind: "text")
        title.text = "Before"
        root.insertChild(title, at: 0)

        title.text = "After"
        XCTAssertEqual(root.children.first?.text, "After")
        XCTAssertEqual(root.children.count, 1)
        root.removeChild(at: 0)
        XCTAssertTrue(root.children.isEmpty)
    }

    @MainActor
    func testTextLineLimitDefaultsUnlimitedAndPublishesWithoutReplacingNode() {
        let regular = MSUBridge.makeNode(kind: "text")
        let title = MSUBridge.makeNode(kind: "text")
        let identity = title.id
        XCTAssertEqual(regular.lineLimit, 0)
        XCTAssertEqual(title.lineLimit, 0)
        XCTAssertTrue(title.responds(to: NSSelectorFromString("setLineLimit:")),
                      "A title MSUNode without setLineLimit: crashes with an unrecognized selector.")

        var updates = 0
        let subscription = title.objectWillChange.sink { updates += 1 }
        title.lineLimit = 1
        XCTAssertEqual(title.lineLimit, 1)
        XCTAssertEqual(title.id, identity)
        XCTAssertEqual(regular.lineLimit, 0)
        XCTAssertEqual(updates, 1)
        title.text = "A full title remains available for accessibility"
        XCTAssertEqual(title.text,
                       "A full title remains available for accessibility")
        XCTAssertEqual(updates, 2)
        _ = SwiftUINodeView(node: title).body
        withExtendedLifetime(subscription) {}
    }

    @MainActor
    func testInlineTextUsesLiteralUnicodeAndSeparatelyObservableStyledRuns() {
        let leading = MSUBridge.makeNode(kind: "text")
        leading.text = "아무나 골라 주세요 *[literal]*"
        leading.fontSize = 17
        leading.fontWeight = 700
        leading.lineHeightMultiple = 1.29
        leading.foregroundHex = "#0F172A"
        leading.foregroundDarkHex = "#F0F9FF"
        let trailing = MSUBridge.makeNode(kind: "text")
        trailing.text = "  Pick anyone/anything please\nnearby"
        trailing.fontSize = 17
        trailing.fontWeight = 400
        trailing.foregroundHex = "#475569"
        trailing.foregroundDarkHex = "#BAE6FD"
        let inline = MSUBridge.makeNode(kind: "inlineText")
        inline.insertChild(leading, at: 0)
        inline.insertChild(trailing, at: 1)
        func text() -> AttributedString {
            InlineTextNodeView.attributedText(
                leading: leading, trailing: trailing,
                colorScheme: .light, bodyFontScale: 1)
        }

        XCTAssertEqual(String(text().characters),
                       "아무나 골라 주세요 *[literal]*  Pick anyone/anything please\nnearby")
        XCTAssertEqual(Array(text().runs).count, 2)
        XCTAssertNotNil(Array(text().runs)[0].font)
        XCTAssertNotNil(Array(text().runs)[1].font)
        XCTAssertNotNil(Array(text().runs)[0].foregroundColor)
        XCTAssertNotNil(Array(text().runs)[1].foregroundColor)
        let dark = InlineTextNodeView.attributedText(
            leading: leading, trailing: trailing,
            colorScheme: .dark, bodyFontScale: 1)
        XCTAssertNotEqual(Array(text().runs)[0].foregroundColor,
                          Array(dark.runs)[0].foregroundColor)
        XCTAssertNotEqual(Array(text().runs)[1].foregroundColor,
                          Array(dark.runs)[1].foregroundColor)
        var leadingUpdates = 0
        var trailingUpdates = 0
        let firstSubscription = leading.objectWillChange.sink { leadingUpdates += 1 }
        let secondSubscription = trailing.objectWillChange.sink { trailingUpdates += 1 }
        leading.fontSize = 21.25
        trailing.foregroundHex = "#334155"
        XCTAssertEqual(leadingUpdates, 1)
        XCTAssertEqual(trailingUpdates, 1)
        trailing.text = ""
        XCTAssertEqual(String(text().characters),
                       "아무나 골라 주세요 *[literal]*")
        XCTAssertEqual(inline.children.map(\.kind), ["text", "text"])
        withExtendedLifetime((firstSubscription, secondSubscription)) {}
    }

    func testCallbacksAndSelectionState() {
        let picker = MSUBridge.makeNode(kind: "picker")
        var selected = -1
        picker.setSelectionChangedHandler { selected = $0 }
        picker.selectedIndex = 1
        picker.selectionChangedHandler?(picker.selectedIndex)

        XCTAssertEqual(selected, 1)
        XCTAssertEqual(picker.selectedIndex, 1)
    }

    func testButtonInvokesRegisteredAction() {
        let button = MSUBridge.makeNode(kind: "button")
        var taps = 0
        button.setTapHandler { taps += 1 }
        button.invokeAction()
        XCTAssertEqual(taps, 1)
        button.clearHandlers()
        button.invokeAction()
        XCTAssertEqual(taps, 1)
    }

    func testDisabledButtonDoesNotInvokeAndCompositeLabelIsOwned() {
        let button = MSUBridge.makeNode(kind: "button")
        let label = MSUBridge.makeNode(kind: "vstack")
        button.insertChild(label, at: 0)
        var taps = 0
        button.setTapHandler { taps += 1 }
        button.isEnabled = false
        button.invokeAction()
        XCTAssertEqual(taps, 0)
        button.isEnabled = true
        button.invokeAction()
        XCTAssertEqual(taps, 1)
        XCTAssertTrue(button.children.first === label)
    }

    func testCustomButtonAppearanceIsOptInAndRetainsNativeDisabledActionGuard() {
        let plain = MSUBridge.makeNode(kind: "button")
        XCTAssertFalse(plain.hasButtonAppearance)
        XCTAssertFalse(plain.hasButtonEllipticalCornerRadii)
        XCTAssertEqual(plain.buttonDisabledOpacity, 0.65)
        XCTAssertEqual(plain.buttonBorderWidth, 1)
        plain.buttonBorderWidth = 2
        plain.buttonCornerTopLeftX = 255
        plain.hasButtonEllipticalCornerRadii = true
        XCTAssertFalse(plain.hasButtonAppearance)

        let button = MSUBridge.makeNode(kind: "button")
        button.buttonStyle = "plain"
        button.buttonFillHex = ""
        button.buttonFillDarkHex = ""
        button.buttonBorderHex = "#6B7888"
        button.buttonBorderDarkHex = "#93A3C7"
        button.buttonCornerRadius = 25
        button.buttonDisabledOpacity = 0.65
        button.hasButtonAppearance = true
        XCTAssertEqual(button.buttonBorderWidth, 1)
        var updates = 0
        let subscription = button.objectWillChange.sink { updates += 1 }
        button.buttonBorderWidth = 2
        XCTAssertEqual(button.buttonBorderWidth, 2)
        button.buttonBorderWidth = 1
        XCTAssertEqual(updates, 2)
        withExtendedLifetime(subscription) {}
        var taps = 0
        button.setTapHandler { taps += 1 }
        button.isEnabled = false
        button.invokeAction()
        XCTAssertEqual(taps, 0)
        XCTAssertTrue(button.hasButtonAppearance)
        XCTAssertEqual(button.buttonFillHex, "")
        XCTAssertEqual(button.buttonBorderDarkHex, "#93A3C7")
        XCTAssertEqual(button.buttonCornerRadius, 25)
        XCTAssertFalse(button.hasButtonEllipticalCornerRadii)
        _ = SwiftUINodeView(node: button).body
        button.isEnabled = true
        button.invokeAction()
        XCTAssertEqual(taps, 1)
        button.clearHandlers()
        button.invokeAction()
        XCTAssertEqual(taps, 1)
    }

    func testClearButtonBorderKeepsTheTwoPointInsetAndExistingOpaqueDefault() {
        let plain = MSUBridge.makeNode(kind: "button")
        XCTAssertEqual(plain.clearButtonBorderInset, 0)
        let button = MSUBridge.makeNode(kind: "button")
        button.buttonBorderWidth = 2
        button.buttonFillHex = ""
        button.buttonFillDarkHex = ""
        button.buttonBorderHex = ""
        button.buttonBorderDarkHex = ""
        button.buttonCornerRadius = 25
        button.hasButtonEllipticalCornerRadii = true
        button.hasButtonAppearance = true
        XCTAssertEqual(button.clearButtonBorderInset, 2)
        button.buttonBorderHex = "#000000"
        button.buttonBorderDarkHex = "#000000"
        XCTAssertEqual(button.clearButtonBorderInset, 0)
        button.buttonBorderHex = ""
        button.buttonBorderDarkHex = ""
        XCTAssertEqual(button.clearButtonBorderInset, 2)
        XCTAssertTrue(button.hasButtonEllipticalCornerRadii)
        XCTAssertTrue(button.hasButtonAppearance)
        XCTAssertEqual(button.buttonDisabledOpacity, 0.65)
    }

    func testButtonGroupOverlapsTwoPointsAndWrapsAtIntrinsicWidthsInOriginalOrder() {
        let group = MSUBridge.makeNode(kind: "buttonGroup")
        XCTAssertEqual(group.spacing, -2)
        XCTAssertEqual(group.selectedIndex, -1)
        XCTAssertFalse(group.buttonGroupWraps)
        XCTAssertEqual(group.buttonGroupOverlap, 2)
        XCTAssertFalse(group.buttonGroupFillAvailableWidth)
        let buttons = (0..<6).map { _ in MSUBridge.makeNode(kind: "button") }
        buttons.forEach { group.insertChild($0, at: group.children.count) }
        group.buttonGroupWraps = true
        group.selectedIndex = 3

        let sizes = [CGSize(width: 110, height: 44), CGSize(width: 90, height: 44),
                     CGSize(width: 96, height: 52), CGSize(width: 108, height: 44),
                     CGSize(width: 104, height: 44), CGSize(width: 72, height: 44)]
        let wide = ButtonGroupLayout.plan(sizes: sizes, availableWidth: 400, wraps: true)
        XCTAssertEqual(wide.positions[1].x, 108)
        XCTAssertEqual(wide.positions[3].y, 4)
        XCTAssertEqual(wide.positions[4].x, -2)
        XCTAssertEqual(wide.positions[4].y, 52)
        XCTAssertEqual(wide.size.height, 96)
        let narrow = ButtonGroupLayout.plan(sizes: sizes, availableWidth: 250, wraps: true)
        XCTAssertEqual(narrow.positions[2].x, -2)
        XCTAssertEqual(narrow.positions[2].y, 44)
        XCTAssertEqual(narrow.positions[4].y, 96)
        XCTAssertEqual(narrow.size.height, 140)
        let single = ButtonGroupLayout.plan(sizes: sizes, availableWidth: 250, wraps: false)
        XCTAssertEqual(single.positions[1].x, 108)
        XCTAssertEqual(single.positions[5].y, 4)
        XCTAssertEqual(single.size.width, 570)
        XCTAssertEqual(group.children.map(\.id), buttons.map(\.id))
        XCTAssertEqual(group.selectedIndex, 3)
        _ = SwiftUINodeView(node: group).body
    }

    func testButtonGroupLayoutDistributesOnlyPositiveSurplusOverIntrinsicWidths() {
        let sizes = [CGSize(width: 113.67, height: 44),
                     CGSize(width: 138, height: 44)]
        let defaultWidths = ButtonGroupLayout.fillingWidths(
            sizes: sizes, availableWidth: 378, overlap: 2)
        XCTAssertEqual(defaultWidths[0], 177.835, accuracy: 0.0001)
        XCTAssertEqual(defaultWidths[1], 202.165, accuracy: 0.0001)
        XCTAssertEqual(defaultWidths[1] - defaultWidths[0], 24.33, accuracy: 0.0001)
        let defaultPlan = ButtonGroupLayout.plan(
            sizes: zip(defaultWidths, sizes).map { CGSize(width: $0.0, height: $0.1.height) },
            availableWidth: 378, wraps: false)
        XCTAssertEqual(defaultPlan.positions[0].x, 0)
        XCTAssertEqual(defaultPlan.positions[1].x, 175.835, accuracy: 0.0001)
        XCTAssertEqual(defaultPlan.size.width, 378, accuracy: 0.0001)

        let onePointWidths = ButtonGroupLayout.fillingWidths(
            sizes: sizes, availableWidth: 378, overlap: 1)
        XCTAssertEqual(onePointWidths[0], 177.335, accuracy: 0.0001)
        XCTAssertEqual(onePointWidths[1], 201.665, accuracy: 0.0001)
        let onePointPlan = ButtonGroupLayout.plan(
            sizes: zip(onePointWidths, sizes).map { CGSize(width: $0.0, height: $0.1.height) },
            availableWidth: 378, wraps: false, overlap: 1)
        XCTAssertEqual(onePointPlan.positions[1].x, 176.335, accuracy: 0.0001)
        XCTAssertEqual(onePointPlan.size.width, 378, accuracy: 0.0001)
        XCTAssertEqual(ButtonGroupLayout.plan(
            sizes: sizes, availableWidth: nil, wraps: false).size.width, 249.67,
            accuracy: 0.0001)
        XCTAssertEqual(ButtonGroupLayout.plan(
            sizes: sizes, availableWidth: nil, wraps: false, overlap: 1).size.width,
            250.67, accuracy: 0.0001)
        XCTAssertEqual(ButtonGroupLayout.fillingWidths(
            sizes: sizes, availableWidth: 249.67, overlap: 2),
            sizes.map(\.width))

        let six = [CGSize(width: 110, height: 44), CGSize(width: 90, height: 44),
                   CGSize(width: 96, height: 52), CGSize(width: 108, height: 44),
                   CGSize(width: 104, height: 44), CGSize(width: 72, height: 44)]
        for overlap: CGFloat in [1, 2] {
            let wrapped = ButtonGroupLayout.plan(
                sizes: six, availableWidth: 250, wraps: true, overlap: overlap)
            XCTAssertEqual(wrapped.positions[2].x, -overlap)
            XCTAssertEqual(wrapped.positions[2].y, 44)
            XCTAssertEqual(wrapped.positions[4].y, 96)
            XCTAssertEqual(wrapped.size.height, 140)
        }

        let group = MSUBridge.makeNode(kind: "buttonGroup")
        var updates = 0
        let subscription = group.objectWillChange.sink { updates += 1 }
        group.buttonGroupOverlap = 1
        group.buttonGroupFillAvailableWidth = true
        XCTAssertEqual(updates, 2)
        XCTAssertEqual(group.buttonGroupOverlap, 1)
        XCTAssertTrue(group.buttonGroupFillAvailableWidth)
        XCTAssertEqual(group.spacing, -2)
        withExtendedLifetime(subscription) {}
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testInlineTextWrapsLongTermsWithoutMovingTheTrailingAction() {
        struct CapturePlacement: Layout {
            let record: (CGRect) -> Void

            func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                              cache: inout ()) -> CGSize {
                subviews[0].sizeThatFits(proposal)
            }

            func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                               subviews: Subviews, cache: inout ()) {
                record(bounds)
                subviews[0].place(at: bounds.origin, anchor: .topLeading,
                                  proposal: ProposedViewSize(bounds.size))
            }
        }

        let leading = MSUBridge.makeNode(kind: "text")
        leading.text = "강남"
        leading.fontSize = 17
        leading.fontWeight = 700
        leading.lineHeightMultiple = 1.29
        let trailing = MSUBridge.makeNode(kind: "text")
        trailing.text = "  nearby"
        trailing.fontSize = 17
        trailing.fontWeight = 400
        let inline = MSUBridge.makeNode(kind: "inlineText")
        inline.fillsWidth = true
        inline.insertChild(leading, at: 0)
        inline.insertChild(trailing, at: 1)
        let remove = MSUBridge.makeNode(kind: "button")
        remove.buttonStyle = "plain"
        remove.minimumHeight = 44
        let icon = MSUBridge.makeNode(kind: "image")
        icon.imageName = "xmark"
        remove.insertChild(icon, at: 0)

        func frames(at width: CGFloat) -> (text: CGRect, action: CGRect) {
            var textFrame = CGRect.null
            var actionFrame = CGRect.null
            let host = NSHostingView(rootView: HStack(spacing: 8) {
                CapturePlacement(record: { textFrame = $0 }) {
                    SwiftUINodeView(node: inline)
                }
                CapturePlacement(record: { actionFrame = $0 }) {
                    SwiftUINodeView(node: remove)
                }
            }.frame(width: width, alignment: .leading))
            host.frame = CGRect(x: 0, y: 0, width: width, height: 400)
            _ = host.fittingSize
            host.layoutSubtreeIfNeeded()
            return (textFrame, actionFrame)
        }

        let short = frames(at: 280)
        leading.text = "아무나 골라 주세요"
        trailing.text = "  Pick anyone/anything please, even when the translation "
            + "runs onto a second or third line."
        let long = frames(at: 280)
        XCTAssertGreaterThan(long.text.height, short.text.height + 15)
        XCTAssertEqual(long.text.minX, short.text.minX, accuracy: 0.5)
        XCTAssertEqual(long.action.maxX, short.action.maxX, accuracy: 0.5)
        XCTAssertEqual(long.action.maxX, 280, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(long.action.minX, long.text.maxX - 0.5)
        XCTAssertLessThan(long.action.height, long.text.height)

        trailing.text = ""
        leading.text = "아무나골라주세요아무나골라주세요아무나골라주세요"
        let noTranslation = frames(at: 245)
        XCTAssertGreaterThan(noTranslation.text.height, short.text.height + 15)
        XCTAssertEqual(noTranslation.action.maxX, 245, accuracy: 0.5)
        leading.fontSize = 24
        trailing.fontSize = 24
        trailing.text = "  An enlarged translation that must remain completely "
            + "legible at narrow widths without moving the delete action."
        let enlarged = frames(at: 245)
        XCTAssertGreaterThan(enlarged.text.height, long.text.height)
        XCTAssertEqual(enlarged.action.maxX, 245, accuracy: 0.5)
    }

    @MainActor
    func testFiniteWidthGroupPlacesUnequalOriginalSwiftUIButtonsAtTheirAllocatedWidths() {
        struct CapturePlacement: Layout {
            let record: (CGRect) -> Void

            func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews,
                              cache: inout ()) -> CGSize {
                subviews[0].sizeThatFits(proposal)
            }

            func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                               subviews: Subviews, cache: inout ()) {
                record(bounds)
                subviews[0].place(at: bounds.origin, anchor: .topLeading,
                                  proposal: ProposedViewSize(bounds.size))
            }
        }

        var frames: [Int: CGRect] = [:]
        func originalButton(_ index: Int, width: CGFloat) -> some View {
            CapturePlacement(record: { frames[index] = $0 }) {
                Button(action: {}) {
                    Text(index == 0 ? "Today" : "Choose Your Own")
                        .frame(width: width, height: 44)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("original.group.\(index)")
            }
        }

        let filled = ButtonGroupLayout(wraps: false, overlap: 2, fillAvailableWidth: true) {
            originalButton(0, width: 113.67)
            originalButton(1, width: 138)
        }
        let host = NSHostingView(rootView: filled.frame(width: 378, alignment: .leading))
        host.frame = CGRect(x: 0, y: 0, width: 378, height: 44)
        _ = host.fittingSize
        host.layoutSubtreeIfNeeded()
        guard let first = frames[0], let second = frames[1] else {
            XCTFail("The native layout did not place both original buttons.")
            return
        }
        XCTAssertEqual(first.minX, 0, accuracy: 0.01)
        XCTAssertEqual(first.width, 177.835, accuracy: 0.01)
        XCTAssertEqual(second.minX, 175.835, accuracy: 0.01)
        XCTAssertEqual(second.width, 202.165, accuracy: 0.01)
        XCTAssertEqual(second.maxX, 378, accuracy: 0.01)

        frames.removeAll()
        let intrinsic = ButtonGroupLayout(wraps: false, overlap: 2,
                                          fillAvailableWidth: false) {
            originalButton(0, width: 113.67)
            originalButton(1, width: 138)
        }
        let unfilledHost = NSHostingView(rootView: intrinsic.frame(
            width: 378, alignment: .leading))
        unfilledHost.frame = CGRect(x: 0, y: 0, width: 378, height: 44)
        _ = unfilledHost.fittingSize
        unfilledHost.layoutSubtreeIfNeeded()
        guard let originalFirst = frames[0], let originalSecond = frames[1] else {
            XCTFail("The intrinsic native layout did not place both original buttons.")
            return
        }
        XCTAssertEqual(originalFirst.width, 113.67, accuracy: 0.01)
        XCTAssertEqual(originalSecond.minX, 111.67, accuracy: 0.01)
        XCTAssertEqual(originalSecond.maxX, 249.67, accuracy: 0.01)

        frames.removeAll()
        let wrapping = ButtonGroupLayout(wraps: true, overlap: 2,
                                         fillAvailableWidth: true) {
            originalButton(0, width: 113.67)
            originalButton(1, width: 138)
        }
        let wrappingHost = NSHostingView(rootView: wrapping.frame(
            width: 378, alignment: .leading))
        wrappingHost.frame = CGRect(x: 0, y: 0, width: 378, height: 44)
        _ = wrappingHost.fittingSize
        wrappingHost.layoutSubtreeIfNeeded()
        guard let wrappingFirst = frames[0], let wrappingSecond = frames[1] else {
            XCTFail("The wrapping native layout did not place both original buttons.")
            return
        }
        XCTAssertEqual(wrappingFirst.width, 113.67, accuracy: 0.01)
        XCTAssertEqual(wrappingSecond.minX, 111.67, accuracy: 0.01)
        XCTAssertEqual(wrappingSecond.maxX, 249.67, accuracy: 0.01)
    }

    @MainActor
    func testClearStrokeAddsFourPointsToTheActualSwiftUIButtonBox() {
        func button(border: String) -> MSUNode {
            let node = MSUBridge.makeNode(kind: "button")
            let label = MSUBridge.makeNode(kind: "text")
            label.text = "Logout"
            label.paddingLeft = 16
            label.paddingRight = 16
            label.paddingTop = 6
            label.paddingBottom = 6
            node.insertChild(label, at: 0)
            node.buttonStyle = "plain"
            node.buttonBorderHex = border
            node.buttonBorderDarkHex = border
            node.buttonBorderWidth = 2
            node.buttonCornerRadius = 25
            node.buttonCornerTopLeftX = 255
            node.buttonCornerTopLeftY = 25
            node.hasButtonEllipticalCornerRadii = true
            node.hasButtonAppearance = true
            return node
        }
        let clear = button(border: "")
        let opaque = button(border: "#000000")
        let clearSize = NSHostingView(rootView: SwiftUINodeView(node: clear)).fittingSize
        let opaqueSize = NSHostingView(rootView: SwiftUINodeView(node: opaque)).fittingSize
        XCTAssertEqual(clearSize.width - opaqueSize.width, 4, accuracy: 0.25)
        XCTAssertEqual(clearSize.height - opaqueSize.height, 4, accuracy: 0.25)
    }

    @MainActor
    func testButtonCirclePaintsFortyFourPointSquaresForDifferentSymbolsAndAppearanceStates() {
        let ordinary = MSUBridge.makeNode(kind: "button")
        XCTAssertEqual(ordinary.buttonCircleDiameter, 0)

        for symbol in ["speaker.wave.2", "info.circle", "photo", "quote.bubble"] {
            let button = MSUBridge.makeNode(kind: "button")
            let image = MSUBridge.makeNode(kind: "image")
            image.imageName = symbol
            button.insertChild(image, at: 0)
            button.buttonStyle = "bordered"
            button.buttonFillHex = ""
            button.buttonFillDarkHex = ""
            button.buttonBorderHex = "#6B7888"
            button.buttonBorderDarkHex = "#93A3C7"
            button.buttonCornerRadius = 22
            button.buttonCircleDiameter = 44
            button.hasButtonAppearance = true
            XCTAssertTrue(button.responds(to:
                NSSelectorFromString("setButtonCircleDiameter:")))
            var taps = 0
            button.setTapHandler { taps += 1 }

            for scheme in [ColorScheme.light, .dark] {
                for textSize in [DynamicTypeSize.large, .accessibility3] {
                    for enabled in [true, false] {
                        button.isEnabled = enabled
                        let host = NSHostingView(rootView: SwiftUINodeView(node: button)
                            .environment(\.colorScheme, scheme)
                            .environment(\.dynamicTypeSize, textSize))
                        let size = host.fittingSize
                        XCTAssertEqual(size.width, 44, accuracy: 0.25,
                            "\(symbol) \(scheme) \(textSize) enabled:\(enabled)")
                        XCTAssertEqual(size.height, 44, accuracy: 0.25,
                            "\(symbol) \(scheme) \(textSize) enabled:\(enabled)")
                        button.invokeAction()
                        XCTAssertEqual(taps, enabled ? 1 : 0)
                        if enabled { taps = 0 }
                    }
                }
            }
        }
    }

    @MainActor
    func testFixedSymbolsStayInsideCircularButtonsAtAccessibilitySizes() {
        let ordinary = MSUBridge.makeNode(kind: "image")
        XCTAssertEqual(ordinary.fixedSymbolSize, 0)
        for symbol in ["speaker.wave.2", "info.circle", "photo", "quote.bubble"] {
            let icon = MSUBridge.makeNode(kind: "image")
            icon.imageName = symbol
            let button = MSUBridge.makeNode(kind: "button")
            button.insertChild(icon, at: 0)
            button.hasButtonAppearance = true
            button.buttonCornerRadius = 22
            button.buttonCircleDiameter = 44
            button.buttonBorderHex = "#6B7888"
            button.buttonBorderDarkHex = "#93A3C7"
            button.buttonBorderWidth = 2
            XCTAssertTrue(icon.responds(to: NSSelectorFromString("setFixedSymbolSize:")))

            for pointSize in [14.0, 21.0] {
                icon.fixedSymbolSize = pointSize
                for scheme in [ColorScheme.light, .dark] {
                    var normalSize = CGSize.zero
                    for textSize in [DynamicTypeSize.large, .accessibility5] {
                        let environment = SwiftUINodeView(node: icon)
                            .environment(\.colorScheme, scheme)
                            .environment(\.dynamicTypeSize, textSize)
                        let symbolSize = NSHostingView(rootView: environment).fittingSize
                        XCTAssertLessThan(symbolSize.width, 40, "\(symbol) \(pointSize) \(textSize)")
                        XCTAssertLessThan(symbolSize.height, 40, "\(symbol) \(pointSize) \(textSize)")
                        if textSize == .large {
                            normalSize = symbolSize
                        } else {
                            XCTAssertEqual(symbolSize.width, normalSize.width, accuracy: 0.25)
                            XCTAssertEqual(symbolSize.height, normalSize.height, accuracy: 0.25)
                        }
                        let circle = NSHostingView(rootView: SwiftUINodeView(node: button)
                            .environment(\.colorScheme, scheme)
                            .environment(\.dynamicTypeSize, textSize)).fittingSize
                        XCTAssertEqual(circle.width, 44, accuracy: 0.25)
                        XCTAssertEqual(circle.height, 44, accuracy: 0.25)
                    }
                }
            }
        }
    }
    #endif

    func testRealButtonShadowOffsetDefaultsToZeroAndPublishesChanges() {
        let button = MSUBridge.makeNode(kind: "button")
        XCTAssertEqual(button.shadowOffsetX, 0)
        var updates = 0
        let subscription = button.objectWillChange.sink { updates += 1 }
        button.shadowOffsetX = 3
        XCTAssertEqual(button.shadowOffsetX, 3)
        button.shadowOffsetX = -2.5
        XCTAssertEqual(button.shadowOffsetX, -2.5)
        XCTAssertEqual(updates, 2)
        withExtendedLifetime(subscription) {}

        button.buttonFillHex = ""
        button.buttonFillDarkHex = ""
        button.buttonBorderHex = "#000000"
        button.buttonBorderDarkHex = "#000000"
        button.buttonCornerRadius = 4
        button.hasButtonAppearance = true
        button.shadowHex = "#000000"
        button.shadowDarkHex = "#000000"
        button.shadowOpacity = 1
        button.shadowOffsetY = 3
        _ = SwiftUINodeView(node: button).body
    }

    func testEllipticalButtonCornersNormalizeOriginalBoundsAndInsetWithoutRescaling() {
        let shape = ButtonEllipticalCornerShape(
            topLeft: CGSize(width: 255, height: 25),
            topRight: CGSize(width: 25, height: 225),
            bottomRight: CGSize(width: 225, height: 25),
            bottomLeft: CGSize(width: 25, height: 255))
        for width: CGFloat in [134, 160, 240] {
            let rect = CGRect(x: 0, y: 0, width: width, height: 44)
            let factor: CGFloat = 44 / 280
            let radii = shape.usedRadii(in: rect)
            XCTAssertEqual(radii.topLeft.width, 255 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.topLeft.height, 25 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.topRight.width, 25 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.topRight.height, 225 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.bottomRight.width, 225 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.bottomRight.height, 25 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.bottomLeft.width, 25 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.bottomLeft.height, 255 * factor, accuracy: 0.0001)
            XCTAssertEqual(radii.topLeft.height + radii.bottomLeft.height, 44, accuracy: 0.0001)

            let inner = shape.inset(by: 1).usedRadii(in: rect)
            XCTAssertEqual(inner.topLeft.width, radii.topLeft.width - 1, accuracy: 0.0001)
            XCTAssertEqual(inner.topRight.height, radii.topRight.height - 1, accuracy: 0.0001)
            XCTAssertEqual(inner.bottomRight.width, radii.bottomRight.width - 1, accuracy: 0.0001)
            XCTAssertEqual(inner.bottomLeft.height, radii.bottomLeft.height - 1, accuracy: 0.0001)
            XCTAssertEqual(inner.topLeft.height + inner.bottomLeft.height, 42, accuracy: 0.0001)
        }
        let tallerCases: [(CGFloat, CGFloat)] = [
            (134, 134 / 280), (160, 160 / 280), (240, 200 / 280)
        ]
        for (width, factor) in tallerCases {
            let radii = shape.usedRadii(in: CGRect(x: 0, y: 0, width: width, height: 200))
            XCTAssertEqual(radii.topLeft.width, 255 * factor, accuracy: 0.0001)
        }
    }

    func testEllipticalButtonPathDrawsFourDifferentQuarterCurvesAndSquareZeroCorner() {
        let shape = ButtonEllipticalCornerShape(
            topLeft: CGSize(width: 255, height: 25),
            topRight: CGSize(width: 25, height: 225),
            bottomRight: CGSize(width: 225, height: 25),
            bottomLeft: CGSize(width: 25, height: 255))
        let rect = CGRect(x: 10, y: 20, width: 134, height: 44)
        let radii = shape.usedRadii(in: rect)
        var elements: [Path.Element] = []
        shape.path(in: rect).forEach { elements.append($0) }
        XCTAssertEqual(elements.count, 10)
        if case .move(to: let start) = elements[0] {
            XCTAssertEqual(start.x, rect.minX + radii.topLeft.width, accuracy: 0.0001)
            XCTAssertEqual(start.y, rect.minY, accuracy: 0.0001)
        } else { XCTFail("Missing top-left start") }
        let ends = [
            CGPoint(x: rect.maxX, y: rect.minY + radii.topRight.height),
            CGPoint(x: rect.maxX - radii.bottomRight.width, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY - radii.bottomLeft.height),
            CGPoint(x: rect.minX + radii.topLeft.width, y: rect.minY)
        ]
        for (index, expected) in zip([2, 4, 6, 8], ends) {
            if case .curve(to: let end, control1: let c1, control2: let c2) = elements[index] {
                XCTAssertEqual(end.x, expected.x, accuracy: 0.0001)
                XCTAssertEqual(end.y, expected.y, accuracy: 0.0001)
                XCTAssertNotEqual(c1, c2)
            } else { XCTFail("Missing distinct elliptical quarter curve") }
        }
        if case .closeSubpath = elements[9] {} else { XCTFail("Path is not closed") }

        var insetElements: [Path.Element] = []
        shape.inset(by: 1).path(in: rect).forEach { insetElements.append($0) }
        let inner = shape.inset(by: 1).usedRadii(in: rect)
        if case .move(to: let point) = insetElements[0] {
            XCTAssertEqual(point.x, rect.minX + 1 + inner.topLeft.width, accuracy: 0.0001)
            XCTAssertEqual(point.y, rect.minY + 1, accuracy: 0.0001)
        } else { XCTFail("Inset path lost its top-left corner") }

        let square = ButtonEllipticalCornerShape(
            topLeft: CGSize(width: 0, height: 25), topRight: .zero,
            bottomRight: .zero, bottomLeft: .zero)
        XCTAssertEqual(square.usedRadii(in: rect).topLeft, .zero)
        var squareElements: [Path.Element] = []
        square.path(in: rect).forEach { squareElements.append($0) }
        if case .move(to: let point) = squareElements[0] {
            XCTAssertEqual(point, rect.origin)
        } else { XCTFail("Zero-axis corner should be square") }
        XCTAssertTrue(shape.inset(by: 23).path(in: rect).isEmpty)
    }

    func testNativeCircleAndUnderlineHaveIndependentObservableState() {
        let circle = MSUBridge.makeNode(kind: "circle")
        circle.diameter = 8
        circle.foregroundHex = "#2C3E50"
        circle.foregroundDarkHex = "#6B8CFF"
        circle.accessibilityLabelText = "Step 3 of 6"
        circle.automationId = "bridge.selected.step"
        let decoration = MSUBridge.makeNode(kind: "circle")
        decoration.diameter = 8
        let text = MSUBridge.makeNode(kind: "text")
        text.text = "Logout"
        XCTAssertFalse(text.isUnderlined)
        text.isUnderlined = true
        _ = SwiftUINodeView(node: circle).body
        _ = SwiftUINodeView(node: decoration).body
        _ = SwiftUINodeView(node: text).body
        text.isUnderlined = false
        XCTAssertEqual(circle.diameter, 8)
        XCTAssertEqual(circle.foregroundDarkHex, "#6B8CFF")
        XCTAssertEqual(decoration.accessibilityLabelText, "")
        XCTAssertFalse(text.isUnderlined)
    }

    func testSourceStyleStateHasExactMetricAndPairedPaletteFields() {
        let text = MSUBridge.makeNode(kind: "text")
        text.fontPostScriptName = ""
        text.fontSize = 24
        text.fontWeight = 700
        text.lineHeightMultiple = 1.17
        text.foregroundHex = "#0B0D12"
        text.foregroundDarkHex = "#F8FAFF"
        text.preferredScheme = "dark"

        XCTAssertEqual(text.fontPostScriptName, "")
        XCTAssertEqual(text.fontSize, 24)
        XCTAssertEqual(text.fontWeight, 700)
        XCTAssertEqual(text.lineHeightMultiple, 1.17)
        XCTAssertEqual(text.foregroundDarkHex, "#F8FAFF")
        XCTAssertEqual(text.preferredScheme, "dark")
        text.preferredScheme = "light"
        XCTAssertEqual(text.preferredScheme, "light")
        _ = SwiftUINodeView(node: text).body
    }

    func testSourceStyleFrameSurfaceProgressAndInsetRetainChildIdentity() {
        let content = MSUBridge.makeNode(kind: "scroll")
        let button = MSUBridge.makeNode(kind: "button")
        button.buttonStyle = "plain"
        button.paddingTop = 12
        button.paddingRight = 16
        button.paddingBottom = 12
        button.paddingLeft = 16
        button.fillsWidth = true
        button.maxWidth = 440
        button.horizontalAlignment = "center"
        button.backgroundHex = "#EEF1FF"
        button.backgroundDarkHex = "#121B33"
        button.borderHex = "#D6DAF0"
        button.borderDarkHex = "#263457"
        button.cornerRadius = 16
        button.borderWidth = 1
        button.shadowHex = "#000000"
        button.shadowDarkHex = "#000000"
        button.shadowRadius = 15
        button.shadowOpacity = 0.15
        button.shadowOffsetY = 4
        content.insertChild(button, at: 0)

        let progress = MSUBridge.makeNode(kind: "progress")
        progress.value = 1
        progress.maximum = 3
        progress.progressThickness = 8
        progress.tintHex = "#1E4DFF"
        progress.tintDarkHex = "#6B8CFF"
        progress.progressTrackHex = "#EEF1FF"
        progress.progressTrackDarkHex = "#121B33"
        content.insertChild(progress, at: 1)

        let footer = MSUBridge.makeNode(kind: "hstack")
        let field = MSUBridge.makeNode(kind: "textField")
        footer.insertChild(field, at: 0)
        let inset = MSUBridge.makeNode(kind: "bottomInset")
        inset.insertChild(content, at: 0)
        inset.insertChild(footer, at: 1)

        XCTAssertTrue(inset.children[0] === content)
        XCTAssertTrue(inset.children[1] === footer)
        XCTAssertTrue(footer.children[0] === field)
        XCTAssertEqual(button.paddingRight, 16)
        XCTAssertEqual(button.maxWidth, 440)
        XCTAssertEqual(button.cornerRadius, 16)
        XCTAssertEqual(button.borderDarkHex, "#263457")
        XCTAssertEqual(progress.value / progress.maximum, 1.0 / 3.0)
        XCTAssertEqual(progress.progressThickness, 8)
        progress.maximum = 0
        progress.value = 0
        _ = SwiftUINodeView(node: inset).body
    }

    func testNativeListRowPaletteInlineTitleCenteredScrollAndSecurePromptState() {
        let list = MSUBridge.makeNode(kind: "list")
        list.nativeListCanvasHex = "#F7F8FF"
        list.nativeListCanvasDarkHex = "#060913"
        list.nativeListRowHex = "#EEF1FF"
        list.nativeListRowDarkHex = "#121B33"
        let row = MSUBridge.makeNode(kind: "text")
        row.automationId = "bridge.row"
        list.insertChild(row, at: 0)

        let form = MSUBridge.makeNode(kind: "form")
        form.nativeListCanvasHex = list.nativeListCanvasHex
        form.nativeListCanvasDarkHex = list.nativeListCanvasDarkHex
        form.nativeListRowHex = list.nativeListRowHex
        form.nativeListRowDarkHex = list.nativeListRowDarkHex
        let section = MSUBridge.makeNode(kind: "section")
        let secure = MSUBridge.makeNode(kind: "secureField")
        secure.placeholder = "Password"
        secure.placeholderColorHex = "#7A8699"
        secure.placeholderColorDarkHex = "#93A3C7"
        secure.automationId = "bridge.password"
        section.insertChild(secure, at: 0)
        form.insertChild(section, at: 0)

        let scroll = MSUBridge.makeNode(kind: "scroll")
        scroll.centerWhenShort = true
        let button = MSUBridge.makeNode(kind: "button")
        button.minimumHeight = 44
        button.automationId = "bridge.next"
        scroll.insertChild(button, at: 0)

        let title = MSUBridge.makeNode(kind: "vstack")
        title.navigationTitle = "Dashboard"
        title.inlineNavigationTitle = true
        XCTAssertTrue(list.children[0] === row)
        XCTAssertTrue(form.children[0] === section)
        XCTAssertTrue(section.children[0] === secure)
        XCTAssertEqual(list.nativeListRowDarkHex, "#121B33")
        XCTAssertEqual(secure.placeholderColorDarkHex, "#93A3C7")
        XCTAssertEqual(button.minimumHeight, 44)
        XCTAssertTrue(scroll.centerWhenShort && title.inlineNavigationTitle)
        _ = SwiftUINodeView(node: list).body
        _ = SwiftUINodeView(node: form).body
        _ = SwiftUINodeView(node: scroll).body
        _ = SwiftUINodeView(node: title).body
        title.navigationTitle = "Updated"
        XCTAssertEqual(title.navigationTitle, "Updated")
        XCTAssertEqual(secure.kind, "secureField")
    }

    func testHorizontalGridRetainsColumnsCellsAndActionsWhenARowIsRemoved() {
        let grid = MSUBridge.makeNode(kind: "horizontalGrid")
        grid.gridColumnMinimumWidths = [0, 0, 120, 0, 0]
        grid.automationId = "bridge.grid"
        let header = MSUBridge.makeNode(kind: "hstack")
        header.automationId = "bridge.grid.header"
        for label in ["Target", "Native", "Type", "Tags", "Remove"] {
            let text = MSUBridge.makeNode(kind: "text")
            text.text = label
            header.insertChild(text, at: header.children.count)
        }
        grid.insertChild(header, at: 0)

        let first = MSUBridge.makeNode(kind: "hstack")
        let second = MSUBridge.makeNode(kind: "hstack")
        var removals = 0
        for (index, row) in [first, second].enumerated() {
            row.automationId = "bridge.grid.row.\(index)"
            for kind in ["textField", "text", "picker", "text", "button"] {
                row.insertChild(MSUBridge.makeNode(kind: kind), at: row.children.count)
            }
            row.children[2].selectedIndex = 1
            row.children[4].setTapHandler { removals += 1 }
            grid.insertChild(row, at: grid.children.count)
        }
        let retainedCell = second.children[0]
        let retainedId = second.id
        _ = SwiftUINodeView(node: grid).body
        XCTAssertEqual(grid.gridColumnMinimumWidths.map(\.doubleValue), [0, 0, 120, 0, 0])
        XCTAssertEqual(grid.children.map(\.id), [header.id, first.id, retainedId])

        first.children[4].invokeAction()
        grid.removeChild(at: 1)
        first.clearHandlers()
        first.clearChildren()
        XCTAssertEqual(removals, 1)
        XCTAssertEqual(grid.children.map(\.id), [header.id, retainedId])
        XCTAssertTrue(second.children[0] === retainedCell)
        XCTAssertEqual(second.children[2].selectedIndex, 1)
        second.children[4].invokeAction()
        XCTAssertEqual(removals, 2)

        let oldScroll = MSUBridge.makeNode(kind: "scroll")
        oldScroll.centerWhenShort = true
        XCTAssertEqual(oldScroll.kind, "scroll")
        XCTAssertTrue(oldScroll.centerWhenShort)
        _ = SwiftUINodeView(node: oldScroll).body
    }

    func testComposedMenuRetainsNativeLabelOptionsAndSelectionActions() {
        let menu = MSUBridge.makeNode(kind: "menu")
        menu.text = "Video"
        menu.automationId = "bridge.menu.media"
        let label = MSUBridge.makeNode(kind: "hstack")
        label.fillsWidth = true
        let selected = MSUBridge.makeNode(kind: "text")
        selected.text = "Video"
        let chevron = MSUBridge.makeNode(kind: "image")
        chevron.imageName = "chevron.down"
        label.insertChild(selected, at: 0)
        label.insertChild(chevron, at: 1)
        menu.insertChild(label, at: 0)

        let video = MSUBridge.makeNode(kind: "button")
        video.text = "Video"
        video.accessibilitySelected = true
        let audio = MSUBridge.makeNode(kind: "button")
        audio.text = "Audio"
        var selectedIndex = 0
        audio.setTapHandler {
            selectedIndex = 1
            selected.text = "Audio"
            menu.text = "Audio"
            video.accessibilitySelected = false
            audio.accessibilitySelected = true
        }
        menu.insertChild(video, at: 1)
        menu.insertChild(audio, at: 2)
        _ = SwiftUINodeView(node: menu).body

        XCTAssertEqual(menu.children.map(\.id), [label.id, video.id, audio.id])
        XCTAssertEqual(label.children.map(\.id), [selected.id, chevron.id])
        audio.invokeAction()
        XCTAssertEqual(selectedIndex, 1)
        XCTAssertEqual(selected.text, "Audio")
        XCTAssertEqual(menu.text, "Audio")
        XCTAssertFalse(video.accessibilitySelected)
        XCTAssertTrue(audio.accessibilitySelected)
        XCTAssertEqual(menu.automationId, "bridge.menu.media")

        let original = MSUBridge.makeNode(kind: "menu")
        original.text = "More"
        original.insertChild(MSUBridge.makeNode(kind: "button"), at: 0)
        _ = SwiftUINodeView(node: original).body
        XCTAssertEqual(original.text, "More")
        XCTAssertEqual(original.children.first?.kind, "button")
    }

    func testViewportCallbackOnlyReportsChangedGeometryOrDynamicType() {
        let viewport = MSUBridge.makeNode(kind: "scroll")
        var reports: [(Double, Int)] = []
        viewport.setViewportChangedHandler { width, size in reports.append((width, size)) }
        viewport.reportViewport(width: 0, dynamicTypeSize: 3)
        viewport.reportViewport(width: 375, dynamicTypeSize: 3)
        viewport.reportViewport(width: 375, dynamicTypeSize: 3)
        viewport.reportViewport(width: 820, dynamicTypeSize: 3)
        viewport.reportViewport(width: 820, dynamicTypeSize: 7)
        XCTAssertEqual(reports.map(\.0), [375, 820, 820])
        XCTAssertEqual(reports.map(\.1), [3, 3, 7])
        viewport.clearHandlers()
        viewport.reportViewport(width: 900, dynamicTypeSize: 7)
        XCTAssertEqual(reports.count, 3)

        let row = MSUBridge.makeNode(kind: "hstack")
        let text = MSUBridge.makeNode(kind: "text")
        row.insertChild(text, at: 0)
        row.adaptiveStackBelowWidth = 430
        _ = SwiftUINodeView(node: row).body
        XCTAssertTrue(row.children.first === text)
    }

    func testNativeNavigationPathReportsInteractiveBack() {
        let stack = MSUBridge.makeNode(kind: "navigationStack")
        let root = MSUBridge.makeNode(kind: "form")
        let detail = MSUBridge.makeNode(kind: "list")
        detail.route = "resource"
        stack.insertChild(root, at: 0)
        stack.insertChild(detail, at: 1)

        var observedDepth = -1
        stack.setNavigationChangedHandler { observedDepth = $0 }
        stack.appendRoute("resource")
        XCTAssertEqual(stack.pathDepth, 1)
        XCTAssertEqual(observedDepth, -1)
        stack.routeBinding.wrappedValue = []
        XCTAssertEqual(stack.pathDepth, 0)
        XCTAssertEqual(observedDepth, 0)

        stack.appendRoute("resource")
        stack.canNavigateBack = false
        stack.routeBinding.wrappedValue = []
        XCTAssertEqual(stack.pathDepth, 1)
        XCTAssertEqual(observedDepth, 0)
        stack.canNavigateBack = true
        stack.popRoute()
        XCTAssertEqual(stack.pathDepth, 0)
        XCTAssertEqual(observedDepth, 0)
        stack.clearHandlers()
        stack.appendRoute("resource")
        stack.routeBinding.wrappedValue = []
        XCTAssertEqual(observedDepth, 0)
    }

    func testStateAndImporterCallbacksAreReleased() {
        let field = MSUBridge.makeNode(kind: "secureField")
        field.text = "Before"
        field.text = "After"
        XCTAssertEqual(field.text, "After")
        let picker = MSUBridge.makeNode(kind: "valuePicker")
        picker.selectedValue = "source"
        XCTAssertEqual(picker.selectedValue, "source")
        let importer = MSUBridge.makeNode(kind: "fileImporter")
        var received = 0
        importer.setFileImportedHandler { data, name, mime in
            XCTAssertEqual(data, Data("text".utf8))
            XCTAssertEqual(name, "words.txt")
            XCTAssertEqual(mime, "text/plain")
            received += 1
        }
        importer.fileImportedHandler?(Data("text".utf8), "words.txt", "text/plain")
        var cancels = 0
        var errors = 0
        importer.setFileImportCancelledHandler { cancels += 1 }
        importer.setFileImportErrorHandler { _ in errors += 1 }
        importer.fileImportCancelledHandler?()
        XCTAssertEqual(cancels, 1)
        XCTAssertEqual(errors, 0)
        importer.clearHandlers()
        importer.fileImportedHandler?(Data(), "", "")
        importer.fileImportCancelledHandler?()
        XCTAssertEqual(received, 1)
        XCTAssertEqual(cancels, 1)
        XCTAssertTrue(MSUBridge.responds(to: #selector(MSUBridge.runApplication(forRoot:sceneChanged:))))
    }

    func testSliderHasSemanticAccessibilityLabel() {
        let slider = MSUBridge.makeNode(kind: "slider")
        slider.accessibilityLabelText = "Practice level"
        XCTAssertEqual(slider.accessibilityLabelText, "Practice level")
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        XCTAssertNotNil(MSUBridge.hostView(forRoot: slider))
        #endif
    }

    func testSourceDividerSpinnerStrikethroughAndOpacityAreIndependent() {
        let divider = MSUBridge.makeNode(kind: "divider")
        let spinner = MSUBridge.makeNode(kind: "indeterminateProgress")
        spinner.accessibilityLabelText = "Loading"
        let line = MSUBridge.makeNode(kind: "progress")
        line.value = 1
        line.maximum = 4
        let text = MSUBridge.makeNode(kind: "text")
        text.isStrikethrough = true
        text.opacity = 0.75
        _ = SwiftUINodeView(node: divider).body
        _ = SwiftUINodeView(node: spinner).body
        _ = SwiftUINodeView(node: line).body
        _ = SwiftUINodeView(node: text).body
        XCTAssertEqual(spinner.kind, "indeterminateProgress")
        XCTAssertEqual(line.kind, "progress")
        XCTAssertEqual(text.opacity, 0.75)
        XCTAssertTrue(text.isStrikethrough)
    }

    func testPhotoImageIODecodesOwnedBytesAndReportsActualAppearanceOnce() {
        let png = Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMQ7LgLAAIkAXfC8r3XAAAAAElFTkSuQmCC")!
        let photo = MSUBridge.makeNode(kind: "photo")
        photo.accessibilityLabelText = "Photo hint"
        photo.photoMaxHeight = 160
        var rendered = 0
        var failures: [String] = []
        photo.setPhotoRenderedHandler { rendered += 1 }
        photo.setPhotoFailedHandler { failures.append($0) }
        photo.photoData = png as NSData
        XCTAssertNotNil(photo.decodedPhoto)
        XCTAssertEqual(photo.photoStatus, "loading")
        _ = SwiftUINodeView(node: photo).body
        photo.reportPhotoRendered()
        photo.reportPhotoRendered()
        XCTAssertEqual(rendered, 1)
        XCTAssertEqual(photo.photoStatus, "displayed")
        XCTAssertTrue(failures.isEmpty)

        let zoom = MSUBridge.makeNode(kind: "zoomPhoto")
        zoom.photoData = png as NSData
        XCTAssertNotNil(zoom.decodedPhoto)
        _ = SwiftUINodeView(node: zoom).body

        let corrupt = MSUBridge.makeNode(kind: "photo")
        var corruptErrors: [String] = []
        corrupt.setPhotoFailedHandler { corruptErrors.append($0) }
        corrupt.photoData = Data([0, 1, 2]) as NSData
        corrupt.reportPhotoRendered()
        XCTAssertNil(corrupt.decodedPhoto)
        XCTAssertEqual(corrupt.photoStatus, "failed")
        XCTAssertEqual(corruptErrors, ["decodeFailed"])
        photo.clearHandlers()
        photo.photoData = Data([0, 1, 2]) as NSData
        XCTAssertTrue(failures.isEmpty)
    }

    func testQuickAddKeysAndSubmitShareExactlyOneFocusedInputCallback() {
        let field = MSUBridge.makeNode(kind: "textField")
        field.automationId = "bridge.quick.field"
        field.text = "word"
        var changes: [String] = []
        field.setTextChangedHandler { changes.append($0) }
        field.updateTextInput("word")
        field.updateTextInput("word\n")
        XCTAssertTrue(changes.isEmpty)
        field.updateTextInput("words")
        XCTAssertEqual(changes, ["words"])
        let editor = MSUBridge.makeNode(kind: "textEditor")
        editor.setTextChangedHandler { changes.append($0) }
        editor.updateTextInput("line one\nline two")
        XCTAssertEqual(changes.last, "line one\nline two")
        var keys: [String] = []
        var submits = 0
        field.setKeyHandler { key in
            keys.append(key)
            return key == "enter" || key == "down"
        }
        field.setSubmitHandler { submits += 1 }
        XCTAssertTrue(field.handleTextKey("down"))
        XCTAssertFalse(field.handleTextKey("escape"))
        field.submitTextField()
        XCTAssertEqual(keys, ["down", "escape", "enter"])
        XCTAssertEqual(submits, 0)
        field.setKeyHandler { key in
            keys.append(key)
            return false
        }
        field.submitTextField()
        XCTAssertEqual(submits, 1)
        field.clearHandlers()
        field.submitTextField()
        XCTAssertEqual(submits, 1)

        let form = MSUBridge.makeNode(kind: "form")
        form.insertChild(field, at: 0)
        let options = MSUBridge.makeNode(kind: "vstack")
        let chosen = MSUBridge.makeNode(kind: "button")
        chosen.accessibilitySelected = true
        options.insertChild(chosen, at: 0)
        let popup = MSUBridge.makeNode(kind: "quickSuggestions")
        popup.quickAddAnchorId = field.automationId
        popup.insertChild(form, at: 0)
        popup.insertChild(options, at: 1)
        popup.isPresented = true
        _ = SwiftUINodeView(node: popup).body
        var dismissals = 0
        popup.setDismissedHandler { dismissals += 1 }
        popup.dismissQuickSuggestions()
        popup.dismissQuickSuggestions()
        XCTAssertEqual(dismissals, 1)
        XCTAssertFalse(popup.isPresented)
        XCTAssertTrue(chosen.accessibilitySelected)
    }

    func testRetainedQuickAddBodySurvivesRemovedChildrenAndIgnoresStaleSelection() {
        let field = MSUBridge.makeNode(kind: "textField")
        field.automationId = "bridge.quick.field"
        let form = MSUBridge.makeNode(kind: "form")
        form.insertChild(field, at: 0)
        let selected = MSUBridge.makeNode(kind: "button")
        selected.accessibilitySelected = true
        let suggestions = MSUBridge.makeNode(kind: "vstack")
        suggestions.insertChild(selected, at: 0)
        let popup = MSUBridge.makeNode(kind: "quickSuggestions")
        popup.quickAddAnchorId = field.automationId
        popup.insertChild(form, at: 0)
        popup.insertChild(suggestions, at: 1)
        popup.isPresented = true
        var dismissals = 0
        popup.setDismissedHandler { dismissals += 1 }

        let retained = QuickAddSuggestionsNodeView(node: popup, field: field)
        _ = retained.body
        XCTAssertEqual(retained.selectedCandidate(content: form, suggestions: suggestions),
                       selected.id)

        popup.removeChild(at: 1)
        _ = retained.body
        XCTAssertNil(retained.selectedCandidate(content: form, suggestions: suggestions))
        popup.clearHandlers()
        popup.clearChildren()
        form.clearChildren()
        suggestions.clearChildren()
        _ = retained.body
        XCTAssertNil(retained.selectedCandidate(content: form, suggestions: suggestions))
        popup.dismissQuickSuggestions()
        XCTAssertFalse(popup.isPresented)
        XCTAssertEqual(dismissals, 0)
    }

    func testTextEditorPlaceholderTracksEmptyFocusedTypedAndClearedText() {
        let editor = MSUBridge.makeNode(kind: "textEditor")
        XCTAssertFalse(editor.showsTextEditorPlaceholder)
        editor.placeholder = "Write a sentence with the target word"
        editor.placeholderColorHex = "#7A8699"
        editor.placeholderColorDarkHex = "#93A3C7"
        XCTAssertTrue(editor.showsTextEditorPlaceholder)
        editor.focusRequested = true
        XCTAssertTrue(editor.showsTextEditorPlaceholder)
        editor.updateTextInput("First line\nSecond")
        XCTAssertEqual(editor.text, "First line\nSecond")
        XCTAssertFalse(editor.showsTextEditorPlaceholder)
        editor.updateTextInput("")
        XCTAssertTrue(editor.showsTextEditorPlaceholder)
        editor.focusRequested = false
        XCTAssertTrue(editor.showsTextEditorPlaceholder)
        _ = SwiftUINodeView(node: editor).body
        editor.placeholder = ""
        XCTAssertFalse(editor.showsTextEditorPlaceholder)

        let field = MSUBridge.makeNode(kind: "textField")
        field.placeholder = "Find vocabulary"
        XCTAssertFalse(field.showsTextEditorPlaceholder)
    }

    func testTextEditorScrollBackgroundIsOptInAndObservable() {
        let editor = MSUBridge.makeNode(kind: "textEditor")
        XCTAssertFalse(editor.hidesTextEditorScrollBackground)
        let field = MSUBridge.makeNode(kind: "textField")
        XCTAssertFalse(field.hidesTextEditorScrollBackground)

        var updates = 0
        let subscription = editor.objectWillChange.sink { updates += 1 }
        editor.hidesTextEditorScrollBackground = true
        XCTAssertTrue(editor.hidesTextEditorScrollBackground)
        XCTAssertEqual(updates, 1)
        _ = SwiftUINodeView(node: editor).body
        editor.hidesTextEditorScrollBackground = false
        XCTAssertFalse(editor.hidesTextEditorScrollBackground)
        XCTAssertEqual(updates, 2)
        withExtendedLifetime(subscription) {}
    }

    func testSheetFullScreenPhotoAndRootBlockingStateRetainNodes() {
        let sheet = MSUBridge.makeNode(kind: "sheet")
        sheet.sheetDetentFraction = 0.7
        sheet.insertChild(MSUBridge.makeNode(kind: "text"), at: 0)
        sheet.insertChild(MSUBridge.makeNode(kind: "scroll"), at: 1)
        _ = SwiftUINodeView(node: sheet).body
        XCTAssertEqual(sheet.sheetDetentFraction, 0.7)

        let cover = MSUBridge.makeNode(kind: "photoCover")
        cover.insertChild(MSUBridge.makeNode(kind: "text"), at: 0)
        cover.insertChild(MSUBridge.makeNode(kind: "zoomPhoto"), at: 1)
        cover.insertChild(MSUBridge.makeNode(kind: "button"), at: 2)
        _ = SwiftUINodeView(node: cover).body
        XCTAssertEqual(cover.children.map(\.kind), ["text", "zoomPhoto", "button"])

        let busy = MSUBridge.makeNode(kind: "starterOverlay")
        busy.insertChild(MSUBridge.makeNode(kind: "tabView"), at: 0)
        busy.text = "Creating starter resource"
        busy.isPresented = true
        _ = SwiftUINodeView(node: busy).body
        XCTAssertTrue(busy.isPresented)
        XCTAssertTrue(busy.children.first?.kind == "tabView")
    }

    func testDeleteConfirmationNeverRunsMutationUntilExplicitConfirm() {
        let dialog = MSUBridge.makeNode(kind: "deleteConfirmation")
        dialog.insertChild(MSUBridge.makeNode(kind: "form"), at: 0)
        dialog.transparentDeleteBackdrop = true
        dialog.text = "Delete resource?"
        dialog.placeholder = "This cannot be undone"
        dialog.deleteCloseLabel = "Close"
        dialog.deleteCancelLabel = "Cancel"
        dialog.deleteConfirmLabel = "Delete"
        var cancellations = 0
        var confirmations = 0
        dialog.setDeleteCancelledHandler { cancellations += 1 }
        dialog.setDeleteConfirmedHandler { confirmations += 1 }
        dialog.isPresented = true
        _ = SwiftUINodeView(node: dialog).body
        dialog.cancelDelete()
        dialog.reportDeleteDismissed()
        XCTAssertFalse(dialog.isPresented)
        XCTAssertEqual(cancellations, 1)
        XCTAssertEqual(confirmations, 0)
        dialog.isPresented = true
        dialog.confirmDelete()
        dialog.confirmDelete()
        dialog.cancelDelete()
        XCTAssertTrue(dialog.deletePending)
        XCTAssertTrue(dialog.isPresented)
        XCTAssertEqual(confirmations, 1)
        dialog.isPresented = false
        dialog.reportDeleteDismissed()
        XCTAssertEqual(cancellations, 1)
        XCTAssertFalse(dialog.deletePending)
        dialog.clearHandlers()
        dialog.isPresented = true
        dialog.confirmDelete()
        XCTAssertEqual(confirmations, 1)
    }

    func testDeleteConfirmationTransparentBackdropIsOptInAndObservable() {
        let dialog = MSUBridge.makeNode(kind: "deleteConfirmation")
        dialog.insertChild(MSUBridge.makeNode(kind: "form"), at: 0)
        XCTAssertFalse(dialog.transparentDeleteBackdrop)
        XCTAssertTrue(dialog.responds(to: NSSelectorFromString(
            "setTransparentDeleteBackdrop:")))
        var updates = 0
        let subscription = dialog.objectWillChange.sink { updates += 1 }
        dialog.transparentDeleteBackdrop = true
        XCTAssertTrue(dialog.transparentDeleteBackdrop)
        XCTAssertEqual(updates, 1)
        _ = SwiftUINodeView(node: dialog).body
        dialog.transparentDeleteBackdrop = false
        XCTAssertFalse(dialog.transparentDeleteBackdrop)
        XCTAssertEqual(updates, 2)
        withExtendedLifetime(subscription) {}
    }

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    @MainActor
    func testAppKitHostCreatesViewAndController() {
        let root = MSUBridge.makeNode(kind: "text")
        root.text = "Hosted"
        XCTAssertNotNil(MSUBridge.hostView(forRoot: root))
        XCTAssertNotNil(MSUBridge.hostController(forRoot: root))
    }

    @MainActor
    func testDeactivatedHostCannotRedisplayTheOldRoot() {
        let root = MSUBridge.makeNode(kind: "button")
        guard let view = MSUBridge.hostView(forRoot: root) as? NSHostingView<SwiftUINodeView>,
              let controller = MSUBridge.hostController(forRoot: root) as? NSHostingController<SwiftUINodeView>
        else {
            XCTFail("Expected the native SwiftUI hosting types")
            return
        }

        XCTAssertTrue(MSUBridge.deactivateHost(view))
        XCTAssertTrue(MSUBridge.deactivateHost(controller))
        XCTAssertFalse(view.rootView.node === root)
        XCTAssertFalse(controller.rootView.node === root)
        XCTAssertEqual(view.rootView.node.kind, "text")
        XCTAssertEqual(controller.rootView.node.kind, "text")
        XCTAssertFalse(MSUBridge.deactivateHost(NSView()))
    }
    #endif
}
