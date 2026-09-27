import Combine
import Foundation
import SwiftUI

@objc(MSUNode)
public final class MSUNode: NSObject, ObservableObject {
    public let objectWillChange = ObservableObjectPublisher()
    public let id = UUID()

    @objc public let kind: String
    @objc public var text = "" { willSet { objectWillChange.send() } }
    @objc public var placeholder = "" { willSet { objectWillChange.send() } }
    @objc public var imageName = "" { willSet { objectWillChange.send() } }
    @objc public var automationId = "" { willSet { objectWillChange.send() } }
    @objc public var accessibilityLabelText = "" { willSet { objectWillChange.send() } }
    @objc public var isOn = false { willSet { objectWillChange.send() } }
    @objc public var isPresented = false { willSet { objectWillChange.send() } }
    @objc public var focusRequested = false { willSet { objectWillChange.send() } }
    @objc public var value = 0.0 { willSet { objectWillChange.send() } }
    @objc public var minimum = 0.0 { willSet { objectWillChange.send() } }
    @objc public var maximum = 1.0 { willSet { objectWillChange.send() } }
    @objc public var spacing = 8.0 { willSet { objectWillChange.send() } }
    @objc public var selectedIndex = 0 { willSet { objectWillChange.send() } }
    public private(set) var children: [MSUNode] = [] { willSet { objectWillChange.send() } }

    var tapHandler: (() -> Void)?
    var textChangedHandler: ((String) -> Void)?
    var boolChangedHandler: ((Bool) -> Void)?
    var valueChangedHandler: ((Double) -> Void)?
    var selectionChangedHandler: ((Int) -> Void)?
    var focusChangedHandler: ((Bool) -> Void)?
    var dismissedHandler: (() -> Void)?

    @objc public init(kind: String) {
        precondition([
            "text", "button", "textField", "textEditor", "vstack", "hstack",
            "scroll", "list", "navigation", "navigationLink", "sheet",
            "image", "toggle", "slider", "picker"
        ].contains(kind), "Unsupported SwiftUI node kind: \(kind)")
        self.kind = kind
        super.init()
    }

    @objc(insertChild:atIndex:)
    public func insertChild(_ child: MSUNode, at index: Int) {
        precondition(index >= 0 && index <= children.count, "Child index out of range")
        children.insert(child, at: index)
    }

    @objc(removeChildAtIndex:)
    public func removeChild(at index: Int) {
        precondition(index >= 0 && index < children.count, "Child index out of range")
        children.remove(at: index)
    }

    @objc public func clearChildren() {
        children.removeAll()
    }

    @objc public func invokeAction() {
        tapHandler?()
    }

    @objc public func clearHandlers() {
        tapHandler = nil
        textChangedHandler = nil
        boolChangedHandler = nil
        valueChangedHandler = nil
        selectionChangedHandler = nil
        focusChangedHandler = nil
        dismissedHandler = nil
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
}

@objc(MSUBridge)
public final class MSUBridge: NSObject {
    @objc(makeNodeWithKind:)
    public static func makeNode(kind: String) -> MSUNode {
        MSUNode(kind: kind)
    }
}

private struct TextInputNodeView: View {
    @ObservedObject var node: MSUNode
    @FocusState private var hasFocus: Bool

    private var text: Binding<String> {
        Binding(
            get: { node.text },
            set: { next in
                node.text = next
                node.textChangedHandler?(next)
            }
        )
    }

    var body: some View {
        Group {
            if node.kind == "textEditor" {
                TextEditor(text: text)
            } else {
                TextField(node.placeholder, text: text)
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

struct SwiftUINodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        content.accessibilityIdentifier(node.automationId)
    }

    @ViewBuilder
    private var content: some View {
        switch node.kind {
        case "text":
            Text(node.text)
        case "button":
            Button(node.text) { node.invokeAction() }
        case "textField", "textEditor":
            TextInputNodeView(node: node)
        case "vstack":
            VStack(alignment: .leading, spacing: node.spacing) {
                ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
            }
        case "hstack":
            HStack(spacing: node.spacing) {
                ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
            }
        case "scroll":
            ScrollView {
                LazyVStack(alignment: .leading, spacing: node.spacing) {
                    ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
                }
            }
        case "list":
            List {
                ForEach(node.children, id: \.id) { SwiftUINodeView(node: $0) }
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
                        SwiftUINodeView(node: node.children[1])
                    }
            }
        case "image":
            Image(systemName: node.imageName).imageScale(.large)
        case "toggle":
            Toggle(node.text, isOn: Binding(
                get: { node.isOn },
                set: { next in
                    node.isOn = next
                    node.boolChangedHandler?(next)
                }
            ))
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
        case "picker":
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
        default:
            EmptyView()
        }
    }
}
