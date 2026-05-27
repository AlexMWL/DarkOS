// DarkOS/DarkOSEngine.swift

import WebKit

extension WKWebViewConfiguration {
    static var darkOSStandard: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let darkOSInjectionScript = """
            // 1. Force the viewport to scale correctly
            if (!document.querySelector('meta[name="viewport"]')) {
                var meta = document.createElement('meta');
                meta.name = "viewport";
                meta.content = "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no";
                document.head.appendChild(meta);
            }

            // 2. The Scale-to-Fit Engine
            function fitToFrame() {
                const contentWidth = document.body.scrollWidth;
                const frameWidth = window.innerWidth;
                const scale = frameWidth / contentWidth;
                
                // Only scale if the content is bigger than the frame
                if (contentWidth > frameWidth) {
                    document.body.style.transform = `scale(${scale})`;
                    document.body.style.transformOrigin = 'top left';
                    document.body.style.width = `${contentWidth}px`;
                }
            }
            
            // 3. Hijack Media/Fullscreen
            function enforceInline() {
                document.querySelectorAll('video').forEach(v => {
                    v.setAttribute('playsinline', '');
                    v.setAttribute('webkit-playsinline', '');
                });
            }
            
            window.onload = () => { enforceInline(); fitToFrame(); };
            window.onresize = () => { fitToFrame(); };
            const observer = new MutationObserver(enforceInline);
            observer.observe(document.body, { childList: true, subtree: true });

            // Block fullscreen
            window.Element.prototype.requestFullscreen = function() { return Promise.resolve(); };
            
            var style = document.createElement('style');
            style.innerHTML = `
                body { overflow-x: hidden !important; }
            `;
            document.head.appendChild(style);
        """
        
        let script = WKUserScript(source: darkOSInjectionScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(script)
        
        return config
    }
}
