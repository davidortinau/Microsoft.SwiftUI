import Foundation
import SwiftUI

private enum ApplicationState {
    nonisolated(unsafe) static var root: MSUNode?
    nonisolated(unsafe) static var sceneChanged: ((Int) -> Void)?
}

extension MSUBridge {
    @objc(runApplicationWithRoot:sceneChanged:)
    public static func runApplication(
        forRoot root: MSUNode,
        sceneChanged: @escaping @convention(block) (Int) -> Void
    ) {
        precondition(Thread.isMainThread, "SwiftUI App.main must run on the Apple main thread")
        precondition(ApplicationState.root == nil, "SwiftUI App.main can run only once")
        ApplicationState.root = root
        ApplicationState.sceneChanged = sceneChanged
        MainActor.assumeIsolated {
            MicrosoftSwiftUIApplication.main()
        }
    }
}

private struct MicrosoftSwiftUIApplication: App {
    var body: some Scene {
        WindowGroup {
            ApplicationRoot()
        }
    }
}

private struct ApplicationRoot: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let root = ApplicationState.root {
                SwiftUINodeView(node: root)
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            let value: Int = switch phase {
            case .active: 2
            case .inactive: 3
            case .background: 4
            @unknown default: 0
            }
            ApplicationState.sceneChanged?(value)
        }
    }
}
