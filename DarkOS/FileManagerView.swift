import SwiftUI
import UniformTypeIdentifiers

struct FileManagerView: View {
    @ObservedObject var fs = FileSystemManager.shared
    @ObservedObject var pm = ProcessManager.shared
    
    @Binding var isPresented: Bool
    
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text(viewTrashBinMode ? "🗑️ RECYCLE_BIN_SUBSYSTEM" : "⚡ SYSTEM_DEVELOPMENT_KIT // MANIFEST")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(viewTrashBinMode ? .orange : .red)
                    Spacer()
                    Button("MINIMIZE") { isPresented = false }
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .border(Color.white.opacity(0.3), width: 1)
                }
                .padding().background(Color.white.opacity(0.03))
                
                HStack(spacing: 12) {
                    if !viewTrashBinMode {
                        HStack(spacing: 8) {
                            Button(action: { fs.navigateBack() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(fs.backStack.isEmpty ? .gray : .red)
                            }
                            .disabled(fs.backStack.isEmpty)
                            
                            Button(action: { fs.navigateForward() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(fs.forwardStack.isEmpty ? .gray : .red)
                            }
                            .disabled(fs.forwardStack.isEmpty)
                            
                            Button(action: { showNewFolderAlert = true }) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Text(getCurrentPathDisplay())
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !viewTrashBinMode && fileClipboard != nil {
                        Button(action: { executePasteAction() }) {
                            Text("PASTE").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.yellow)
                        }
                        .padding(.trailing, 8)
                    }
                    
                    Button(action: { viewTrashBinMode.toggle() }) {
                        Text(viewTrashBinMode ? "DRIVE VIEW" : "TRASH BIN")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(viewTrashBinMode ? .red : .orange)
                    }
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(Color.white.opacity(0.01))
                .border(Color.white.opacity(0.05), width: 1)
                
                if !viewTrashBinMode {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(">>> OVER-THE-AIR COMPILER INJECTION").font(.system(size: 10, design: .monospaced)).foregroundColor(.red.opacity(0.7))
                        
                        HStack {
                            TextField("REMOTELINK.HTML", text: $webURLString)
                                .font(.system(size: 11, design: .monospaced)).padding(10).background(Color.white.opacity(0.05)).foregroundColor(.white).autocapitalization(.none)
                            
                            TextField("ID", text: $downloadName)
                                .font(.system(size: 11, design: .monospaced)).padding(10).frame(width: 90).background(Color.white.opacity(0.05)).foregroundColor(.white).autocapitalization(.none)
                            
                            Button("COMPILE") {
                                fs.downloadApp(from: webURLString, saveAs: downloadName) { success in
                                    installAlertMessage = success ? "MANIFEST RECOMPILED SUCCESSFUL." : "PACKET TRANSMISSION ERROR."
                                    showInstallAlert = true
                                    if success { webURLString = ""; downloadName = "" }
                                }
                            }
                            .font(.system(size: 11, weight: .black, design: .monospaced)).padding(.vertical, 10).padding(.horizontal, 15).background(Color.red).foregroundColor(.black)
                        }
                        
                        Button(action: { showLocalFilePicker = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.on.square.fill")
                                Text("INJECT MODULE VIA STORAGE SOURCE (.HTML / .JS)")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(12).background(Color.red.opacity(0.15))
                            .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color.red.opacity(0.5), lineWidth: 1))
                        }
                    }
                    .padding().background(Color.red.opacity(0.02))
                }
                
                Text(viewTrashBinMode ? ">>> TRASH BUFFER ROW INDEX" : ">>> DRIVE MAP ROW INDEX")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.red.opacity(0.7)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal).padding(.top, 10)
                
                List {
                    let items = viewTrashBinMode ? fs.listTrashContents() : fs.listCurrentDirectoryContents()
                    
                    if items.isEmpty {
                        Text("NO DISK RECORD ENTRIES FOUND.")
                            .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                            .listRowBackground(Color.black)
                            .padding()
                    } else {
                        ForEach(items, id: \.self) { file in
                            let isDir = checkIsDirectory(url: file)
                            
                            HStack {
                                Image(systemName: isDir ? "folder.fill" : fileIcon(for: file))
                                    .foregroundColor(viewTrashBinMode ? .orange : (isDir ? .yellow : .red))
                                Text(file.lastPathComponent.uppercased())
                                    .font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
                                Spacer()
                                Text(isDir ? "DIR" : "\(file.pathExtension.uppercased())")
                                    .font(.system(size: 9, design: .monospaced)).foregroundColor(.white.opacity(0.3))
                            }
                            .listRowBackground(Color.black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewTrashBinMode { return }
                                if isDir {
                                    fs.navigateIntoFolder(file)
                                } else {
                                    routeFileSelection(file)
                                }
                            }
                            .contextMenu {
                                // FIXED: Extracted subview removes the processing tree expression overflow completely
                                FileContextMenu(
                                    file: file,
                                    isDir: isDir,
                                    viewTrashBinMode: viewTrashBinMode,
                                    renameTargetURL: $renameTargetURL,
                                    renameInputText: $renameInputText,
                                    showRenameAlert: $showRenameAlert,
                                    fileClipboard: $fileClipboard,
                                    clipboardIsCutOperation: $clipboardIsCutOperation
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .alert("CREATE SUB-DIRECTORY", isPresented: $showNewFolderAlert) {
            TextField("Folder Identity Name", text: $folderNameInput).autocapitalization(.none)
            Button("ALLOCATE") {
                if !folderNameInput.isEmpty { fs.createFolder(named: folderNameInput) }
                folderNameInput = ""
            }
            Button("CANCEL", role: .cancel) { folderNameInput = "" }
        }
        .alert("RENAME DRIVE ASSET", isPresented: $showRenameAlert) {
            TextField("New Asset Label", text: $renameInputText).autocapitalization(.none)
            Button("MODIFY") {
                if let target = renameTargetURL, !renameInputText.isEmpty {
                    fs.renameFile(fileURL: target, to: renameInputText)
                }
                renameTargetURL = nil
                renameInputText = ""
            }
            Button("CANCEL", role: .cancel) {
                renameTargetURL = nil
                renameInputText = ""
            }
        }
        .sheet(item: $selectedFile) { url in InternalFileViewer(fileURL: url) }
        .sheet(item: $sourceViewFile) { url in InternalFileViewer(fileURL: url, forceTextView: true) }
        .alert(installAlertMessage, isPresented: $showInstallAlert) {
            Button("ACKNOWLEDGE", role: .cancel) { }
        }
        .alert("HTML DETECTED", isPresented: $showHTMLChoiceAlert, presenting: htmlAlertFile) { file in
            Button("EXECUTE AS SYSTEM APP") {
                pm.launchProcess(from: file)
                isPresented = false
                htmlAlertFile = nil
            }
            Button("VIEW SOURCE CODE") {
                let targetFile = file
                htmlAlertFile = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.sourceViewFile = targetFile
                }
            }
            Button("CANCEL", role: .cancel) { htmlAlertFile = nil }
        } message: { file in
            Text("CHOOSE RUNTIME PARSING METHOD FOR\n\(file.lastPathComponent.uppercased())")
        }
        .fileImporter(
            isPresented: $showLocalFilePicker,
            allowedContentTypes: [.html, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    guard selectedURL.startAccessingSecurityScopedResource() else { return }
                    fs.importLocalFile(from: selectedURL)
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Deployment Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func getCurrentPathDisplay() -> String {
        if viewTrashBinMode { return "ROOT://VIRTUAL_VOLUMES/.TRASH" }
        let subPath = fs.currentDirectory.path.replacingOccurrences(of: fs.rootDirectory.path, with: "")
        return "ROOT://C_DRIVE" + subPath.uppercased()
    }
    
    private func checkIsDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
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
            // FIXED: Route both HTML and JS files through the system alert confirmation engine
            if ext == "html" || ext == "js" {
                htmlAlertFile = file
                showHTMLChoiceAlert = true
            } else {
                selectedFile = file
            }
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
            Button(action: { fs.restoreFromTrash(fileURL: file) }) {
                Label("Restore File to Drive", systemImage: "arrow.uturn.backward.circle.fill")
            }
            Button(role: .destructive, action: { fs.permanentlyDelete(fileURL: file) }) {
                Label("Permanently Purge", systemImage: "trash.slash.fill")
            }
        } else {
            Button(action: {
                renameTargetURL = file
                renameInputText = file.deletingPathExtension().lastPathComponent
                showRenameAlert = true
            }) {
                Label("Rename Asset", systemImage: "pencil")
            }
            Button(action: {
                fileClipboard = file
                clipboardIsCutOperation = false
            }) {
                Label("Copy Asset", systemImage: "doc.on.doc.fill")
            }
            Button(action: {
                fileClipboard = file
                clipboardIsCutOperation = true
            }) {
                Label("Cut Asset (Move)", systemImage: "scissors")
            }
            Button(action: { fs.moveToTrash(fileURL: file) }) {
                Label("Move to Recycle Bin", systemImage: "trash.fill")
            }
            if !isDir {
                Button(action: {
                    _ = FileSafeManager.importFromInternalPath(sourceURL: file)
                }) {
                    Label("Move to Secure File_Safe", systemImage: "lock.doc.fill")
                }
                
                if ["html", "js"].contains(file.pathExtension.lowercased()) {
                    Divider()
                    
                    Button(action: { fs.toggleDesktopShortcut(url: file) }) {
                        if fs.desktopShortcuts.contains(file) {
                            Label("Unpin from Desktop", systemImage: "desktopcomputer")
                        } else {
                            Label("Pin to Desktop", systemImage: "plus.rectangle.on.folder")
                        }
                    }
                    
                    Button(action: { fs.toggleDockShortcut(url: file) }) {
                        if fs.dockShortcuts.contains(file) {
                            Label("Unpin from Core Dock", systemImage: "pin.fill")
                        } else {
                            Label("Pin to Core Dock", systemImage: "pin")
                        }
                    }
                    
                    Button(action: { fs.toggleStartMenuShortcut(url: file) }) {
                        if fs.startMenuShortcuts.contains(file) {
                            Label("Unpin from Start Menu", systemImage: "command.circle.fill")
                        } else {
                            Label("Pin to Start Menu", systemImage: "command")
                        }
                    }
                }
            }
        }
    }
}
