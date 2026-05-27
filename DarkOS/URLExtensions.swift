// DarkOS/URLExtensions.swift

import Foundation

extension URL: Identifiable {
    public var id: String { self.absoluteString }
    
    var isDarkOSDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
