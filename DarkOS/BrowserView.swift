// DarkOS/BrowserView.swift

import SwiftUI
import WebKit

struct BrowserTab: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var title: String
    
    static func == (lhs: BrowserTab, rhs: BrowserTab) -> Bool {
        lhs.id == rhs.id
    }
}

struct Bookmark: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var urlString: String
}

struct BrowserView: View {
    @Binding var isPresented: Bool
    
    @State private var tabs: [BrowserTab] = [
        BrowserTab(url: URL(string: "https://www.google.com")!, title: "CORE_SEARCH")
    ]
    @State private var activeTabId: UUID?
    
    @State private var urlInputString = "https://www.google.com"
    
    @State private var bookmarks: [Bookmark] = []
    @State private var showAddBookmarkAlert = false
    @State private var bookmarkNameInput = ""
    @State private var showBookmarksDrawer = false
    
    @State private var webViewStore = WebViewStore()
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        if let firstTab = tabs.first {
            self._activeTabId = State(initialValue: firstTab.id)
        }
    }
    
    var activeTab: BrowserTab? {
        tabs.first { $0.id == activeTabId }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tabs) { tab in
                            let isActive = tab.id == activeTabId
                            HStack(spacing: 8) {
                                Text(tab.title.uppercased())
                                    .font(.system(size: 10, weight: isActive ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(isActive ? .black : .gray)
                                
                                if tabs.count > 1 {
                                    Button(action: { closeTab(tab) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(isActive ? .black : .red.opacity(0.7))
                                    }
                                }
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isActive ? Color.cyan : Color.white.opacity(0.05))
                            .border(Color.cyan.opacity(isActive ? 1.0 : 0.2), width: 1)
                            .onTapGesture {
                                switchTab(to: tab)
                            }
                        }
                        
                        Button(action: { createNewTab() }) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.white.opacity(0.02))
                                .border(Color.white.opacity(0.1), width: 1)
                        }
                    }
                    .padding(.horizontal).padding(.top, 6)
                }
                .background(Color.white.opacity(0.01))
                
                HStack(spacing: 12) {
                    HStack(spacing: 14) {
                        Button(action: { webViewStore.webView.goBack() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(webViewStore.canGoBack ? .cyan : .gray)
                        }
                        .disabled(!webViewStore.canGoBack)
                        
                        Button(action: { webViewStore.webView.goForward() }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(webViewStore.canGoForward ? .cyan : .gray)
                        }
                        .disabled(!webViewStore.canGoForward)
                        
                        Button(action: { webViewStore.webView.reload() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "terminal").font(.system(size: 10)).foregroundColor(.cyan.opacity(0.5))
                        TextField("TARGET_URL://", text: $urlInputString, onCommit: {
                            triggerNavigation()
                        })
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.05))
                    .border(Color.white.opacity(0.1), width: 1)
                    
                    Button(action: { prepareAddBookmark() }) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    Button(action: { showBookmarksDrawer.toggle() }) {
                        Text("BOOKMARKS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(showBookmarksDrawer ? .black : .yellow)
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .background(showBookmarksDrawer ? Color.yellow : Color.clear)
                            .border(Color.yellow, width: 1)
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(Color.white.opacity(0.02))
                .border(Color.white.opacity(0.05), width: 1)
                
                if showBookmarksDrawer {
                    bookmarksListView
                }
                
                if let activeTab = activeTab {
                    DarkOSWebViewRepresentable(url: activeTab.url, store: webViewStore) { updatedTitle, updatedURL in
                        updateActiveTabMetrics(title: updatedTitle, url: updatedURL)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    VStack {
                        Spacer()
                        Text("NO ACTIVE surf_NODES FOUND.").font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .darkOSInjectModule)) { notification in
            if let localURL = notification.object as? URL {
                injectLocalModuleTab(fileURL: localURL)
            }
        }
        .onAppear {
            loadPersistentBookmarks()
            if activeTabId == nil, let first = tabs.first {
                activeTabId = first.id
            }
        }
        .alert("SAVE CRYPTO_NODE LINK", isPresented: $showAddBookmarkAlert) {
            TextField("Bookmark Anchor Name", text: $bookmarkNameInput)
                .autocapitalization(.none)
            Button("INJECT") {
                saveBookmark(name: bookmarkNameInput, urlString: urlInputString)
                bookmarkNameInput = ""
            }
            Button("CANCEL", role: .cancel) { bookmarkNameInput = "" }
        }
    }
    
    private var bookmarksListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(">>> PERSISTENT SECURE BOOKMARKS INDEX")
                .font(.system(size: 9, design: .monospaced)).foregroundColor(.yellow.opacity(0.7))
                .padding(.horizontal)
            
            if bookmarks.isEmpty {
                Text("NO SAVED DOMAIN POINTERS COMPILED.")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.gray)
                    .padding(.horizontal).padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bookmarks) { bookmark in
                            HStack(spacing: 6) {
                                Text(bookmark.name.uppercased())
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        urlInputString = bookmark.urlString
                                        triggerNavigation()
                                    }
                                
                                Button(action: { removeBookmark(bookmark) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(.red.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Color.white.opacity(0.04))
                            .border(Color.yellow.opacity(0.3), width: 1)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Divider().background(Color.white.opacity(0.1)).padding(.top, 4)
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
    }
    
    private func injectLocalModuleTab(fileURL: URL) {
        let labelName = fileURL.deletingPathExtension().lastPathComponent.uppercased()
        let newTab = BrowserTab(url: fileURL, title: labelName)
        tabs.append(newTab)
        switchTab(to: newTab)
    }
    
    private func createNewTab() {
        let newTab = BrowserTab(url: URL(string: "https://www.google.com")!, title: "NEW_NODE")
        tabs.append(newTab)
        switchTab(to: newTab)
    }
    
    private func closeTab(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: index)
        
        if activeTabId == tab.id {
            if let nextTab = tabs.first {
                switchTab(to: nextTab)
            } else {
                activeTabId = nil
            }
        }
    }
    
    private func switchTab(to tab: BrowserTab) {
        activeTabId = tab.id
        urlInputString = tab.url.absoluteString
        webViewStore.load(url: tab.url)
    }
    
    private func triggerNavigation() {
        var cleanURLString = urlInputString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURLString.lowercased().hasPrefix("http://") && !cleanURLString.lowercased().hasPrefix("https://") {
            cleanURLString = "https://" + cleanURLString
        }
        
        guard let url = URL(string: cleanURLString) else { return }
        urlInputString = cleanURLString
        
        if let activeId = activeTabId, let index = tabs.firstIndex(where: { $0.id == activeId }) {
            tabs[index].url = url
        }
        webViewStore.load(url: url)
    }
    
    private func updateActiveTabMetrics(title: String?, url: URL?) {
        guard let activeId = activeTabId, let index = tabs.firstIndex(where: { $0.id == activeId }) else { return }
        if let url = url {
            tabs[index].url = url
            
            if !url.absoluteString.hasPrefix("file://") {
                DispatchQueue.main.async {
                    self.urlInputString = url.absoluteString
                }
            }
        }
        if let title = title, !title.isEmpty {
            
            if let currentUrl = activeTab?.url, !currentUrl.absoluteString.hasPrefix("file://") {
                tabs[index].title = title
            }
        }
    }
    
    private func prepareAddBookmark() {
        bookmarkNameInput = activeTab?.title ?? "NODE_ANCHOR"
        showAddBookmarkAlert = true
    }
    
    private func saveBookmark(name: String, urlString: String) {
        let cleanName = name.isEmpty ? "LINK_NODE" : name
        let newBookmark = Bookmark(name: cleanName, urlString: urlString)
        bookmarks.append(newBookmark)
        writeBookmarksToStorage()
    }
    
    private func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        writeBookmarksToStorage()
    }
    
    private func writeBookmarksToStorage() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "darkos_browser_bookmarks")
        }
    }
    
    private func loadPersistentBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "darkos_browser_bookmarks"),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
        }
    }
}

@Observable
class WebViewStore {
    var webView: WKWebView
    var canGoBack = false
    var canGoForward = false
    
    init() {
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let antiHijackScript = """
            // 1. Force inline playback attributes
            function enforceInline() {
                document.querySelectorAll('video').forEach(v => {
                    v.setAttribute('playsinline', '');
                    v.setAttribute('webkit-playsinline', '');
                });
            }
            enforceInline();
            const observer = new MutationObserver(enforceInline);
            observer.observe(document.body, { childList: true, subtree: true });

            // 2. Kill-switch: Mock the fullscreen API to do nothing
            window.Element.prototype.requestFullscreen = function() { 
                return Promise.resolve(); 
            };
            window.Element.prototype.webkitRequestFullscreen = function() { 
                return Promise.resolve(); 
            };
            
            // 3. CSS to force sizing and hide overlays
            var style = document.createElement('style');
            style.innerHTML = `
                body, html { width: 100% !important; height: 100% !important; overflow: hidden !important; }
                video { width: 100% !important; height: 100% !important; object-fit: contain !important; }
                .fullscreen-button, .tiktok-player-fullscreen, [role="button"][aria-label*="Full"] { display: none !important; }
            `;
            document.head.appendChild(style);

            // 4. Block events
            document.addEventListener('fullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
            document.addEventListener('webkitfullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
        """
        
        let script = WKUserScript(source: antiHijackScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        
        let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        webView.customUserAgent = desktopUserAgent
        
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func load(url: URL) {
        if url.absoluteString.hasPrefix("file://") {
            let standardizedURL = url.resolvingSymlinksInPath()
            let standardizedReadAccess = FileSystemManager.shared.rootDirectory.resolvingSymlinksInPath()
            webView.loadFileURL(standardizedURL, allowingReadAccessTo: standardizedReadAccess)
        } else {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

struct DarkOSWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let store: WebViewStore
    var onNavigationUpdate: (String?, URL?) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        store.webView.navigationDelegate = context.coordinator
        store.load(url: url)
        return store.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        
        if uiView.url != url {
            store.load(url: url)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DarkOSWebViewRepresentable
        private var titleObservation: NSKeyValueObservation?
        
        init(_ parent: DarkOSWebViewRepresentable) {
            self.parent = parent
            super.init()
            
            titleObservation = parent.store.webView.observe(\.title, options: .new) { [weak self] webView, _ in
                self?.parent.onNavigationUpdate(webView.title, webView.url)
            }
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            parent.store.canGoBack = webView.canGoBack
            parent.store.canGoForward = webView.canGoForward
            parent.onNavigationUpdate(webView.title, webView.url)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.store.canGoBack = webView.canGoBack
            parent.store.canGoForward = webView.canGoForward
            parent.onNavigationUpdate(webView.title, webView.url)
        }
    }
}
