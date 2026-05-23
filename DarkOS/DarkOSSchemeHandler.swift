//
//  DarkOSSchemeHandler.swift
//  DarkOS
//
//  Created by DiscoTots on 5/20/26.
//

import Foundation
import WebKit
import UniformTypeIdentifiers

class DarkOSSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        
        let rootDir = FileSystemManager.shared.rootDirectory.resolvingSymlinksInPath()
        let relativePath = url.path
        let fileURL = rootDir.appendingPathComponent(relativePath).resolvingSymlinksInPath()
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDir), !isDir.boolValue {
            if let data = try? Data(contentsOf: fileURL) {
                let mimeType = getMimeType(for: fileURL)
                
                // UPGRADED: Construct a proper HTTP header payload mapping
                let headerFields = [
                    "Content-Type": "\(mimeType); charset=utf-8",
                    "Content-Length": String(data.count),
                    "Access-Control-Allow-Origin": "*" // Allows flexible sub-resource loading
                ]
                
                // Switching to HTTPURLResponse with a 200 status code guarantees
                // that WKWebView will compile the HTML view layout instead of showing raw code text!
                if let response = HTTPURLResponse(
                    url: url,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: headerFields
                ) {
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                    return
                }
            }
        }
        
        urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
    
    private func getMimeType(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if let utType = UTType(filenameExtension: ext),
           let mimeType = utType.preferredMIMEType {
            return mimeType
        }
        if ext == "html" { return "text/html" }
        if ext == "js"   { return "application/javascript" }
        if ext == "css"  { return "text/css" }
        return "application/octet-stream"
    }
}
