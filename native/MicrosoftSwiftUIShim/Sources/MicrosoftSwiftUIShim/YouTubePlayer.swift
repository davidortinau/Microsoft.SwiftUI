import Foundation
import SwiftUI
import WebKit

/// The only web content the shim hosts: one privacy-enhanced YouTube embed.
/// The main frame may show only the embed page for the given video id; it
/// never navigates elsewhere, and pop-up windows are refused.

let msuYouTubeEmbedHost = "www.youtube-nocookie.com"

/// A YouTube video id is exactly 11 characters of [A-Za-z0-9_-].
func msuIsYouTubeVideoId(_ value: String) -> Bool {
    value.utf8.count == 11 && value.utf8.allSatisfy { byte in
        (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) ||
            (byte >= 0x61 && byte <= 0x7A) || byte == 0x2D || byte == 0x5F
    }
}

func msuYouTubeEmbedURL(_ videoId: String) -> URL? {
    guard msuIsYouTubeVideoId(videoId) else { return nil }
    var components = URLComponents()
    components.scheme = "https"
    components.host = msuYouTubeEmbedHost
    components.path = "/embed/\(videoId)"
    components.queryItems = [
        URLQueryItem(name: "playsinline", value: "1"),
        URLQueryItem(name: "rel", value: "0")
    ]
    return components.url
}

/// Frames the embed player itself loads (for example its own iframes) stay on
/// YouTube's hosts; the main frame stays on the embed page for this video.
func msuYouTubeAllowsNavigation(to url: URL?, isMainFrame: Bool, videoId: String) -> Bool {
    guard let url, msuIsYouTubeVideoId(videoId) else { return false }
    if isMainFrame {
        return url.scheme == "https" && url.host == msuYouTubeEmbedHost
            && url.path == "/embed/\(videoId)" && url.user == nil && url.port == nil
    }
    if url.scheme == "about" {
        return url.absoluteString == "about:blank" || url.absoluteString == "about:srcdoc"
    }
    guard url.scheme == "https", let host = url.host?.lowercased() else { return false }
    return ["youtube-nocookie.com", "youtube.com", "google.com"].contains { domain in
        host == domain || host.hasSuffix("." + domain)
    }
}

final class MSUYouTubeCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    private(set) var videoId = ""

    func load(_ next: String, in webView: WKWebView) {
        guard next != videoId, let url = msuYouTubeEmbedURL(next) else { return }
        videoId = next
        var request = URLRequest(url: url)
        // YouTube requires embedding clients to identify themselves.
        let app = (Bundle.main.bundleIdentifier ?? "localhost").lowercased()
        request.setValue("https://\(app)", forHTTPHeaderField: "Referer")
        webView.load(request)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
        let mainFrame = navigationAction.targetFrame?.isMainFrame ?? true
        decisionHandler(msuYouTubeAllowsNavigation(
            to: navigationAction.request.url, isMainFrame: mainFrame, videoId: videoId)
            ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        nil
    }

    static func makeWebView(_ coordinator: MSUYouTubeCoordinator) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        #if os(iOS)
        configuration.allowsInlineMediaPlayback = true
        #endif
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = coordinator
        webView.uiDelegate = coordinator
        return webView
    }
}

#if os(iOS)
struct MSUYouTubePlayerView: UIViewRepresentable {
    let videoId: String

    func makeCoordinator() -> MSUYouTubeCoordinator { MSUYouTubeCoordinator() }

    func makeUIView(context: Context) -> WKWebView {
        MSUYouTubeCoordinator.makeWebView(context.coordinator)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(videoId, in: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: MSUYouTubeCoordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}
#else
struct MSUYouTubePlayerView: NSViewRepresentable {
    let videoId: String

    func makeCoordinator() -> MSUYouTubeCoordinator { MSUYouTubeCoordinator() }

    func makeNSView(context: Context) -> WKWebView {
        MSUYouTubeCoordinator.makeWebView(context.coordinator)
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(videoId, in: webView)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: MSUYouTubeCoordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }
}
#endif
