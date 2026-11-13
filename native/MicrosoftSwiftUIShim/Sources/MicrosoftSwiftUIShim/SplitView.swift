import SwiftUI

/// A `NavigationSplitView` node: two children (sidebar, detail) or three (sidebar, content,
/// detail). The node's `splitColumnVisibility` and `splitCompactColumn` are two-way: SwiftUI
/// writes them when the person shows or hides the sidebar, or goes back in the collapsed
/// (compact width) stack, and the change is reported to the host (a compact column change only
/// while the split view is collapsed). Each column's own node can
/// set its width. The columns are fixed slots: a host replaces what a column shows inside it.
struct SplitViewNodeView: View {
    @ObservedObject var node: MSUNode
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    /// Only a collapsed split view (compact width) has a stack the person can go back in; a
    /// write while it is expanded (or while the width class changes) is not a Back.
    private var isCollapsed: Bool {
        #if os(iOS)
        horizontalSizeClass == .compact
        #else
        false
        #endif
    }

    var body: some View {
        switch node.splitViewStyle {
        case "balanced":
            split.navigationSplitViewStyle(.balanced)
        case "prominentDetail":
            split.navigationSplitViewStyle(.prominentDetail)
        default:
            split
        }
    }

    @ViewBuilder
    private var split: some View {
        let columns = node.children
        if columns.count >= 3 {
            NavigationSplitView(columnVisibility: visibility, preferredCompactColumn: compactColumn) {
                sidebar(columns[0])
            } content: {
                SplitColumnView(column: columns[1])
            } detail: {
                SplitColumnView(column: columns[2])
            }
        } else if columns.count == 2 {
            NavigationSplitView(columnVisibility: visibility, preferredCompactColumn: compactColumn) {
                sidebar(columns[0])
            } detail: {
                SplitColumnView(column: columns[1])
            }
        }
    }

    /// The sidebar column, without the sidebar toggle while the node hides it.
    private func sidebar(_ column: MSUNode) -> some View {
        SplitColumnView(column: column)
            .toolbar(removing: node.splitSidebarToggleHidden ? .sidebarToggle : nil)
    }

    private var visibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { msuSplitVisibility(node.splitColumnVisibility) },
            set: { next in
                // Some platforms resolve .automatic to an equal value (macOS: .doubleColumn),
                // so a write equal to the current visibility is not a change.
                if next == msuSplitVisibility(node.splitColumnVisibility) { return }
                let name = msuSplitVisibilityName(next)
                node.splitColumnVisibility = name
                node.selectedValueChangedHandler?(name)
            }
        )
    }

    private var compactColumn: Binding<NavigationSplitViewColumn> {
        Binding(
            get: { msuSplitColumn(node.splitCompactColumn) },
            set: { next in
                let name = msuSplitColumnName(next)
                if name == node.splitCompactColumn { return }
                node.splitCompactColumn = name
                if isCollapsed {
                    node.selectionChangedHandler?(msuSplitColumnIndex(name))
                }
            }
        )
    }
}

/// One column, with the width its own node sets. Views inside a column hide the tab bar only in
/// a compact width: in a regular width the column sits beside the others and the tabs stay.
private struct SplitColumnView: View {
    @ObservedObject var column: MSUNode

    var body: some View {
        if column.splitColumnIdealWidth > 0 {
            SwiftUINodeView(node: column)
                .environment(\.msuInSplitColumn, true)
                .navigationSplitViewColumnWidth(
                    min: column.splitColumnMinWidth > 0 ? CGFloat(column.splitColumnMinWidth) : nil,
                    ideal: CGFloat(column.splitColumnIdealWidth),
                    max: column.splitColumnMaxWidth > 0 ? CGFloat(column.splitColumnMaxWidth) : nil)
        } else {
            SwiftUINodeView(node: column)
                .environment(\.msuInSplitColumn, true)
        }
    }
}

private struct MSUInSplitColumnKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside a split view column (see `SplitColumnView`).
    var msuInSplitColumn: Bool {
        get { self[MSUInSplitColumnKey.self] }
        set { self[MSUInSplitColumnKey.self] = newValue }
    }
}

func msuSplitVisibility(_ name: String) -> NavigationSplitViewVisibility {
    switch name {
    case "all": return .all
    case "doubleColumn": return .doubleColumn
    case "detailOnly": return .detailOnly
    default: return .automatic
    }
}

func msuSplitVisibilityName(_ visibility: NavigationSplitViewVisibility) -> String {
    if visibility == .all { return "all" }
    if visibility == .doubleColumn { return "doubleColumn" }
    if visibility == .detailOnly { return "detailOnly" }
    return "automatic"
}

func msuSplitColumn(_ name: String) -> NavigationSplitViewColumn {
    switch name {
    case "content": return .content
    case "detail": return .detail
    default: return .sidebar
    }
}

func msuSplitColumnName(_ column: NavigationSplitViewColumn) -> String {
    if column == .content { return "content" }
    if column == .detail { return "detail" }
    return "sidebar"
}

func msuSplitColumnIndex(_ name: String) -> Int {
    switch name {
    case "content": return 1
    case "detail": return 2
    default: return 0
    }
}
