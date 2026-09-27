import AilohaAgent
import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@objc(MicrosoftSwiftUIAilohaDebug)
public final class MicrosoftSwiftUIAilohaDebug: NSObject {
    @objc(startWithCompletion:)
    public static func start(completion: @escaping @convention(block) (Bool, String) -> Void) {
        Task { @MainActor in
            do {
                try await Agent.shared.start(.debugDefault)
                completion(true, "")
            } catch {
                let message = String(describing: error)
                NSLog("Ailoha debug agent failed to start: %@", message)
                completion(false, message)
            }
        }
    }

    @objc public static func stop() {
        Task { @MainActor in
            await Agent.shared.stop()
        }
    }

    #if canImport(UIKit)
    @objc(tagTextInputInRoot:placeholder:identifier:)
    public static func tagTextInput(in root: UIView, placeholder: String, identifier: String) -> Bool {
        var pending = [root]
        while let view = pending.popLast() {
            if let field = view as? UITextField, field.placeholder == placeholder {
                field.setAilohaIdentifier(identifier)
                return true
            }
            pending.append(contentsOf: view.subviews)
        }
        return false
    }
    #elseif canImport(AppKit)
    @objc(tagTextInputInRoot:placeholder:identifier:)
    public static func tagTextInput(in root: NSView, placeholder: String, identifier: String) -> Bool {
        var pending = [root]
        while let view = pending.popLast() {
            if let field = view as? NSTextField, field.placeholderString == placeholder {
                field.setAilohaIdentifier(identifier)
                return true
            }
            pending.append(contentsOf: view.subviews)
        }
        return false
    }
    #endif
}
