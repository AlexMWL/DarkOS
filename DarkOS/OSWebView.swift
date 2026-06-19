// DarkOS/OSWebView.swift

import SwiftUI
import WebKit

struct OSWebViewWrapper: UIViewRepresentable {
    let webView: WKWebView
    
    func makeUIView(context: Context) -> WKWebView {
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
