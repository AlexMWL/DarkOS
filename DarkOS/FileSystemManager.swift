// DarkOS/FileSystemManager.swift

import Foundation
import Combine

class FileSystemManager: ObservableObject {
    static let shared = FileSystemManager()
    
    let rootDirectory: URL
    let trashDirectory: URL
    let modulesDirectory: URL
    
    @Published var currentDirectory: URL
    @Published var installedModules: [URL] = []
    
    @Published var desktopShortcuts: [URL] = []
    @Published var dockShortcuts: [URL] = []
    @Published var startMenuShortcuts: [URL] = []
    
    @Published var backStack: [URL] = []
    @Published var forwardStack: [URL] = []
    @Published var hiddenBuiltInApps: Set<String> = []
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.rootDirectory = paths[0].appendingPathComponent("C_Drive").resolvingSymlinksInPath()
        self.trashDirectory = paths[0].appendingPathComponent(".Trash").resolvingSymlinksInPath()
        self.modulesDirectory = rootDirectory.appendingPathComponent("Modules").resolvingSymlinksInPath()
        self.currentDirectory = rootDirectory
        
        if let hiddenArray = UserDefaults.standard.stringArray(forKey: "darkos_hidden_builtin_desktop") {
            self.hiddenBuiltInApps = Set(hiddenArray)
        }
        
        createSystemDirectories()
        loadPinnableStates()
        refreshInstalledModules()
    }
    
    func hideBuiltInApp(_ name: String) {
        hiddenBuiltInApps.insert(name)
        UserDefaults.standard.set(Array(hiddenBuiltInApps), forKey: "darkos_hidden_builtin_desktop")
        objectWillChange.send()
    }
    
    func showBuiltInApp(_ name: String) {
        hiddenBuiltInApps.remove(name)
        UserDefaults.standard.set(Array(hiddenBuiltInApps), forKey: "darkos_hidden_builtin_desktop")
        objectWillChange.send()
    }
    
    private func createSystemDirectories() {
        try? FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: trashDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // Migrate legacy Apps folder to Modules folder if it exists
        let oldAppsDir = rootDirectory.appendingPathComponent("Apps").resolvingSymlinksInPath()
        if FileManager.default.fileExists(atPath: oldAppsDir.path) {
            try? FileManager.default.moveItem(at: oldAppsDir, to: modulesDirectory)
        }
        try? FileManager.default.createDirectory(at: modulesDirectory, withIntermediateDirectories: true, attributes: nil)
        
        seedDefaultModules()
        
        let browserVirtualURL = rootDirectory.appendingPathComponent("Browser")
        if !FileManager.default.fileExists(atPath: browserVirtualURL.path) {
            try? "DARKOS_NATIVE_BROWSER_BINARY".write(to: browserVirtualURL, atomically: true, encoding: .utf8)
        }
    }
    
    private func seedDefaultModules() {
        let defaultModules = ["weather.js", "musicplayer.js"]
        let fm = FileManager.default
        
        #if targetEnvironment(simulator)
        let devModulesPath = "/Users/discotots/Desktop/DarkOS/Modules"
        if fm.fileExists(atPath: devModulesPath) {
            for name in defaultModules {
                let srcURL = URL(fileURLWithPath: devModulesPath).appendingPathComponent(name)
                let destURL = modulesDirectory.appendingPathComponent(name)
                if fm.fileExists(atPath: srcURL.path) {
                    try? fm.removeItem(at: destURL)
                    try? fm.copyItem(at: srcURL, to: destURL)
                }
            }
            refreshInstalledModules()
            return
        }
        #endif
        
        for name in defaultModules {
            let baseName = (name as NSString).deletingPathExtension
            let ext = (name as NSString).pathExtension
            guard let bundleURL = Bundle.main.url(forResource: baseName, withExtension: ext) else { continue }
            let destURL = modulesDirectory.appendingPathComponent(name)
            if !fm.fileExists(atPath: destURL.path) {
                try? fm.copyItem(at: bundleURL, to: destURL)
            }
        }
        refreshInstalledModules()
    }
    
    func listCurrentDirectoryContents() -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        let sorted = contents.sorted { url1, url2 in
            var isDir1: ObjCBool = false
            var isDir2: ObjCBool = false
            FileManager.default.fileExists(atPath: url1.path, isDirectory: &isDir1)
            FileManager.default.fileExists(atPath: url2.path, isDirectory: &isDir2)
            if isDir1.boolValue && !isDir2.boolValue { return true }
            if !isDir1.boolValue && isDir2.boolValue { return false }
            return url1.lastPathComponent.lowercased() < url2.lastPathComponent.lowercased()
        }
        return sorted.filter { $0.lastPathComponent != "Browser" }
    }
    
    func listTrashContents() -> [URL] {
        return (try? FileManager.default.contentsOfDirectory(at: trashDirectory, includingPropertiesForKeys: nil)) ?? []
    }
    
    func refreshInstalledModules() {
        var modules: [URL] = []
        
        // Always include the built-in apps in the Start Menu
        let builtIns = ["Browser", "Module_Manager", "File_Explorer"]
        for name in builtIns {
            let url = resolveShortcutURL(for: name)
            modules.append(url)
        }
        
        // Recursively scan rootDirectory (C_Drive) for .html and .js files
        if let enumerator = FileManager.default.enumerator(at: rootDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ext == "html" || ext == "js" {
                    let resolved = fileURL.resolvingSymlinksInPath()
                    if !modules.contains(resolved) {
                        modules.append(resolved)
                    }
                }
            }
        }
        
        // Also check startMenuShortcuts just in case
        for shortcut in startMenuShortcuts {
            let resolved = shortcut.resolvingSymlinksInPath()
            if !modules.contains(resolved) {
                modules.append(resolved)
            }
        }
        
        // Remove File_Vault or any duplicates
        modules.removeAll { $0.lastPathComponent == "File_Vault" }
        self.installedModules = modules
    }
    
    func loadPinnableStates() {
        if var desktopNames = UserDefaults.standard.stringArray(forKey: "darkos_desktop_shortcuts") {
            desktopNames.removeAll { $0 == "File_Safe" || $0 == "File_Vault" }
            desktopShortcuts = desktopNames.map { resolveShortcutURL(for: $0) }
            UserDefaults.standard.set(desktopNames, forKey: "darkos_desktop_shortcuts")
        }
        if let dockNames = UserDefaults.standard.stringArray(forKey: "darkos_dock_shortcuts") {
            dockShortcuts = dockNames.map { resolveShortcutURL(for: $0) }
        }
        if var startNames = UserDefaults.standard.stringArray(forKey: "darkos_start_shortcuts") {
            startNames.removeAll { $0 == "File_Safe" || $0 == "File_Vault" }
            startMenuShortcuts = startNames.map { resolveShortcutURL(for: $0) }
            UserDefaults.standard.set(startNames, forKey: "darkos_start_shortcuts")
        }
    }

    func savePinnableStates() {
        UserDefaults.standard.set(desktopShortcuts.map { $0.lastPathComponent }, forKey: "darkos_desktop_shortcuts")
        UserDefaults.standard.set(dockShortcuts.map { $0.lastPathComponent }, forKey: "darkos_dock_shortcuts")
        UserDefaults.standard.set(startMenuShortcuts.map { $0.lastPathComponent }, forKey: "darkos_start_shortcuts")
    }
    
    private func resolveShortcutURL(for name: String) -> URL {
        let cleanName = name == "File_Safe" ? "File_Vault" : name
        if ["Browser", "File_Vault", "Module_Manager", "File_Explorer", "Task_Manager"].contains(cleanName) {
            return rootDirectory.appendingPathComponent(cleanName).resolvingSymlinksInPath()
        }
        return modulesDirectory.appendingPathComponent(cleanName).resolvingSymlinksInPath()
    }

    func toggleDesktopShortcut(url: URL) {
        if url.lastPathComponent == "File_Safe" || url.lastPathComponent == "File_Vault" { return }
        if desktopShortcuts.contains(url) {
            desktopShortcuts.removeAll { $0 == url }
        } else {
            desktopShortcuts.append(url)
        }
        savePinnableStates()
    }

    func toggleDockShortcut(url: URL) {
        if dockShortcuts.contains(url) {
            dockShortcuts.removeAll { $0 == url }
        } else {
            dockShortcuts.append(url)
        }
        savePinnableStates()
    }

    func toggleStartMenuShortcut(url: URL) {
        if url.lastPathComponent == "File_Safe" || url.lastPathComponent == "File_Vault" { return }
        if startMenuShortcuts.contains(url) {
            startMenuShortcuts.removeAll { $0 == url }
        } else {
            startMenuShortcuts.append(url)
        }
        savePinnableStates()
        refreshInstalledModules()
    }

    func removeDesktopShortcut(url: URL) {
        desktopShortcuts.removeAll { $0 == url }
        savePinnableStates()
    }
    
    func createFolder(named folderName: String) {
        let newFolderURL = currentDirectory.appendingPathComponent(folderName)
        try? FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        objectWillChange.send()
    }
    
    func isProtectedModulesFolder(_ url: URL) -> Bool {
        if url.lastPathComponent == "Modules" {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                return isDir.boolValue
            }
            return true
        }
        return false
    }
    
    func renameFile(fileURL: URL, to newName: String) {
        if isProtectedModulesFolder(fileURL) { return }
        let ext = fileURL.pathExtension
        var fullNewName = newName
        if !ext.isEmpty && !newName.lowercased().hasSuffix(".\(ext.lowercased())") {
            fullNewName = "\(newName).\(ext)"
        }
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(fullNewName)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledModules()
        objectWillChange.send()
    }
    
    func moveToTrash(fileURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var destinationURL = trashDirectory.appendingPathComponent(fileURL.lastPathComponent)
        
        var counter = 1
        while FileManager.default.fileExists(atPath: destinationURL.path) {
            let newName = ext.isEmpty ? "\(fileName) (\(counter))" : "\(fileName) (\(counter)).\(ext)"
            destinationURL = trashDirectory.appendingPathComponent(newName)
            counter += 1
        }
        
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledModules()
        objectWillChange.send()
    }
    
    func restoreFromTrash(fileURL: URL) {
        let destinationURL = rootDirectory.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledModules()
        objectWillChange.send()
    }
    
    func permanentlyDelete(fileURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        try? FileManager.default.removeItem(at: fileURL)
        objectWillChange.send()
    }
    
    func copyFile(fileURL: URL, to directoryURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        let destinationURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.copyItem(at: fileURL, to: destinationURL)
        refreshInstalledModules()
        objectWillChange.send()
    }
    
    func moveFile(fileURL: URL, to directoryURL: URL) {
        if isProtectedModulesFolder(fileURL) { return }
        let destinationURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledModules()
        objectWillChange.send()
    }
    
    func downloadApp(from urlString: String, saveAs fileName: String, completion: @escaping (Bool) -> Void) {
        let cleanName = fileName.hasSuffix(".html") ? fileName : "\(fileName).html"
        var cleanURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURLString.lowercased().hasPrefix("http://") && !cleanURLString.lowercased().hasPrefix("https://") {
            cleanURLString = "https://" + cleanURLString
        }
        
        guard let url = URL(string: cleanURLString) else { completion(false); return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let htmlContent = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            let destinationURL = self.modulesDirectory.appendingPathComponent(cleanName)
            do {
                try htmlContent.write(to: destinationURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { self.refreshInstalledModules(); completion(true) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func importLocalFile(from securityScopedURL: URL) {
        guard securityScopedURL.startAccessingSecurityScopedResource() else { return }
        defer { securityScopedURL.stopAccessingSecurityScopedResource() }
        
        let fileName = securityScopedURL.lastPathComponent
        let targetFolder = (["html", "js"].contains(securityScopedURL.pathExtension.lowercased())) ? modulesDirectory : currentDirectory
        let destinationURL = targetFolder.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: securityScopedURL, to: destinationURL)
            refreshInstalledModules()
        } catch {
            print("Failed to import local file: \(error.localizedDescription)")
        }
    }
    
    func navigateIntoFolder(_ folderURL: URL) {
        backStack.append(currentDirectory)
        forwardStack.removeAll()
        currentDirectory = folderURL
    }
    
    func navigateBack() {
        guard !backStack.isEmpty else { return }
        let previous = backStack.removeLast()
        forwardStack.append(currentDirectory)
        currentDirectory = previous
    }
    
    func navigateForward() {
        guard !forwardStack.isEmpty else { return }
        let next = forwardStack.removeLast()
        backStack.append(currentDirectory)
        currentDirectory = next
    }
    
    func getUsedDiskSpace() -> Int64 {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return folderSize(at: documentsURL)
    }
    
    private func folderSize(at url: URL) -> Int64 {
        var size: Int64 = 0
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) else { return 0 }
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }
    
    func getUsedDiskSpaceDisplay() -> String {
        let bytes = getUsedDiskSpace()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
