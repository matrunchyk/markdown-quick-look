import AppKit
import QuickLookUI
import WebKit

final class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {
    private let webView = WKWebView(frame: .zero)
    private var pendingCompletion: ((Error?) -> Void)?

    override func loadView() {
        webView.underPageBackgroundColor = .clear
        webView.navigationDelegate = self
        view = webView
        preferredContentSize = NSSize(width: 820, height: 700)
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            _ = view // Force the WebKit view to load before starting navigation.
            title = url.lastPathComponent
            pendingCompletion?(CancellationError())
            pendingCompletion = handler
            webView.loadHTMLString(MarkdownRenderer.document(markdown, title: url.lastPathComponent),
                                   baseURL: url.deletingLastPathComponent())
        } catch {
            handler(error)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finishPreparation(with: nil)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finishPreparation(with: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finishPreparation(with: error)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let externalSchemes = ["http", "https", "mailto"]
        if let scheme = url.scheme?.lowercased(), externalSchemes.contains(scheme) {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    private func finishPreparation(with error: Error?) {
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?(error)
    }
}
