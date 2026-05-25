//
//  DarkOSEngine.swift
//  DarkOS
//
//  Created by DiscoTots on 5/23/26.
//

import WebKit

extension WKWebViewConfiguration {
    static var darkOSStandard: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
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
            
            var style = document.createElement('style');
            style.innerHTML = `
                body, html { width: 100% !important; height: 100% !important; overflow: hidden !important; }
                video { width: 100% !important; height: 100% !important; object-fit: contain !important; }
                .fullscreen-button, .tiktok-player-fullscreen, [role="button"][aria-label*="Full"] { display: none !important; }
            `;
            document.head.appendChild(style);

            document.addEventListener('fullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
            document.addEventListener('webkitfullscreenchange', (e) => { e.stopImmediatePropagation(); }, true);
        """
        
        let script = WKUserScript(source: antiHijackScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        
        return config
    }
}
