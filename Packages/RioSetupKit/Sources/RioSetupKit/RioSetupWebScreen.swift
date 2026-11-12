//
//  RioSetupWebScreen.swift
//

import SwiftUI
import WebKit

struct RioSetupWebScreen: View {
    @State private var model: RioSetupWebModel

    private let theme: RioSetupTheme

    init(url: URL, store: RioSetupSessionStoring, theme: RioSetupTheme, onFailure: @escaping () -> Void) {
        self.theme = theme
        // SwiftUI may run this initializer more than once. The model is cheap until `makeWebView()`.
        _model = State(initialValue: RioSetupWebModel(url: url, store: store, onFailure: onFailure))
    }

    var body: some View {
        ZStack {
            theme.webBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                RioSetupWebContainer(model: model)

                Divider()
                    .overlay(Color.black.opacity(0.08))

                HStack(spacing: 36) {
                    barButton("arrow.backward", isEnabled: model.canGoBack, action: model.goBack)
                    barButton("arrow.triangle.2.circlepath", action: model.reload)
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(.ultraThinMaterial)
            }

            if model.isLoading {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.webTint))
                        .scaleEffect(1.8)
                }
                .allowsHitTesting(false)
            }
        }
        .persistentSystemOverlays(.hidden)
    }

    private func barButton(_ symbol: String, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isEnabled ? theme.webTint : Color.gray.opacity(0.4))
                .frame(width: 44, height: 44)
        }
        .disabled(!isEnabled)
    }
}

private struct RioSetupWebContainer: UIViewRepresentable {
    let model: RioSetupWebModel

    func makeUIView(context: Context) -> WKWebView { model.makeWebView() }
    func updateUIView(_ webView: WKWebView, context: Context) {}
}

// MARK: - Model

/// Owns the web view and its navigation rules.
@MainActor @Observable
final class RioSetupWebModel: NSObject, WKNavigationDelegate, WKUIDelegate {
    private(set) var isLoading = true
    private(set) var canGoBack = false

    private let url: URL
    private let store: RioSetupSessionStoring
    private let onFailure: () -> Void
    /// First web session only: keep refreshing the saved URL as redirects settle.
    private let shouldCaptureURL: Bool
    @ObservationIgnored private var webView: WKWebView?
    @ObservationIgnored private var didFail = false
    @ObservationIgnored private var lastMainFrameWasSuccess = false
    @ObservationIgnored private var revealTimeout: Task<Void, Never>?

    private static let compatibilityScript = """
    (function () {
      if (typeof Notification === 'undefined') {
        window.Notification = function () {};
        window.Notification.permission = 'default';
        window.Notification.requestPermission = function () {
          return Promise.resolve('default');
        };
      } else if (typeof Notification.permission === 'undefined') {
        Notification.permission = 'default';
      }
      if (!navigator.permissions || typeof navigator.permissions.query !== 'function') {
        navigator.permissions = {
          query: function () {
            return Promise.resolve({ state: 'prompt', onchange: null });
          }
        };
      }

      // Keep popup-based tracker redirects in the current tab. Returning the
      // window matters: some scripts stop when window.open() returns null.
      window.open = function (url, target, features) {
        if (typeof url === 'string' && url.length > 0) {
          window.location.assign(url);
        }
        return window;
      };
    })();
    """

    init(url: URL, store: RioSetupSessionStoring, onFailure: @escaping () -> Void) {
        self.url = url
        self.store = store
        self.onFailure = onFailure
        self.shouldCaptureURL = store.savedLastURL == nil
    }

    func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.userContentController.addUserScript(
            WKUserScript(source: Self.compatibilityScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.backgroundColor = .white
        webView.isOpaque = true
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = RioSetupUserAgent.safari
        self.webView = webView

        // Redirect chains must never leave the spinner stuck.
        revealTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled { self?.reveal() }
        }
        webView.load(URLRequest(url: url))
        return webView
    }

    func goBack() { webView?.goBack() }
    func reload() { webView?.reload() }

    private func reveal() {
        revealTimeout?.cancel()
        revealTimeout = nil
        isLoading = false
    }

    /// Falls back to native only while web has never succeeded.
    private func fail() {
        guard store.savedLastURL == nil, !didFail else { return }
        didFail = true
        store.hasShownNativeShell = true
        rioSetupLog("web failed on first load, falling back to native")
        onFailure()
    }

    private func handleLoadError(_ error: Error) {
        // A redirect cancels the previous navigation. That is not a load failure.
        let nsError = error as NSError
        guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
        reveal()
        fail()
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url,
              ["mailto", "tel", "sms"].contains(url.scheme?.lowercased()) else {
            return .allow
        }
        if UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
        }
        return .cancel
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        guard navigationResponse.isForMainFrame,
              let http = navigationResponse.response as? HTTPURLResponse else {
            return .allow
        }

        if (200...299).contains(http.statusCode) {
            lastMainFrameWasSuccess = true
            return .allow
        }

        lastMainFrameWasSuccess = false
        // Only a main-frame HTTP error on the first load sends the user to native.
        guard shouldCaptureURL, !didFail, (400...599).contains(http.statusCode) else {
            return .allow
        }
        reveal()
        fail()
        return .cancel
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        reveal()
        canGoBack = webView.canGoBack
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        reveal()
        canGoBack = webView.canGoBack
        // Persist the document URL after redirects (HTTP / JS). Overwrite while this
        // is still the first successful web session so the final landing URL is kept.
        guard shouldCaptureURL, lastMainFrameWasSuccess, !didFail,
              let finalURL = webView.url else { return }
        store.savedLastURL = finalURL
        rioSetupLog("web loaded OK, saved final URL: \(finalURL.absoluteString)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
}
