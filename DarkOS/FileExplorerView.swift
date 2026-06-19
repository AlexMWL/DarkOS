// DarkOS/FileExplorerView.swift

import SwiftUI
import AVKit
import UniformTypeIdentifiers
import Combine

struct FileExplorerView: View {
    @ObservedObject var fs = FileSystemManager.shared
    @ObservedObject var pm = ProcessManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var viewMode: ExplorerViewMode = .grid
    @State private var searchQuery: String = ""
    @State private var selectedFile: URL? = nil
    @State private var showSidebar = true
    @State private var showPreviewPanel = true
    @State private var previewFile: URL? = nil
    
    // File Operation States
    @State private var showNewFolderAlert = false
    @State private var folderNameInput = ""
    @State private var showRenameAlert = false
    @State private var renameTargetURL: URL? = nil
    @State private var renameInputText = ""
    @State private var showLocalFilePicker = false
    
    // Clipboard
    @State private var fileClipboard: URL? = nil
    @State private var clipboardIsCutOperation = false
    
    enum ExplorerViewMode {
        case grid, list
    }
    
    var filteredItems: [URL] {
        let items = fs.listCurrentDirectoryContents()
        let isTrash = fs.currentDirectory == fs.trashDirectory
        let explorerItems = isTrash ? items.filter { !["html", "js"].contains($0.pathExtension.lowercased()) } : items
        
        if searchQuery.isEmpty {
            return explorerItems
        } else {
            return explorerItems.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 500
            
            HStack(spacing: 0) {
                // Sidebar Navigation Panel (Hidden on narrow viewports)
                if showSidebar && !isCompact {
                    sidebarPanel
                        .frame(width: 130)
                        .transition(.move(edge: .leading))
                }
                
                // Main Directory Contents Area
                VStack(spacing: 0) {
                    topToolbar(isCompact: isCompact)
                    searchBarView
                    
                    ZStack {
                        theme.bgSolid.ignoresSafeArea()
                        
                        if filteredItems.isEmpty {
                            emptyStateView
                        } else {
                            mainContentView(isCompact: isCompact)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Collapsible Detail/Preview Sidebar (Hidden on narrow viewports)
                if showPreviewPanel && !isCompact, let file = selectedFile {
                    Divider().background(theme.border)
                    DetailPreviewPanel(fileURL: file, theme: theme) {
                        selectedFile = nil
                        fs.objectWillChange.send()
                    }
                    .frame(width: 160)
                    .transition(.move(edge: .trailing))
                }
            }
            .sheet(item: $previewFile) { url in
                InternalFileViewer(fileURL: url)
            }
        }
        .background(theme.bgSolid)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showSidebar)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPreviewPanel)
        .animation(.easeInOut(duration: 0.2), value: selectedFile)
        .alert("Create Sub-Directory", isPresented: $showNewFolderAlert) {
            TextField("Folder Identity Name", text: $folderNameInput).autocapitalization(.none)
            Button("Allocate") { if !folderNameInput.isEmpty { fs.createFolder(named: folderNameInput) }; folderNameInput = "" }
            Button("Cancel", role: .cancel) { folderNameInput = "" }
        }
        .alert("Rename Drive Asset", isPresented: $showRenameAlert) {
            TextField("New Label", text: $renameInputText).autocapitalization(.none)
            Button("Modify") { if let target = renameTargetURL, !renameInputText.isEmpty { fs.renameFile(fileURL: target, to: renameInputText) }; renameTargetURL = nil; renameInputText = "" }
            Button("Cancel", role: .cancel) { renameTargetURL = nil; renameInputText = "" }
        }
        .fileImporter(isPresented: $showLocalFilePicker, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    guard selectedURL.startAccessingSecurityScopedResource() else { return }
                    fs.importLocalFile(from: selectedURL)
                    selectedURL.stopAccessingSecurityScopedResource()
                    selectedFile = nil
                }
            case .failure(let error):
                print("Import Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sidebar view
    private var sidebarPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QUICK ACCESS")
                .font(.system(size: 7.5, weight: .black, design: .rounded))
                .foregroundColor(theme.accent)
                .padding(.horizontal, 12)
                .padding(.top, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                sidebarButton(title: "Root Drive C:", icon: "desktopcomputer") {
                    fs.currentDirectory = fs.rootDirectory
                    selectedFile = nil
                }
                
                sidebarButton(title: "Modules Sector", icon: "cpu") {
                    fs.currentDirectory = fs.modulesDirectory
                    selectedFile = nil
                }
                
                sidebarButton(title: "File Vault", icon: "lock.shield.fill") {
                    let safeURL = fs.rootDirectory.appendingPathComponent("File_Vault")
                    pm.launchProcess(from: safeURL)
                }
                
                sidebarButton(title: "Recycle Bin", icon: "trash.fill") {
                    fs.currentDirectory = fs.trashDirectory
                    selectedFile = nil
                }
            }
            
            Spacer()
            
            // Storage Health/Capacity Indicators
            VStack(alignment: .leading, spacing: 6) {
                Text("DISK STATUS")
                    .font(.system(size: 7.5, weight: .black, design: .rounded))
                    .foregroundColor(theme.textMuted)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.panelDeep)
                            .frame(height: 5)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.accent)
                            .frame(width: geo.size.width * 0.42, height: 5)
                            .shadow(color: theme.glow, radius: 2)
                    }
                }
                .frame(height: 5)
                
                Text("42.8 MB / 100.0 MB")
                    .font(.system(size: 6.5, design: .monospaced))
                    .foregroundColor(theme.text)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
        .background(theme.panel)
        .border(theme.border, width: 0.5)
    }
    
    private func sidebarButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 9.5))
                    .foregroundColor(theme.accent)
                    .frame(width: 14)
                
                Text(title)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(theme.text)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(theme.panelDeep.opacity(0.4))
            .cornerRadius(4)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Toolbar View
    private func topToolbar(isCompact: Bool) -> some View {
        HStack(spacing: 8) {
            // Navigation stack actions
            HStack(spacing: 4) {
                Button(action: { fs.navigateBack(); selectedFile = nil }) {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundColor(fs.backStack.isEmpty ? .gray : theme.accent)
                }
                .disabled(fs.backStack.isEmpty)
                
                Button(action: { fs.navigateForward(); selectedFile = nil }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(fs.forwardStack.isEmpty ? .gray : theme.accent)
                }
                .disabled(fs.forwardStack.isEmpty)
                
                // Sidebar Menu for Compact layout
                if isCompact {
                    Menu {
                        Button("Root Drive C:") { fs.currentDirectory = fs.rootDirectory; selectedFile = nil }
                        Button("Modules Sector") { fs.currentDirectory = fs.modulesDirectory; selectedFile = nil }
                        Button("File Vault") {
                            let safeURL = fs.rootDirectory.appendingPathComponent("File_Vault")
                            pm.launchProcess(from: safeURL)
                        }
                        Button("Recycle Bin") { fs.currentDirectory = fs.trashDirectory; selectedFile = nil }
                    } label: {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 9.5))
                            .foregroundColor(theme.accent)
                            .padding(6)
                            .background(theme.panelDeep)
                            .cornerRadius(4)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 0.5))
                    }
                }
            }
            
            // Current Location Indicator
            HStack {
                Image(systemName: "folder")
                    .font(.caption2)
                    .foregroundColor(theme.accent)
                Text(getCurrentPathDisplay())
                    .font(.system(size: 8.5, design: .monospaced))
                    .foregroundColor(theme.text)
                    .lineLimit(1)
                Spacer()
            }
            .padding(6)
            .background(theme.panelDeep)
            .cornerRadius(4)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 1))
            
            // Clipboard Actions
            if fileClipboard != nil {
                Button(action: executePasteAction) {
                    Text("PASTE")
                        .font(.system(size: 7.5, weight: .black, design: .rounded))
                        .foregroundColor(.yellow)
                }
            }
            
            // Panel view controls
            HStack(spacing: 6) {
                if !isCompact {
                    Button(action: { showSidebar.toggle() }) {
                        Image(systemName: showSidebar ? "sidebar.left" : "sidebar.left.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(theme.text)
                    }
                    
                    Button(action: { showPreviewPanel.toggle() }) {
                        Image(systemName: showPreviewPanel ? "sidebar.right" : "sidebar.right.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(theme.text)
                    }
                }
                
                Button(action: { viewMode = (viewMode == .grid ? .list : .grid) }) {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2.fill")
                        .font(.system(size: 9.5))
                        .foregroundColor(theme.text)
                }
            }
            .padding(6)
            .background(theme.panel)
            .cornerRadius(4)
        }
        .padding(8)
        .background(theme.panel)
    }
    
    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 9.5))
                .foregroundColor(theme.textMuted)
            
            TextField("Search assets...", text: $searchQuery)
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(theme.text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 9.5))
                        .foregroundColor(.gray)
                }
            }
            
            // Media creation & importing options / Empty trash bin
            HStack(spacing: 8) {
                if fs.currentDirectory == fs.trashDirectory {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        let items = fs.listTrashContents()
                        let explorerItems = items.filter { !["html", "js"].contains($0.pathExtension.lowercased()) }
                        for file in explorerItems {
                            fs.permanentlyDelete(fileURL: file)
                        }
                        selectedFile = nil
                    }) {
                        Label("Empty Bin", systemImage: "trash.slash.fill")
                            .font(.system(size: 7.5, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: { showNewFolderAlert = true }) {
                        Label("Folder", systemImage: "folder.badge.plus")
                            .font(.system(size: 7.5, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    
                    Button(action: { showLocalFilePicker = true }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .font(.system(size: 7.5, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .padding(.leading, 8)
        }
        .padding(8)
        .background(theme.panelDeep.opacity(0.5))
        .border(theme.border, width: 0.5)
    }
    
    // MARK: - File Content Grid & List Views
    private func mainContentView(isCompact: Bool) -> some View {
        ScrollView {
            if viewMode == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 85))], spacing: 14) {
                    ForEach(filteredItems, id: \.self) { file in
                        gridItemView(for: file, isCompact: isCompact)
                    }
                }
                .padding(12)
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(filteredItems, id: \.self) { file in
                        listItemView(for: file, isCompact: isCompact)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    private func gridItemView(for file: URL, isCompact: Bool) -> some View {
        let isSelected = selectedFile == file
        return VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? theme.accent.opacity(0.25) : theme.panel)
                    .frame(width: 46, height: 46)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? theme.accent : theme.border, lineWidth: 1))
                
                Image(systemName: file.isDarkOSDirectory ? "folder.fill" : fileIcon(for: file))
                    .font(.caption2)
                    .foregroundColor(file.isDarkOSDirectory ? .yellow : theme.accent)
            }
            
            Text(file.lastPathComponent.uppercased())
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
                .lineLimit(1)
                .frame(width: 65)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let isTrash = fs.currentDirectory == fs.trashDirectory
            if isTrash { return }
            if file.isDarkOSDirectory {
                fs.navigateIntoFolder(file)
                selectedFile = nil
            } else {
                if isCompact {
                    previewFile = file
                } else {
                    selectedFile = file
                }
            }
        }
        .contextMenu { FileExplorerContextMenu(file: file, isDir: file.isDarkOSDirectory, isTrashMode: fs.currentDirectory == fs.trashDirectory, renameTargetURL: $renameTargetURL, renameInputText: $renameInputText, showRenameAlert: $showRenameAlert, fileClipboard: $fileClipboard, clipboardIsCutOperation: $clipboardIsCutOperation, selectedFile: $selectedFile) }
    }
    
    private func listItemView(for file: URL, isCompact: Bool) -> some View {
        let isSelected = selectedFile == file
        return HStack(spacing: 12) {
            Image(systemName: file.isDarkOSDirectory ? "folder.fill" : fileIcon(for: file))
                .foregroundColor(file.isDarkOSDirectory ? .yellow : theme.accent)
                .frame(width: 16)
            
            Text(file.lastPathComponent.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
            
            Spacer()
            
            Text(file.isDarkOSDirectory ? "Folder" : file.pathExtension.uppercased())
                .font(.system(size: 6.5, design: .rounded))
                .foregroundColor(theme.textMuted)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(isSelected ? theme.accent.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            let isTrash = fs.currentDirectory == fs.trashDirectory
            if isTrash { return }
            if file.isDarkOSDirectory {
                fs.navigateIntoFolder(file)
                selectedFile = nil
            } else {
                if isCompact {
                    previewFile = file
                } else {
                    selectedFile = file
                }
            }
        }
        .contextMenu { FileExplorerContextMenu(file: file, isDir: file.isDarkOSDirectory, isTrashMode: fs.currentDirectory == fs.trashDirectory, renameTargetURL: $renameTargetURL, renameInputText: $renameInputText, showRenameAlert: $showRenameAlert, fileClipboard: $fileClipboard, clipboardIsCutOperation: $clipboardIsCutOperation, selectedFile: $selectedFile) }
    }
    
    // MARK: - Empty States
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.questionmark")
                .font(.caption2)
                .foregroundColor(theme.textMuted)
            Text("No Assets Discovered.")
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    private func getCurrentPathDisplay() -> String {
        if fs.currentDirectory == fs.trashDirectory { return "C:\\DARKOS\\EXPLORER\\RECYCLE_BIN" }
        let subPath = fs.currentDirectory.path.replacingOccurrences(of: fs.rootDirectory.path, with: "")
        return "C:\\DarkOS\\Explorer" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    
    private func fileIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(ext) { return "photo.fill" }
        if ["mp4", "mov", "m4v"].contains(ext) { return "video.fill" }
        if ext == "pdf" { return "doc.richtext.fill" }
        if ["html", "js", "css"].contains(ext) { return "doc.text.fill" }
        if ["mp3", "wav", "m4a"].contains(ext) { return "music.note" }
        return "doc.fill"
    }
    
    private func executePasteAction() {
        guard let source = fileClipboard else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if clipboardIsCutOperation {
            fs.moveFile(fileURL: source, to: fs.currentDirectory)
            fileClipboard = nil
        } else {
            fs.copyFile(fileURL: source, to: fs.currentDirectory)
        }
        selectedFile = nil
    }
}

// MARK: - Context Menu
struct FileExplorerContextMenu: View {
    let file: URL
    let isDir: Bool
    let isTrashMode: Bool
    @ObservedObject var fs = FileSystemManager.shared
    @Binding var renameTargetURL: URL?
    @Binding var renameInputText: String
    @Binding var showRenameAlert: Bool
    @Binding var fileClipboard: URL?
    @Binding var clipboardIsCutOperation: Bool
    @Binding var selectedFile: URL?
    
    var body: some View {
        if isTrashMode {
            Button(action: { fs.restoreFromTrash(fileURL: file) }) {
                Label("Restore Asset", systemImage: "arrow.uturn.backward.circle.fill")
            }
            Button(role: .destructive, action: { fs.permanentlyDelete(fileURL: file) }) {
                Label("Purge Binary", systemImage: "trash.slash.fill")
            }
        } else {
            let isModulesDir = fs.isProtectedModulesFolder(file)
            
            Button(action: { renameTargetURL = file; renameInputText = file.deletingPathExtension().lastPathComponent; showRenameAlert = true }) {
                Label("Rename Token", systemImage: "pencil")
            }
            .disabled(isModulesDir)
            
            Button(action: { fileClipboard = file; clipboardIsCutOperation = false }) {
                Label("Copy Asset", systemImage: "doc.on.doc")
            }
            .disabled(isModulesDir)
            
            Button(action: { fileClipboard = file; clipboardIsCutOperation = true }) {
                Label("Cut Asset", systemImage: "scissors")
            }
            .disabled(isModulesDir)
            
            Divider()
            
            Button(action: {
                if !isDir {
                    _ = FileVaultManager.importFromInternalPath(sourceURL: file)
                    selectedFile = nil
                }
            }) {
                Label("Move to File Vault", systemImage: "lock.doc.fill")
            }
            .disabled(isDir)
            
            Divider()
            
            Button(role: .destructive, action: {
                fs.moveToTrash(fileURL: file)
                selectedFile = nil
            }) {
                Label("Discard to Trash", systemImage: "trash")
            }
            .disabled(isModulesDir)
        }
    }
}

// MARK: - Sidebar Detail Preview Panel
struct DetailPreviewPanel: View {
    let fileURL: URL
    let theme: ThemeManager
    let dismissAction: () -> Void
    
    @State private var fileData: Data? = nil
    @State private var documentText: String? = nil
    @State private var isImage = false
    @State private var isVideo = false
    @State private var isPDF = false
    @State private var isAudio = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Header / Close button
            HStack {
                Text("METADATA PREVIEW")
                    .font(.system(size: 7.5, weight: .black, design: .rounded))
                    .foregroundColor(theme.accent)
                Spacer()
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundColor(theme.textMuted)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 12)
            
            // Preview Asset Render Layer
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.panelDeep)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.border, lineWidth: 0.5))
                
                if isImage, let data = fileData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(4)
                        .padding(4)
                } else if isVideo {
                    VideoPlayer(player: AVPlayer(url: fileURL))
                        .cornerRadius(4)
                        .padding(4)
                } else if isPDF {
                    PDFKitView(url: fileURL)
                        .cornerRadius(4)
                        .padding(4)
                } else if isAudio {
                    AudioPlayerView(url: fileURL)
                        .cornerRadius(4)
                        .padding(4)
                } else if let text = documentText {
                    ScrollView {
                        Text(text)
                            .font(.system(size: 5, design: .monospaced))
                            .foregroundColor(theme.text)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.plaintext")
                            .font(.caption2)
                            .foregroundColor(theme.textMuted)
                        Text(fileURL.pathExtension.uppercased())
                            .font(.system(size: 6.5, weight: .black, design: .rounded))
                            .foregroundColor(theme.textMuted)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Meta Info List
            VStack(alignment: .leading, spacing: 8) {
                metaRow(label: "LABEL", value: fileURL.lastPathComponent.uppercased())
                metaRow(label: "FORMAT", value: fileURL.pathExtension.uppercased())
                
                if let sizeBytes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
                    metaRow(label: "CAPACITY", value: formatBytes(sizeBytes))
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .background(theme.panel)
        .onAppear { loadFileMetadata() }
        .onChange(of: fileURL) { loadFileMetadata() }
    }
    
    private func metaRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textMuted)
            Text(value)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
                .lineLimit(2)
        }
    }
    
    private func loadFileMetadata() {
        let ext = fileURL.pathExtension.lowercased()
        isImage = ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(ext)
        isVideo = ["mp4", "mov", "m4v"].contains(ext)
        isPDF = ext == "pdf"
        isAudio = ["mp3", "wav", "m4a"].contains(ext)
        
        fileData = nil
        documentText = nil
        
        if isImage {
            fileData = try? Data(contentsOf: fileURL)
        } else if isVideo {
            // AVPlayer handles the video directly from URL
        } else if isPDF {
            // PDFKitView handles PDF from URL
        } else {
            // Load text document preview
            if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
                documentText = String(text.prefix(800)) // Limit preview length
            } else if let data = try? Data(contentsOf: fileURL) {
                documentText = "Binary document size: \(data.count) bytes."
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
