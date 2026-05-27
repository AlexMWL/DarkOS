// DarkOS/FileSafeManager.swift

import Foundation

class FileSafeManager {
    static var currentSafeDirectory: URL = getDocumentsDirectory()
    
    private static var safeTrashDirectory: URL {
        let url = getDocumentsDirectory().appendingPathComponent(".SafeTrash")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }
    
    static func getFailedAttempts() -> Int {
        return UserDefaults.standard.integer(forKey: "darkos_vault_fails")
    }
    
    static func recordFailedAttempt() {
        let current = getFailedAttempts()
        UserDefaults.standard.set(current + 1, forKey: "darkos_vault_fails")
    }
    
    static func resetFailedAttempts() {
        UserDefaults.standard.set(0, forKey: "darkos_vault_fails")
    }
    
    static func listCurrentSafeContents() -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: currentSafeDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return contents.sorted { url1, url2 in
            var isDir1: ObjCBool = false
            var isDir2: ObjCBool = false
            FileManager.default.fileExists(atPath: url1.path, isDirectory: &isDir1)
            FileManager.default.fileExists(atPath: url2.path, isDirectory: &isDir2)
            if isDir1.boolValue && !isDir2.boolValue { return true }
            if !isDir1.boolValue && isDir2.boolValue { return false }
            return url1.lastPathComponent.lowercased() < url2.lastPathComponent.lowercased()
        }
    }
    
    static func listSafeTrashContents() -> [URL] {
        return (try? FileManager.default.contentsOfDirectory(at: safeTrashDirectory, includingPropertiesForKeys: nil)) ?? []
    }
    
    static func createSafeFolder(named name: String) {
        let targetURL = currentSafeDirectory.appendingPathComponent(name)
        try? FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
    }
    
    static func renameSafeFile(fileURL: URL, to newName: String) {
        let ext = fileURL.pathExtension
        var fullNewName = newName
        if !ext.isEmpty && !newName.lowercased().hasSuffix(".\(ext.lowercased())") {
            fullNewName = "\(newName).\(ext)"
        }
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(fullNewName)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
    }
    
    static func moveSafeItemToTrash(fileURL: URL) {
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var dest = safeTrashDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        var counter = 1
        while FileManager.default.fileExists(atPath: dest.path) {
            let newName = ext.isEmpty ? "\(fileName) (\(counter))" : "\(fileName) (\(counter)).\(ext)"
            dest = safeTrashDirectory.appendingPathComponent(newName)
            counter += 1
        }
        
        try? FileManager.default.moveItem(at: fileURL, to: dest)
    }
    
    static func restoreFromSafeTrash(fileURL: URL) {
        let dest = getDocumentsDirectory().appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: fileURL, to: dest)
    }
    
    static func copySafeFile(fileURL: URL, to directoryURL: URL) {
        let dest = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.copyItem(at: fileURL, to: dest)
    }
    
    static func moveSafeFile(fileURL: URL, to directoryURL: URL) {
        let dest = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: fileURL, to: dest)
    }
    
    static func navigateSafeBack() {
        if currentSafeDirectory != getDocumentsDirectory() {
            currentSafeDirectory = currentSafeDirectory.deletingLastPathComponent()
        }
    }
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func saveTextFile(filename: String, content: String) -> Bool {
        let url = currentSafeDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
    
    static func readTextFile(at url: URL) -> String? {
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    private static let pinKey = "darkos_vault_pin"
    static func isPINSet() -> Bool { return UserDefaults.standard.string(forKey: pinKey) != nil }
    static func savePIN(_ pin: String) -> Bool { UserDefaults.standard.set(pin, forKey: pinKey); return true }
    
    static func verifyPIN(_ pin: String) -> Bool {
        let isValid = UserDefaults.standard.string(forKey: pinKey) == pin
        if isValid {
            resetFailedAttempts()
        } else {
            recordFailedAttempt()
        }
        return isValid
    }
    
    static func deletePIN() -> Bool {
        UserDefaults.standard.removeObject(forKey: pinKey)
        resetFailedAttempts()
        return true
    }
    
    static func saveBinaryFile(filename: String, data: Data) -> Bool {
        let url = currentSafeDirectory.appendingPathComponent(filename)
        return (try? data.write(to: url, options: .atomic)) != nil
    }
    
    static func readBinaryFile(at url: URL) -> Data? { return try? Data(contentsOf: url) }
    
    static func importFromInternalPath(sourceURL: URL) -> Bool {
        guard let data = try? Data(contentsOf: sourceURL) else { return false }
        return saveBinaryFile(filename: sourceURL.lastPathComponent, data: data)
    }
    
    static func exportToInternalPath(fileURL: URL) -> Bool {
        guard let data = readBinaryFile(at: fileURL) else { return false }
        let cDriveURL = FileSystemManager.shared.rootDirectory.appendingPathComponent(fileURL.lastPathComponent)
        do {
            try data.write(to: cDriveURL, options: .atomic)
            DispatchQueue.main.async { FileSystemManager.shared.refreshInstalledApps() }
            return true
        } catch {
            return false
        }
    }
}
