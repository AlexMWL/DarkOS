import SwiftUI
import WebKit
import Combine

struct OSBrowserContainerView: View {
    let processName: String
    let mainWebView: WKWebView
    
    @StateObject private var targetWebEngine = TargetWebEngine()
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. Dashboard Controller
            OSWebViewRawWrapper(webView: mainWebView)
                .onAppear {
                    targetWebEngine.setupBridge(for: mainWebView)
                }
            
            // 2. Active Tab Sheet Canvas Render
            if targetWebEngine.showTargetContent, let activeWebView = targetWebEngine.getActiveWebView() {
                OSWebViewRawWrapper(webView: activeWebView)
                    .padding(.top, 80) // Expanded margin to fit the double-row (nav bar + tab bar) layout!
                    .transition(.opacity)
                    .id(targetWebEngine.activeTabIndex) // Forces SwiftUI layout refreshes on switch
            }
        }
    }
}

// Model layout to help convert tab arrays into JSON packets for our Javascript engine
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
    
    // Array pool maintaining the sandboxed tab sessions
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
        
        // Spawn primary Tab 1 if empty
        if tabWebViews.isEmpty {
            createNewTab(withInitialURL: "https://www.bing.com")
        }
    }
    
    private func createNewTab(withInitialURL urlString: String) {
        let newWebView = WKWebView()
        newWebView.backgroundColor = .white
        newWebView.isOpaque = true
        newWebView.navigationDelegate = self
        
        // --- UPDATED: Support loading both local file nodes and public web links ---
        // --- SUPPORT LOADING BOTH LOCAL FILE NODES AND PUBLIC WEB LINKS ---
        if urlString.hasPrefix("file://"), let fileURL = URL(string: urlString) {
            // FIXED: Force symlink alignment across separate engine tabs
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
    
    // Serializes the local tabs state data and passes it straight across the frame bridge
    private func broadcastTabsToJS() {
        let models = tabWebViews.enumerated().map { (index, webView) in
            JSTabModel(currentURL: webView.url?.absoluteString ?? "https://www.bing.com", isActive: index == activeTabIndex)
        }
        let payload = JSTabsPayload(tabs: models)
        
        if let jsonData = try? JSONEncoder().encode(payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Escapes characters safely for execution inside the evaluating JavaScript string block
            let escapedJson = jsonString.replacingOccurrences(of: "'", with: "\\'")
            
            DispatchQueue.main.async {
                self.mainUiWebView?.evaluateJavaScript("window.updateTabsUI('\(escapedJson)');", completionHandler: nil)
            }
        }
    }
    
    // WKNavigationDelegate: Updates your tabs array strings dynamically as you browse links
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        broadcastTabsToJS()
    }
    
    // Process Interceptor for JavaScript Actions
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
            // Check if a specific target URL or file path was passed down in the data packet payload
            if let customURLString = body["data"] as? String, !customURLString.isEmpty {
                // Direct the tab engine to load your custom app file instead of the default homepage
                createNewTab(withInitialURL: customURLString)
            } else {
                // Fallback normal behavior when hitting the '+' button manually
                createNewTab(withInitialURL: "https://www.bing.com")
            }
        case "selectTab":
            if let indexStr = body["data"] as? String, let targetIndex = Int(indexStr), tabWebViews.indices.contains(targetIndex) {
                activeTabIndex = targetIndex
                broadcastTabsToJS()
            }
        case "closeTab":
            if let indexStr = body["data"] as? String, let targetIndex = Int(indexStr), tabWebViews.indices.contains(targetIndex) {
                // Safeguard: Do not delete the final remaining active tab context
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
// Satisfies the core multi-tab browser layout engine requirements
struct OSWebViewRawWrapper: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        // FIXED: Forces the Web Engine to scale dynamically with the window size!
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// Satisfies standard non-browser JavaScript app modules (like FILE_SAFE)
struct OSWebViewWrapper: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        // FIXED: Forces the Web Engine to scale dynamically with the window size!
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
