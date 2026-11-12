import SwiftUI

/// A `NavigationSplitView` node: two children (sidebar, detail) or three (sidebar, content,
/// detail). The node's `splitColumnVisibility` and `splitCompactColumn` are two-way: SwiftUI
/// writes them when the person shows or hides the sidebar, or goes back in the collapsed
/// (compact width) stack, and the change is reported to the host. Each column's own node can
/// set its width. The columns are fixed slots: a host replaces what a column shows inside it.
struct SplitViewNodeView: View {
    @ObservedObject var node: MSUNode

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
                SplitColumnView(column: columns[0])
            } content: {
                SplitColumnView(column: columns[1])
            } detail: {
                SplitColumnView(column: columns[2])
            }
        } else if columns.count == 2 {
            NavigationSplitView(columnVisibility: visibility, preferredCompactColumn: compactColumn) {
                SplitColumnView(column: columns[0])
            } detail: {
                SplitColumnView(column: columns[1])
            }
        }
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
                node.selectionChangedHandler?(msuSplitColumnIndex(name))
            }
        )
    }
}

/// One column, with the width its own node sets.
private struct SplitColumnView: View {
    @ObservedObject var column: MSUNode

    var body: some View {
        if column.splitColumnIdealWidth > 0 {
            SwiftUINodeView(node: column)
                .navigationSplitViewColumnWidth(
                    min: column.splitColumnMinWidth > 0 ? CGFloat(column.splitColumnMinWidth) : nil,
                    ideal: CGFloat(column.splitColumnIdealWidth),
                    max: column.splitColumnMaxWidth > 0 ? CGFloat(column.splitColumnMaxWidth) : nil)
        } else {
            SwiftUINodeView(node: column)
        }
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
