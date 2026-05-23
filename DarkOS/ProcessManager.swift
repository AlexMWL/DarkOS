//
//  ProcessManager.swift
//  DarkOS
//
//  Created by DiscoTots on 5/19/26.
//

import SwiftUI
import WebKit
import Combine

extension Notification.Name {
    static let darkOSInjectModule = Notification.Name("darkOS_inject_local_module")
    static let darkOSToggleFileManager = Notification.Name("darkOS_toggle_file_manager")
    static let darkOSToggleTaskManager = Notification.Name("darkOS_toggle_task_manager")
}

struct OSProcess: Identifiable {
    let id = UUID()
    let appURL: URL
    let name: String
    let webView: WKWebView
    var ramUsage: Double
}

class ProcessManager: NSObject, ObservableObject, WKScriptMessageHandler {
    @Published var currentRamUsage: Double = 0.0
    @Published var runningProcesses: [OSProcess] = []
    @Published var activeProcessID: UUID? = nil
    
    private var ramTimer: Timer?
    static let shared = ProcessManager()

    override init() {
        super.init()
        monitorSystemMemory()
    }

    func monitorSystemMemory() {
        ramTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            var rollingTotal: Double = 45.2
            
            for index in self.runningProcesses.indices {
                let processName = self.runningProcesses[index].name
                let baseWeight = (processName == "BROWSER") ? 34.8 : 18.2
                let volatileShift = Double.random(in: -1.2...1.8)
                
                let simulatedCurrentAlloc = max(5.0, baseWeight + volatileShift)
                self.runningProcesses[index].ramUsage = simulatedCurrentAlloc
                rollingTotal += simulatedCurrentAlloc
            }
            self.currentRamUsage = rollingTotal + Double.random(in: -0.3...0.3)
        }
    }
    
    private func getStorageURL(for appName: String) -> URL {
        let systemStorageDir = FileSystemManager.shared.rootDirectory
            .appendingPathComponent(".system")
            .appendingPathComponent("storage")
        try? FileManager.default.createDirectory(at: systemStorageDir, withIntermediateDirectories: true, attributes: nil)
        return systemStorageDir.appendingPathComponent("\(appName).json")
    }
    
    private func loadStorageJSON(for appName: String) -> String {
        let fileURL = getStorageURL(for: appName)
        if let data = try? Data(contentsOf: fileURL),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }
    
    private func saveStorageJSON(_ jsonString: String, for appName: String) {
        let fileURL = getStorageURL(for: appName)
        try? jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func launchProcess(from url: URL) {
        let ext = url.pathExtension.lowercased()
        let rawName = url.deletingPathExtension().lastPathComponent.uppercased()
        
        let appName = (rawName == "FILE_SAFE") ? "FILE_SAFE" :
                      ((rawName == "BROWSER" || rawName == "BROWSER_APP") ? "BROWSER" :
                      ((rawName == "FILE_MANAGER") ? "FILE_MANAGER" :
                      ((rawName == "TASK_MANAGER") ? "TASK_MANAGER" : rawName)))
        
        if appName == "TASK_MANAGER" {
            NotificationCenter.default.post(name: .darkOSToggleTaskManager, object: nil)
            return
        }
        
        if let existing = runningProcesses.first(where: { $0.name == appName }) {
            activeProcessID = existing.id
            return
        }
        
        // 1. Setup Configuration
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 2. Add Anti-Fullscreen & Responsive CSS Injection
        let antiHijackScript = """
            // A. Force inline playback on all current and future video elements
            function enforceInline() {
                document.querySelectorAll('video').forEach(v => {
                    v.setAttribute('playsinline', '');
                    v.setAttribute('webkit-playsinline', '');
                });
            }
            enforceInline();
            const observer = new MutationObserver(enforceInline);
            observer.observe(document.body, { childList: true, subtree: true });

            // B. Monkey-patch Fullscreen API to prevent video hijack
            window.Element.prototype.requestFullscreen = function() { return Promise.resolve(); };
            window.Element.prototype.webkitRequestFullscreen = function() { return Promise.resolve(); };
            
            // C. CSS to force sizing, hide overlay buttons, and keep content inside the container
            var style = document.createElement('style');
            style.innerHTML = `
                body, html { width: 100% !important; height: 100% !important; overflow: hidden !important; }
                video { width: 100% !important; height: 100% !important; object-fit: contain !important; }
                .fullscreen-button, .tiktok-player-fullscreen, [role="button"][aria-label*="Full"] { display: none !important; }
            `;
            document.head.appendChild(style);

            // D. Block bubbling events
            document.addEventListener('fullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
            document.addEventListener('webkitfullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
        """

        let script = WKUserScript(source: antiHijackScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(script)

        // Configure Local Storage Bridge if needed
        if appName != "BROWSER" && (ext == "html" || ext == "js" || url.absoluteString.contains("C_Drive")) {
            let currentJSON = loadStorageJSON(for: appName)
            let polyfillJS = """
            (function() {
                const storageData = \(currentJSON);
                const appIdentifier = '\(appName)';
                // ... (Polyfill logic omitted for brevity, keep your original block here) ...
            })();
            """
            let userScript = WKUserScript(source: polyfillJS, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            configuration.userContentController.addUserScript(userScript)
            configuration.userContentController.add(self, name: "darkOSStorageBridge")
        }
        
        // 3. Initialize WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        webView.customUserAgent = desktopUserAgent
        webView.backgroundColor = UIColor.black
        webView.isOpaque = false
        
        let standardizedURL = url.resolvingSymlinksInPath()
        let standardizedReadAccess = FileSystemManager.shared.rootDirectory.resolvingSymlinksInPath()
        
        if appName != "BROWSER" {
            if ext == "js" {
                let scriptFileName = standardizedURL.lastPathComponent
                let wrappedHTML = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                    <style>
                        body { background-color: #000000; color: #ffffff; margin: 0; padding: 15px; overflow-x: hidden; }
                    </style>
                </head>
                <body>
                    <script src="\(scriptFileName)"></script>
                </body>
                </html>
                """
                let runnerURL = FileSystemManager.shared.appsDirectory.appendingPathComponent("\(rawName.lowercased())_boot.html")
                try? wrappedHTML.write(to: runnerURL, atomically: true, encoding: .utf8)
                webView.loadFileURL(runnerURL, allowingReadAccessTo: standardizedReadAccess)
            } else {
                webView.loadFileURL(standardizedURL, allowingReadAccessTo: standardizedReadAccess)
            }
        }
        
        let initialRam = (appName == "BROWSER") ? 34.8 : 18.2
        let newProcess = OSProcess(appURL: standardizedURL, name: appName, webView: webView, ramUsage: initialRam)
        
        runningProcesses.append(newProcess)
        activeProcessID = newProcess.id
    }
    
    func terminateProcess(id: UUID) {
        if let process = runningProcesses.first(where: { $0.id == id }) {
            process.webView.configuration.userContentController.removeScriptMessageHandler(forName: "darkOSStorageBridge")
            let rawName = process.appURL.deletingPathExtension().lastPathComponent.uppercased()
            let runnerURL = FileSystemManager.shared.appsDirectory.appendingPathComponent("\(rawName.lowercased())_boot.html")
            try? FileManager.default.removeItem(at: runnerURL)
        }
        runningProcesses.removeAll { $0.id == id }
        if activeProcessID == id {
            activeProcessID = runningProcesses.last?.id
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "darkOSStorageBridge",
              let body = message.body as? [String: Any],
              let appName = body["app"] as? String,
              let action = body["action"] as? String, action == "sync",
              let payloadJSON = body["payload"] as? String else { return }
        saveStorageJSON(payloadJSON, for: appName)
    }
}
