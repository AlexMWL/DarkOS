// DarkOS/FileVaultManager.swift

import Foundation
import Combine

class FileVaultManager {
    private static var hasMigrated = false
    
    private static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static var vaultRootDirectory: URL {
        let url = getDocumentsDirectory().appendingPathComponent(".FileVault").resolvingSymlinksInPath()
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        if !hasMigrated {
            hasMigrated = true
            migrateOldVaultFiles(to: url)
        }
        return url
    }
    
    private static func migrateOldVaultFiles(to newRoot: URL) {
        let oldRoot = getDocumentsDirectory()
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(at: oldRoot, includingPropertiesForKeys: nil) else { return }
        for url in contents {
            let name = url.lastPathComponent
            if name == "C_Drive" || name == ".Trash" || name == ".SafeTrash" || name == ".FileVault" || name.hasPrefix(".") {
                continue
            }
            let dest = newRoot.appendingPathComponent(name)
            try? fileManager.moveItem(at: url, to: dest)
        }
    }
    
    static var safeBackStack: [URL] = []
    static var safeForwardStack: [URL] = []
    
    static var currentSafeDirectory: URL = vaultRootDirectory
    
    private static var safeTrashDirectory: URL {
        let url = vaultRootDirectory.appendingPathComponent(".SafeTrash")
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
    
    static func isProtectedModulesFolder(_ url: URL) -> Bool {
        if url.lastPathComponent == "Modules" {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                return isDir.boolValue
            }
            return true
        }
        return false
    }
    
    static func renameSafeFile(fileURL: URL, to newName: String) {
        if isProtectedModulesFolder(fileURL) { return }
        let ext = fileURL.pathExtension
        var fullNewName = newName
        if !ext.isEmpty && !newName.lowercased().hasSuffix(".\(ext.lowercased())") {
            fullNewName = "\(newName).\(ext)"
        }
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(fullNewName)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
    
    static func moveSafeItemToTrash(fileURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
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
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
    
    static func restoreFromSafeTrash(fileURL: URL) {
        let dest = currentSafeDirectory.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: fileURL, to: dest)
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
    
    static func copySafeFile(fileURL: URL, to directoryURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        let dest = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.copyItem(at: fileURL, to: dest)
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
    
    static func moveSafeFile(fileURL: URL, to directoryURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        let dest = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.moveItem(at: fileURL, to: dest)
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
    
    static func navigateSafeIntoFolder(_ folderURL: URL) {
        safeBackStack.append(currentSafeDirectory)
        safeForwardStack.removeAll()
        currentSafeDirectory = folderURL
    }
    
    static func navigateSafeBack() {
        guard !safeBackStack.isEmpty else { return }
        let previous = safeBackStack.removeLast()
        safeForwardStack.append(currentSafeDirectory)
        currentSafeDirectory = previous
    }
    
    static func navigateSafeForward() {
        guard !safeForwardStack.isEmpty else { return }
        let next = safeForwardStack.removeLast()
        safeBackStack.append(currentSafeDirectory)
        currentSafeDirectory = next
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
        if saveBinaryFile(filename: sourceURL.lastPathComponent, data: data) {
            try? FileManager.default.removeItem(at: sourceURL)
            DispatchQueue.main.async {
                FileSystemManager.shared.refreshInstalledModules()
                FileSystemManager.shared.objectWillChange.send()
            }
            return true
        }
        return false
    }
    
    static func exportToInternalPath(fileURL: URL) -> Bool {
        guard let data = readBinaryFile(at: fileURL) else { return false }
        let cDriveURL = FileSystemManager.shared.rootDirectory.appendingPathComponent(fileURL.lastPathComponent)
        do {
            try data.write(to: cDriveURL, options: .atomic)
            try? FileManager.default.removeItem(at: fileURL)
            DispatchQueue.main.async {
                FileSystemManager.shared.refreshInstalledModules()
                FileSystemManager.shared.objectWillChange.send()
            }
            return true
        } catch {
            return false
        }
    }
    
    static func exportAndMove(fileURL: URL, to destinationDir: URL) -> Bool {
        guard let data = readBinaryFile(at: fileURL) else { return false }
        let destFileURL = destinationDir.appendingPathComponent(fileURL.lastPathComponent)
        do {
            try data.write(to: destFileURL, options: .atomic)
            try? FileManager.default.removeItem(at: fileURL)
            DispatchQueue.main.async {
                FileSystemManager.shared.refreshInstalledModules()
                FileSystemManager.shared.objectWillChange.send()
            }
            return true
        } catch {
            return false
        }
    }
    
    static func wipeEntireVault() {
        let fileManager = FileManager.default
        let root = vaultRootDirectory
        
        // Remove regular safe contents
        if let contents = try? fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
            for url in contents {
                try? fileManager.removeItem(at: url)
            }
        }
        
        // Remove trash contents
        let trash = safeTrashDirectory
        if let trashContents = try? fileManager.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil) {
            for url in trashContents {
                try? fileManager.removeItem(at: url)
            }
        }
        
        // Reset navigation stacks and directory
        safeBackStack.removeAll()
        safeForwardStack.removeAll()
        currentSafeDirectory = vaultRootDirectory
        
        _ = deletePIN()
        
        DispatchQueue.main.async {
            FileSystemManager.shared.refreshInstalledModules()
            FileSystemManager.shared.objectWillChange.send()
        }
    }
}
