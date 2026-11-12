import SwiftUI

/// A tab view drawn with the iOS 18 / macOS 15 `Tab` API, used only when the
/// tab view sets a style or a minimize behavior (iOS 26), or one of its tabs sets a
/// role or a hidden state (a plain tab view keeps the `tabItem` rendering). Each tab node's first child is
/// the tab's content; the tab node supplies the title, symbol, role, hidden
/// state and accessibility identifier. Choose the style and roles before the
/// tab view is mounted: switching between the two renderings rebuilds it.
@available(iOS 18.0, macOS 15.0, *)
struct AdaptiveTabViewNodeView: View {
    @ObservedObject var node: MSUNode

    var body: some View {
        let tabs = TabView(selection: Binding(
            get: { node.selectedIndex },
            set: { next in
                node.selectedIndex = next
                node.selectionChangedHandler?(next)
            }
        )) {
            ForEach(node.children.indices, id: \.self) { index in
                tab(node.children[index], index: index)
            }
        }
        let styled = Group {
            if node.tabViewStyle == "sidebarAdaptable" {
                tabs.tabViewStyle(.sidebarAdaptable)
            } else if node.tabViewStyle == "tabBarOnly" {
                tabs.tabViewStyle(.tabBarOnly)
            } else {
                tabs
            }
        }
        #if os(iOS)
        if #available(iOS 26.0, *), !node.tabBarMinimizeBehavior.isEmpty {
            styled.tabBarMinimizeBehavior(minimizeBehavior)
        } else {
            styled
        }
        #else
        styled
        #endif
    }

    #if os(iOS)
    @available(iOS 26.0, *)
    private var minimizeBehavior: TabBarMinimizeBehavior {
        switch node.tabBarMinimizeBehavior {
        case "onScrollDown": return .onScrollDown
        case "onScrollUp": return .onScrollUp
        case "never": return .never
        default: return .automatic
        }
    }
    #endif

    private func tab(_ tab: MSUNode, index: Int) -> some TabContent<Int> {
        Tab(tab.text, systemImage: tab.imageName, value: index,
            role: tab.tabRole == "search" ? .search : nil) {
            if let root = tab.children.first {
                SwiftUINodeView(node: root)
            }
        }
        .hidden(tab.tabHidden)
        .accessibilityIdentifier(tab.automationId, isEnabled: !tab.automationId.isEmpty)
    }
}
