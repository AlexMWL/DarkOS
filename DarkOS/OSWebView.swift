import SwiftUI
import WebKit
import Combine

struct OSBrowserContainerView: View {
    let processName: String
    let mainWebView: WKWebView
    
    @StateObject private var targetWebEngine = TargetWebEngine()
    
    var body: some View {
        ZStack(alignment: .top) {
            
            OSWebViewWrapper(webView: mainWebView)
                .onAppear {
                    targetWebEngine.setupBridge(for: mainWebView)
                }
            
            if targetWebEngine.showTargetContent, let activeWebView = targetWebEngine.getActiveWebView() {
                OSWebViewWrapper(webView: activeWebView)
                    .padding(.top, 80)
                    .transition(.opacity)
                    .id(targetWebEngine.activeTabIndex)
            }
        }
    }
}

struct JSTabModel: Encodable {
    let currentURL: String
    let isActive: Bool
}
struct JSTabsPayload: Encodable {
    let tabs: [JSTabModel]
}

class TargetWebEngine: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    @Published var showTargetContent = false
    @Published var activeTabIndex: Int = 0
    
    private var tabWebViews: [WKWebView] = []
    private var mainUiWebView: WKWebView?
    
    func getActiveWebView() -> WKWebView? {
        guard tabWebViews.indices.contains(activeTabIndex) else { return nil }
        return tabWebViews[activeTabIndex]
    }
    
    func setupBridge(for mainUiWebView: WKWebView) {
        self.mainUiWebView = mainUiWebView
        mainUiWebView.configuration.userContentController.removeScriptMessageHandler(forName: "darkOSBridge")
        mainUiWebView.configuration.userContentController.add(self, name: "darkOSBridge")
        
        if tabWebViews.isEmpty {
            createNewTab(withInitialURL: "https://www.bing.com")
        }
    }
    
    private func createNewTab(withInitialURL urlString: String) {
        let newWebView = WKWebView()
        newWebView.backgroundColor = .white
        newWebView.isOpaque = true
        newWebView.navigationDelegate = self
        
        if urlString.hasPrefix("file://"), let fileURL = URL(string: urlString) {
            let standardizedURL = fileURL.resolvingSymlinksInPath()
            let standardizedReadAccess = FileSystemManager.shared.rootDirectory.resolvingSymlinksInPath()
            newWebView.loadFileURL(standardizedURL, allowingReadAccessTo: standardizedReadAccess)
        } else if let url = URL(string: urlString) {
            newWebView.load(URLRequest(url: url))
        }
        
        tabWebViews.append(newWebView)
        activeTabIndex = tabWebViews.count - 1
        showTargetContent = true
        
        broadcastTabsToJS()
    }
    
    private func broadcastTabsToJS() {
        let models = tabWebViews.enumerated().map { (index, webView) in
            JSTabModel(currentURL: webView.url?.absoluteString ?? "https://www.bing.com", isActive: index == activeTabIndex)
        }
        let payload = JSTabsPayload(tabs: models)
        
        if let jsonData = try? JSONEncoder().encode(payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let escapedJson = jsonString.replacingOccurrences(of: "'", with: "\\'")
            
            DispatchQueue.main.async {
                self.mainUiWebView?.evaluateJavaScript("window.updateTabsUI('\(escapedJson)');", completionHandler: nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        broadcastTabsToJS()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "darkOSBridge",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }
              
        switch action {
        case "loadURL":
            if let urlString = body["data"] as? String, let url = URL(string: urlString) {
                getActiveWebView()?.load(URLRequest(url: url))
            }
        case "createTab":
            
            if let customURLString = body["data"] as? String, !customURLString.isEmpty {
                
                createNewTab(withInitialURL: customURLString)
            } else {
                
                createNewTab(withInitialURL: "https://www.bing.com")
            }
        case "selectTab":
            if let indexStr = body["data"] as? String, let targetIndex = Int(indexStr), tabWebViews.indices.contains(targetIndex) {
                activeTabIndex = targetIndex
                broadcastTabsToJS()
            }
        case "closeTab":
            if let indexStr = body["data"] as? String, let targetIndex = Int(indexStr), tabWebViews.indices.contains(targetIndex) {
                
                if tabWebViews.count > 1 {
                    tabWebViews.remove(at: targetIndex)
                    activeTabIndex = max(0, targetIndex - 1)
                    broadcastTabsToJS()
                }
            }
        case "back":
            if let web = getActiveWebView(), web.canGoBack { web.goBack() }
        case "forward":
            if let web = getActiveWebView(), web.canGoForward { web.goForward() }
        case "reload":
            getActiveWebView()?.reload()
        default:
            break
        }
    }
}

struct OSWebViewWrapper: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
