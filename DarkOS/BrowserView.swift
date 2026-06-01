// DarkOS/BrowserView.swift

import SwiftUI
import WebKit

struct BrowserTab: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var title: String
    var store: WebViewStore
    
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
    
    @State private var tabs: [BrowserTab] = []
    @State private var activeTabId: UUID?
    
    @State private var urlInputString = ""
    
    @State private var bookmarks: [Bookmark] = []
    @State private var showAddBookmarkAlert = false
    @State private var bookmarkNameInput = ""
    @State private var showBookmarksDrawer = false
    
    // Settings & State
    @AppStorage("darkos_browser_homepage") private var homepageURL: String = "https://www.google.com"
    @AppStorage("darkos_browser_is_mobile") private var isMobileMode: Bool = true
    
    @State private var showSettingsPopup = false
    @State private var newHomepageInput = ""
    @State private var showDuplicateToast = false
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    var activeTab: BrowserTab? {
        tabs.first { $0.id == activeTabId }
    }
    
    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // --- TAB BAR ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(tabs) { tab in
                            let isActive = tab.id == activeTabId
                            // The "Garage Full" Logic: If there are 4 or more tabs, only the active one stays fully expanded.
                            let showFullTab = !(tabs.count >= 4) || isActive
                            
                            HStack(spacing: showFullTab ? 8 : 0) {
                                
                                // --- THE FAVICON HEADLIGHT LOGIC ---
                                let domain = tab.url.host ?? ""
                                
                                if !domain.isEmpty && !tab.url.absoluteString.hasPrefix("file://") {
                                    // Fetch the official badge from the API
                                    AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?sz=64&domain=\(domain)")) { phase in
                                        switch phase {
                                        case .empty:
                                            Image(systemName: "globe")
                                                .font(.system(size: showFullTab ? 10 : 14))
                                                .foregroundColor(isActive ? .cyan : .gray)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: showFullTab ? 12 : 16, height: showFullTab ? 12 : 16)
                                                .cornerRadius(2)
                                        case .failure:
                                            Image(systemName: "globe")
                                                .font(.system(size: showFullTab ? 10 : 14))
                                                .foregroundColor(isActive ? .cyan : .gray)
                                        @unknown default:
                                            Image(systemName: "globe")
                                        }
                                    }
                                } else {
                                    // Show a document icon for local files, or a globe for blanks
                                    Image(systemName: tab.url.absoluteString.hasPrefix("file://") ? "doc.text.fill" : "globe")
                                        .font(.system(size: showFullTab ? 10 : 14))
                                        .foregroundColor(isActive ? .cyan : .gray)
                                }
                                
                                if showFullTab {
                                    Text(tab.title)
                                        .font(.system(size: 11, weight: isActive ? .bold : .regular, design: .monospaced))
                                        .foregroundColor(isActive ? .white : .gray)
                                        .lineLimit(1)
                                        .frame(maxWidth: 120, alignment: .leading)
                                    
                                    if tabs.count > 1 {
                                        Button(action: { closeTab(tab) }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(isActive ? .white : .gray.opacity(0.7))
                                                .padding(4)
                                                .background(Color.white.opacity(0.001))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, showFullTab ? 14 : 10)
                            .padding(.vertical, showFullTab ? 10 : 12)
                            .background(isActive ? Color(white: 0.18) : Color.white.opacity(0.03))
                            .cornerRadius(8)
                            .onTapGesture {
                                switchTab(to: tab)
                            }
                        }
                        
                        // New Tab Button
                        Button(action: { createNewTab() }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal, 10).padding(.top, 8)
                }
                .background(Color(white: 0.08))
                
                // --- TOOLBAR ---
                HStack(spacing: 12) {
                    HStack(spacing: 18) {
                        Button(action: { activeTab?.store.webView.goBack() }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(activeTab?.store.canGoBack == true ? .white : .gray)
                        }
                        .disabled(!(activeTab?.store.canGoBack ?? false))
                        
                        Button(action: { activeTab?.store.webView.goForward() }) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(activeTab?.store.canGoForward == true ? .white : .gray)
                        }
                        .disabled(!(activeTab?.store.canGoForward ?? false))
                        
                        Button(action: { activeTab?.store.webView.reload() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: goHome) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Address Bar
                    HStack {
                        Image(systemName: urlInputString.hasPrefix("https") ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 10))
                            .foregroundColor(urlInputString.hasPrefix("https") ? .gray : .red)
                        
                        TextField("Search or type URL", text: $urlInputString)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onSubmit {
                                triggerNavigation()
                            }
                        
                        // NEW: The Smart Clear Button!
                        if !urlInputString.isEmpty {
                            Button(action: {
                                urlInputString = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Button(action: { prepareAddBookmark() }) {
                            Image(systemName: isBookmarked(urlInputString) ? "star.fill" : "star")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isBookmarked(urlInputString) ? .yellow : .gray)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(16)
                    
                    HStack(spacing: 16) {
                        Button(action: { showBookmarksDrawer.toggle() }) {
                            Image(systemName: "bookmark.square.fill")
                                .font(.system(size: 16))
                                .foregroundColor(showBookmarksDrawer ? .cyan : .gray)
                        }
                        
                        Button(action: {
                            newHomepageInput = homepageURL
                            showSettingsPopup = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color(white: 0.18))
                
                if showBookmarksDrawer {
                    bookmarksListView
                }
                
                // --- WEB VIEWS ---
                ZStack {
                    if tabs.isEmpty {
                        VStack {
                            Spacer()
                            Text("NO ACTIVE TABS.").font(.system(size: 12, design: .monospaced)).foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        ForEach(tabs) { tab in
                            DarkOSWebViewRepresentable(url: tab.url, store: tab.store) { updatedTitle, updatedURL in
                                updateTabMetrics(for: tab.id, title: updatedTitle, url: updatedURL)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black)
                            .opacity(tab.id == activeTabId ? 1.0 : 0.0)
                            .allowsHitTesting(tab.id == activeTabId)
                        }
                    }
                }
            }
            
            // --- SETTINGS POPUP ---
            if showSettingsPopup {
                Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { showSettingsPopup = false }
                
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "slider.horizontal.3").foregroundColor(.cyan)
                        Text("BROWSER CONFIG").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.white)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Default Homepage & Home URL:")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        TextField("https://...", text: $newHomepageInput)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(10)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.4), lineWidth: 1))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle(isOn: $isMobileMode) {
                            Text("Request Mobile Websites")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .cyan))
                    }
                    
                    Button(action: saveSettings) {
                        Text("SAVE & APPLY")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.cyan)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                    }
                }
                .padding(20)
                .frame(width: 320)
                .background(Color(white: 0.15))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.8), radius: 20, y: 10)
            }
            
            // --- TOAST ---
            if showDuplicateToast {
                VStack {
                    Text("ERROR: BOOKMARK EXACT URL ALREADY EXISTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .shadow(radius: 5)
                        .padding(.top, 100)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut, value: showDuplicateToast)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .darkOSInjectModule)) { notification in
            if let localURL = notification.object as? URL {
                injectLocalModuleTab(fileURL: localURL)
            }
        }
        .onAppear {
            loadPersistentBookmarks()
            if tabs.isEmpty {
                let initialURL = URL(string: homepageURL) ?? URL(string: "https://www.google.com")!
                let firstTab = BrowserTab(url: initialURL, title: "Connecting...", store: WebViewStore(isMobile: isMobileMode))
                tabs.append(firstTab)
                activeTabId = firstTab.id
                urlInputString = initialURL.absoluteString
            }
        }
        .alert("SAVE BOOKMARK", isPresented: $showAddBookmarkAlert) {
            TextField("Bookmark Anchor Name", text: $bookmarkNameInput)
                .autocapitalization(.none)
            Button("Add") {
                saveBookmark(name: bookmarkNameInput, urlString: urlInputString)
                bookmarkNameInput = ""
            }
            Button("CANCEL", role: .cancel) { bookmarkNameInput = "" }
        }
    }
    
    private var bookmarksListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(">>> BOOKMARKS INDEX")
                .font(.system(size: 9, design: .monospaced)).foregroundColor(.cyan.opacity(0.7))
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
                                    .foregroundColor(.white)
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
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Divider().background(Color.white.opacity(0.1)).padding(.top, 4)
        }
        .padding(.vertical, 8)
        .background(Color(white: 0.18))
    }
    
    private func saveSettings() {
        var cleanURL = newHomepageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.lowercased().hasPrefix("http") && !cleanURL.isEmpty {
            cleanURL = "https://" + cleanURL
        }
        homepageURL = cleanURL.isEmpty ? "https://www.google.com" : cleanURL
        
        for tab in tabs {
            tab.store.updateUserAgent(isMobile: isMobileMode)
        }
        
        showSettingsPopup = false
    }
    
    private func goHome() {
        let home = homepageURL.isEmpty ? "https://www.google.com" : homepageURL
        guard let url = URL(string: home) else { return }
        
        if let activeId = activeTabId, let index = tabs.firstIndex(where: { $0.id == activeId }) {
            tabs[index].url = url
            tabs[index].store.load(url: url)
            urlInputString = url.absoluteString
        } else {
            createNewTab(with: url)
        }
    }
    
    private func injectLocalModuleTab(fileURL: URL) {
        let labelName = fileURL.deletingPathExtension().lastPathComponent.uppercased()
        let newTab = BrowserTab(url: fileURL, title: labelName, store: WebViewStore(isMobile: isMobileMode))
        tabs.append(newTab)
        switchTab(to: newTab)
    }
    
    private func createNewTab(with url: URL? = nil) {
        let startURL = url ?? URL(string: homepageURL) ?? URL(string: "https://www.google.com")!
        let newTab = BrowserTab(url: startURL, title: "New Tab", store: WebViewStore(isMobile: isMobileMode))
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
    }
    
    private func triggerNavigation() {
        let cleanInput = urlInputString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return }
        
        let finalURL: URL?
        
        if cleanInput.contains(" ") || !cleanInput.contains(".") {
            let encodedQuery = cleanInput.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            finalURL = URL(string: "https://www.bing.com/search?q=\(encodedQuery)")
        } else {
            var urlString = cleanInput
            if !urlString.lowercased().hasPrefix("http") {
                urlString = "https://" + urlString
            }
            finalURL = URL(string: urlString)
        }
        
        guard let url = finalURL else { return }
        urlInputString = url.absoluteString
        
        if let activeId = activeTabId, let index = tabs.firstIndex(where: { $0.id == activeId }) {
            tabs[index].url = url
            tabs[index].store.load(url: url)
        }
    }
    
    private func updateTabMetrics(for tabId: UUID, title: String?, url: URL?) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }
        if let url = url {
            tabs[index].url = url
            if tabId == activeTabId && !url.absoluteString.hasPrefix("file://") {
                DispatchQueue.main.async {
                    self.urlInputString = url.absoluteString
                }
            }
        }
        if let title = title, !title.isEmpty {
            if let currentUrl = tabs[index].url as URL?, !currentUrl.absoluteString.hasPrefix("file://") {
                tabs[index].title = title
            }
        }
    }
    
    private func prepareAddBookmark() {
        bookmarkNameInput = activeTab?.title ?? "NODE_ANCHOR"
        showAddBookmarkAlert = true
    }
    
    private func isBookmarked(_ urlString: String) -> Bool {
        let clean = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return bookmarks.contains { $0.urlString.lowercased() == clean }
    }
    
    private func saveBookmark(name: String, urlString: String) {
        let cleanName = name.isEmpty ? "LINK_NODE" : name
        let cleanURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isBookmarked(cleanURL) {
            showDuplicateToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showDuplicateToast = false
            }
            return
        }
        
        let newBookmark = Bookmark(name: cleanName, urlString: cleanURL)
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
    
    init(isMobile: Bool = true) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.backgroundColor = UIColor.black
        self.webView.isOpaque = false
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupEnvironment(isMobile: isMobile)
    }
    
    func setupEnvironment(isMobile: Bool) {
        let desktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        let mobileUA = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"
        webView.customUserAgent = isMobile ? mobileUA : desktopUA
        
        if #available(iOS 13.0, *) {
            webView.configuration.defaultWebpagePreferences.preferredContentMode = isMobile ? .mobile : .desktop
        }
        
        webView.configuration.userContentController.removeAllUserScripts()
        
        let platform = isMobile ? "iPhone" : "MacIntel"
        let touchPoints = isMobile ? 5 : 0
        let viewportContent = isMobile
            ? "width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes"
            : "width=1024, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes"
            
        let spoofScript = """
            Object.defineProperty(navigator, 'platform', {get: function() { return '\(platform)'; }});
            Object.defineProperty(navigator, 'maxTouchPoints', {get: function() { return \(touchPoints); }});
            Object.defineProperty(navigator, 'vendor', {get: function() { return 'Apple Computer, Inc.'; }});

            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = '\(viewportContent)';
            document.documentElement.appendChild(meta);
            
            var style = document.createElement('style');
            style.innerHTML = `
                video { object-fit: contain !important; }
                .fullscreen-button, .tiktok-player-fullscreen, [role="button"][aria-label*="Full"] { display: none !important; }
            `;
            document.documentElement.appendChild(style);
        """
        
        let spoofUserScript = WKUserScript(source: spoofScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(spoofUserScript)
        
        let antiHijackScript = """
            function enforceInline() {
                document.querySelectorAll('video').forEach(v => {
                    v.setAttribute('playsinline', '');
                    v.setAttribute('webkit-playsinline', '');
                });
            }
            enforceInline();
            const observer = new MutationObserver(enforceInline);
            observer.observe(document.body, { childList: true, subtree: true });

            window.Element.prototype.requestFullscreen = function() { return Promise.resolve(); };
            window.Element.prototype.webkitRequestFullscreen = function() { return Promise.resolve(); };
            document.addEventListener('fullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
            document.addEventListener('webkitfullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
        """
        let antiHijackUserScript = WKUserScript(source: antiHijackScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(antiHijackUserScript)
    }
    
    func updateUserAgent(isMobile: Bool) {
        let targetUA = isMobile
            ? "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1"
            : "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        if webView.customUserAgent != targetUA {
            setupEnvironment(isMobile: isMobile)
            if webView.url != nil {
                webView.reload()
            }
        }
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
        // Intentionally left blank to fix the Double-Loading Stutter Step!
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
