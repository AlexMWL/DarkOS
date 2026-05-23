import Foundation
import Combine

class FileSystemManager: ObservableObject {
    static let shared = FileSystemManager()
    
    let rootDirectory: URL
    let trashDirectory: URL
    let appsDirectory: URL // Dedicated sub-cluster for launchable apps
    
    @Published var currentDirectory: URL
    @Published var installedApps: [URL] = []
    
    @Published var desktopShortcuts: [URL] = []
    @Published var dockShortcuts: [URL] = []
    @Published var startMenuShortcuts: [URL] = []
    
    @Published var backStack: [URL] = []
    @Published var forwardStack: [URL] = []
    
    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.rootDirectory = paths[0].appendingPathComponent("C_Drive").resolvingSymlinksInPath()
        self.trashDirectory = paths[0].appendingPathComponent(".Trash").resolvingSymlinksInPath()
        self.appsDirectory = rootDirectory.appendingPathComponent("Apps").resolvingSymlinksInPath()
        self.currentDirectory = rootDirectory
        
        createSystemDirectories()
        loadPinnableStates()
        refreshInstalledApps()
    }
    
    private func createSystemDirectories() {
        try? FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: trashDirectory, withIntermediateDirectories: true, attributes: nil)
        try? FileManager.default.createDirectory(at: appsDirectory, withIntermediateDirectories: true, attributes: nil)
        
        let browserVirtualURL = rootDirectory.appendingPathComponent("Browser")
        if !FileManager.default.fileExists(atPath: browserVirtualURL.path) {
            try? "DARKOS_NATIVE_BROWSER_BINARY".write(to: browserVirtualURL, atomically: true, encoding: .utf8)
        }
    }
    
    func listCurrentDirectoryContents() -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
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
    
    func listTrashContents() -> [URL] {
        return (try? FileManager.default.contentsOfDirectory(at: trashDirectory, includingPropertiesForKeys: nil)) ?? []
    }
    
    func refreshInstalledApps() {
        let rootContents = (try? FileManager.default.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: nil)) ?? []
        let appContents = (try? FileManager.default.contentsOfDirectory(at: appsDirectory, includingPropertiesForKeys: nil)) ?? []
        
        let combinedContents = rootContents + appContents
        var apps = combinedContents.filter { $0.pathExtension == "html" || $0.pathExtension == "js" || $0.lastPathComponent == "Browser" }
        
        let safeVirtualURL = rootDirectory.appendingPathComponent("File_Safe")
        if !apps.contains(safeVirtualURL) {
            apps.append(safeVirtualURL)
        }
        
        for shortcut in startMenuShortcuts {
            if !apps.contains(shortcut) {
                apps.append(shortcut)
            }
        }
        
        self.installedApps = apps
    }
    
    func loadPinnableStates() {
        if let desktopNames = UserDefaults.standard.stringArray(forKey: "darkos_desktop_shortcuts") {
            desktopShortcuts = desktopNames.map { resolveShortcutURL(for: $0) }
        }
        if let dockNames = UserDefaults.standard.stringArray(forKey: "darkos_dock_shortcuts") {
            dockShortcuts = dockNames.map { resolveShortcutURL(for: $0) }
        }
        if let startNames = UserDefaults.standard.stringArray(forKey: "darkos_start_shortcuts") {
            startMenuShortcuts = startNames.map { resolveShortcutURL(for: $0) }
        }
    }

    func savePinnableStates() {
        UserDefaults.standard.set(desktopShortcuts.map { $0.lastPathComponent }, forKey: "darkos_desktop_shortcuts")
        UserDefaults.standard.set(dockShortcuts.map { $0.lastPathComponent }, forKey: "darkos_dock_shortcuts")
        UserDefaults.standard.set(startMenuShortcuts.map { $0.lastPathComponent }, forKey: "darkos_start_shortcuts")
    }
    
    private func resolveShortcutURL(for name: String) -> URL {
        if ["Browser", "File_Safe", "File_Manager", "Task_Manager"].contains(name) {
            return rootDirectory.appendingPathComponent(name).resolvingSymlinksInPath()
        }
        return appsDirectory.appendingPathComponent(name).resolvingSymlinksInPath()
    }

    func toggleDesktopShortcut(url: URL) {
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
        if startMenuShortcuts.contains(url) {
            startMenuShortcuts.removeAll { $0 == url }
        } else {
            startMenuShortcuts.append(url)
        }
        savePinnableStates()
        refreshInstalledApps()
    }

    func addDockShortcut(url: URL) {
        if !dockShortcuts.contains(url) {
            dockShortcuts.append(url)
            savePinnableStates()
        }
    }

    func removeDesktopShortcut(url: URL) {
        desktopShortcuts.removeAll { $0 == url }
        savePinnableStates()
    }

    func removeDockShortcut(url: URL) {
        dockShortcuts.removeAll { $0 == url }
        savePinnableStates()
    }
    
    func createFolder(named folderName: String) {
        let newFolderURL = currentDirectory.appendingPathComponent(folderName)
        try? FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
        objectWillChange.send()
    }
    
    func renameFile(fileURL: URL, to newName: String) {
        let ext = fileURL.pathExtension
        var fullNewName = newName
        if !ext.isEmpty && !newName.lowercased().hasSuffix(".\(ext.lowercased())") {
            fullNewName = "\(newName).\(ext)"
        }
        let destinationURL = fileURL.deletingLastPathComponent().appendingPathComponent(fullNewName)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledApps()
        objectWillChange.send()
    }
    
    func moveToTrash(fileURL: URL) {
        let destinationURL = trashDirectory.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledApps()
        objectWillChange.send()
    }
    
    func restoreFromTrash(fileURL: URL) {
        let destinationURL = rootDirectory.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledApps()
        objectWillChange.send()
    }
    
    func permanentlyDelete(fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
        objectWillChange.send()
    }
    
    func copyFile(fileURL: URL, to directoryURL: URL) {
        let destinationURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.copyItem(at: fileURL, to: destinationURL)
        refreshInstalledApps()
        objectWillChange.send()
    }
    
    func moveFile(fileURL: URL, to directoryURL: URL) {
        let destinationURL = directoryURL.appendingPathComponent(fileURL.lastPathComponent)
        try? FileManager.default.removeItem(at: destinationURL)
        try? FileManager.default.moveItem(at: fileURL, to: destinationURL)
        refreshInstalledApps()
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
            let destinationURL = self.appsDirectory.appendingPathComponent(cleanName)
            do {
                try htmlContent.write(to: destinationURL, atomically: true, encoding: .utf8)
                DispatchQueue.main.async { self.refreshInstalledApps(); completion(true) }
            } catch {
                DispatchQueue.main.async { completion(false) }
            }
        }.resume()
    }

    func importLocalFile(from securityScopedURL: URL) {
        guard securityScopedURL.startAccessingSecurityScopedResource() else { return }
        defer { securityScopedURL.stopAccessingSecurityScopedResource() }
        
        let fileName = securityScopedURL.lastPathComponent
        let targetFolder = (["html", "js"].contains(securityScopedURL.pathExtension.lowercased())) ? appsDirectory : currentDirectory
        let destinationURL = targetFolder.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: securityScopedURL, to: destinationURL)
            refreshInstalledApps()
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
}
