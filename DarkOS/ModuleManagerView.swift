// DarkOS/ModuleManagerView.swift

import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ModuleManagerView: View {
    @ObservedObject var fs = FileSystemManager.shared
    @ObservedObject var pm = ProcessManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @Binding var isPresented: Bool
    
    @State private var currentDirectory: URL = FileSystemManager.shared.modulesDirectory
    @State private var localBackStack: [URL] = []
    
    @State private var webURLString = ""
    @State private var downloadName = ""
    @State private var showLocalFilePicker = false
    @State private var installAlertMessage = ""
    @State private var showInstallAlert = false
    
    @State private var showNewFolderAlert = false
    @State private var folderNameInput = ""
    @State private var viewTrashBinMode = false
    
    @State private var showRenameAlert = false
    @State private var renameTargetURL: URL? = nil
    @State private var renameInputText = ""
    
    @State private var fileClipboard: URL? = nil
    @State private var clipboardIsCutOperation = false
    
    @State private var selectedFile: URL? = nil
    @State private var sourceViewFile: URL? = nil
    
    @State private var showHTMLChoiceAlert = false
    @State private var htmlAlertFile: URL? = nil
    
    private var currentListItems: [URL] {
        if viewTrashBinMode {
            return fs.listTrashContents().filter { ["html", "js"].contains($0.pathExtension.lowercased()) }
        } else {
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
    }
    
    var body: some View {
        ZStack {
            theme.bgSolid.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                navigationMatrix
                if !viewTrashBinMode { compilerWorkspace }
                fileListView
            }
        }
        .alert("Create Sub-Directory", isPresented: $showNewFolderAlert) {
            TextField("Folder Identity Name", text: $folderNameInput).autocapitalization(.none)
            Button("Allocate") {
                if !folderNameInput.isEmpty {
                    let newFolderURL = currentDirectory.appendingPathComponent(folderNameInput)
                    try? FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
                    fs.objectWillChange.send()
                }
                folderNameInput = ""
            }
            Button("Cancel", role: .cancel) { folderNameInput = "" }
        }
        .alert("Rename Drive Asset", isPresented: $showRenameAlert) {
            TextField("New Label", text: $renameInputText).autocapitalization(.none)
            Button("Modify") { if let target = renameTargetURL, !renameInputText.isEmpty { fs.renameFile(fileURL: target, to: renameInputText) }; renameTargetURL = nil; renameInputText = "" }
            Button("Cancel", role: .cancel) { renameTargetURL = nil; renameInputText = "" }
        }
        .sheet(item: $selectedFile) { url in InternalFileViewer(fileURL: url) }
        .sheet(item: $sourceViewFile) { url in InternalFileViewer(fileURL: url, forceTextView: true) }
        .alert(installAlertMessage, isPresented: $showInstallAlert) { Button("OK", role: .cancel) { } }
        .alert("HTML Detected", isPresented: $showHTMLChoiceAlert, presenting: htmlAlertFile) { file in
            Button("Execute As Module") { pm.launchProcess(from: file); isPresented = false; htmlAlertFile = nil }
            Button("View Source Code") { let targetFile = file; htmlAlertFile = nil; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.sourceViewFile = targetFile } }
            Button("Cancel", role: .cancel) { htmlAlertFile = nil }
        } message: { file in Text("Choose Run Option For\n\(file.lastPathComponent.uppercased())") }
        .fileImporter(isPresented: $showLocalFilePicker, allowedContentTypes: [.html, .plainText, .data], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first { guard selectedURL.startAccessingSecurityScopedResource() else { return }; fs.importLocalFile(from: selectedURL); selectedURL.stopAccessingSecurityScopedResource() }
            case .failure(let error): print("Deployment Error: \(error.localizedDescription)")
            }
        }
    }
    
    private var headerBar: some View {
            HStack {
                Image(systemName: "folder.fill").foregroundColor(.yellow)
                Text(viewTrashBinMode ? "Recycle Bin subsystem" : "Module Manager // Local & Remote Compilation")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(theme.text)
                Spacer()
            }
            .padding()
            .background(theme.panel)
        }
    
    private var navigationMatrix: some View {
        HStack(spacing: 12) {
            if !viewTrashBinMode {
                HStack(spacing: 6) {
                    Button(action: {
                        if !localBackStack.isEmpty {
                            currentDirectory = localBackStack.removeLast()
                        }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.caption2)
                            .foregroundColor(localBackStack.isEmpty ? .gray : theme.accent)
                    }
                    .disabled(localBackStack.isEmpty)
                    
                    Button(action: { showNewFolderAlert = true }) { Image(systemName: "folder.badge.plus.fill").font(.system(size: 14.5)).foregroundColor(.green) }
                }
            }
            HStack {
                Image(systemName: "desktopcomputer").font(.caption2).foregroundColor(.gray)
                Text(getCurrentPathDisplay()).font(.system(size: 9.5, design: .monospaced)).foregroundColor(theme.text.opacity(0.8))
                Spacer()
            }
            .padding(8).background(theme.panelDeep).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 1))
            
            if !viewTrashBinMode && fileClipboard != nil {
                Button(action: { executePasteAction() }) { Text("PASTE").font(.system(size: 9.5, weight: .black, design: .rounded)).foregroundColor(.yellow) }
            }
            
            Button(action: { viewTrashBinMode.toggle() }) {
                Text(viewTrashBinMode ? "Computer Drives" : "Recycle Bin").font(.system(size: 8.5, weight: .bold, design: .rounded)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 6).background(viewTrashBinMode ? Color.green.opacity(0.6) : Color.orange.opacity(0.6)).cornerRadius(4)
            }
        }
        .padding().background(theme.panel)
    }
    
    private var compilerWorkspace: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("URL Compiler").font(.system(size: 9.5, weight: .bold, design: .rounded)).foregroundColor(theme.accent)
            HStack(spacing: 8) {
                TextField("URL Source Link...", text: $webURLString).textFieldStyle(.plain).font(.system(size: 10.5, design: .monospaced)).padding(8).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4)
                TextField("App Label", text: $downloadName).textFieldStyle(.plain).font(.system(size: 10.5, design: .monospaced)).padding(8).frame(width: 100).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4)
                Button(action: {
                    fs.downloadApp(from: webURLString, saveAs: downloadName) { success in
                        installAlertMessage = success ? "MANIFEST MODULE COMPILED SUCCESSFULLY." : "PACKET DISCOVERY INTERRUPT EXCEPTION."
                        showInstallAlert = true; if success { webURLString = ""; downloadName = "" }
                    }
                }) { Text("Compile").font(.system(size: 9.5, weight: .black, design: .rounded)).padding(.vertical, 8).padding(.horizontal, 16).background(theme.accent).foregroundColor(.white).cornerRadius(4) }
            }
            Button(action: { showLocalFilePicker = true }) {
                Label("Import External Module (.html / .js)", systemImage: "square.and.arrow.down.fill").font(.system(size: 9.5, weight: .bold, design: .rounded)).foregroundColor(theme.text).frame(maxWidth: .infinity).padding(10).background(theme.panel).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 1))
            }
        }
        .padding().background(theme.panel)
    }
    
    private var fileListView: some View {
        List {
            if currentListItems.isEmpty {
                Text("No data structures mapped inside this segment cluster.").font(.system(size: 10.5, design: .rounded)).foregroundColor(.gray).listRowBackground(theme.bgSolid)
            } else {
                ForEach(currentListItems, id: \.self) { file in
                    HStack {
                        Image(systemName: file.isDarkOSDirectory ? "folder.fill" : fileIcon(for: file)).foregroundColor(viewTrashBinMode ? .orange : (file.isDarkOSDirectory ? .yellow : theme.accent))
                        Text(file.lastPathComponent.uppercased()).font(.system(size: 10.5, weight: .medium, design: .monospaced)).foregroundColor(theme.text)
                        Spacer()
                        Text(file.isDarkOSDirectory ? "File Folder" : "\(file.pathExtension.uppercased()) File").font(.system(size: 8.5, design: .rounded)).foregroundColor(theme.textMuted)
                    }
                    .padding(.vertical, 4).listRowBackground(theme.bgSolid).contentShape(Rectangle())
                    .onTapGesture {
                        if viewTrashBinMode { return }
                        if file.isDarkOSDirectory {
                            localBackStack.append(currentDirectory)
                            currentDirectory = file
                        } else {
                            routeFileSelection(file)
                        }
                    }
                    .contextMenu { FileContextMenu(file: file, isDir: file.isDarkOSDirectory, viewTrashBinMode: viewTrashBinMode, renameTargetURL: $renameTargetURL, renameInputText: $renameInputText, showRenameAlert: $showRenameAlert, fileClipboard: $fileClipboard, clipboardIsCutOperation: $clipboardIsCutOperation) }
                }
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden).background(theme.bgSolid)
    }
    
    private func getCurrentPathDisplay() -> String {
        if viewTrashBinMode { return "ROOT://VIRTUAL_VOLUMES/.TRASH" }
        let subPath = currentDirectory.path.replacingOccurrences(of: fs.rootDirectory.path, with: "")
        return "C:\\DarkOS\\Modules" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    
    private func fileIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic"].contains(ext) { return "photo.fill" }
        if ["mp4", "mov", "m4v"].contains(ext) { return "video.fill" }
        if ["html", "js"].contains(ext) { return "cpu" }
        return "doc.plaintext.fill"
    }
    
    private func routeFileSelection(_ file: URL) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let ext = file.pathExtension.lowercased()
        if ext == "html" || ext == "js" { htmlAlertFile = file; showHTMLChoiceAlert = true } else { selectedFile = file }
    }
    
    private func executePasteAction() {
        guard let source = fileClipboard else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if clipboardIsCutOperation { fs.moveFile(fileURL: source, to: currentDirectory); fileClipboard = nil } else { fs.copyFile(fileURL: source, to: currentDirectory) }
    }
}

struct FileContextMenu: View {
    let file: URL
    let isDir: Bool
    let viewTrashBinMode: Bool
    @ObservedObject var fs = FileSystemManager.shared
    @Binding var renameTargetURL: URL?
    @Binding var renameInputText: String
    @Binding var showRenameAlert: Bool
    @Binding var fileClipboard: URL?
    @Binding var clipboardIsCutOperation: Bool
    
    var body: some View {
        if viewTrashBinMode {
            Button(action: { fs.restoreFromTrash(fileURL: file) }) { Label("Restore File to Drive", systemImage: "arrow.uturn.backward.circle.fill") }
            Button(role: .destructive, action: { fs.permanentlyDelete(fileURL: file) }) { Label("Purge", systemImage: "trash.slash.fill") }
        } else {
            Button(action: { renameTargetURL = file; renameInputText = file.deletingPathExtension().lastPathComponent; showRenameAlert = true }) { Label("Rename", systemImage: "pencil") }
            Button(action: { fileClipboard = file; clipboardIsCutOperation = false }) { Label("Copy", systemImage: "doc.on.doc.fill") }
            Button(action: { fileClipboard = file; clipboardIsCutOperation = true }) { Label("Cut", systemImage: "scissors") }
            Button(action: { fs.moveToTrash(fileURL: file) }) { Label("Move to Trash", systemImage: "trash.fill") }
            if !isDir {
                Button(action: { _ = FileVaultManager.importFromInternalPath(sourceURL: file) }) { Label("Move to File Vault", systemImage: "lock.doc.fill") }
                if ["html", "js"].contains(file.pathExtension.lowercased()) {
                    Divider()
                    Button(action: { fs.toggleDesktopShortcut(url: file) }) { Label(fs.desktopShortcuts.contains(file) ? "Unpin from Desktop" : "Pin to Desktop", systemImage: fs.desktopShortcuts.contains(file) ? "desktopcomputer" : "plus.rectangle.on.folder") }
                    Button(action: { fs.toggleDockShortcut(url: file) }) { Label(fs.dockShortcuts.contains(file) ? "Unpin from Dock" : "Pin to Dock", systemImage: fs.dockShortcuts.contains(file) ? "pin.fill" : "pin") }
                    Button(action: { fs.toggleStartMenuShortcut(url: file) }) { Label(fs.startMenuShortcuts.contains(file) ? "Unpin from Start Menu" : "Pin to Start Menu", systemImage: fs.startMenuShortcuts.contains(file) ? "command.circle.fill" : "command") }
                }
            }
        }
    }
}
