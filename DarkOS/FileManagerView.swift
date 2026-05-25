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
    
    private var currentListItems: [URL] {
        viewTrashBinMode ? fs.listTrashContents() : fs.listCurrentDirectoryContents()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                HStack {
                    Image(systemName: "folder.fill").foregroundColor(.yellow)
                    Text(viewTrashBinMode ? "Recycle Bin subsystem" : "File Explorer // Network Storage")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Text("CLOSE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.6))
                            .cornerRadius(3)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.06))
                
                HStack(spacing: 12) {
                    if !viewTrashBinMode {
                        HStack(spacing: 6) {
                            Button(action: { fs.navigateBack() }) {
                                Image(systemName: "arrow.left.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(fs.backStack.isEmpty ? .gray : .red)
                            }
                            .disabled(fs.backStack.isEmpty)
                            
                            Button(action: { fs.navigateForward() }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(fs.forwardStack.isEmpty ? .gray : .red)
                            }
                            .disabled(fs.forwardStack.isEmpty)
                            
                            Button(action: { showNewFolderAlert = true }) {
                                Image(systemName: "folder.badge.plus.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    HStack {
                        Image(systemName: "desktopcomputer").font(.caption).foregroundColor(.gray)
                        Text(getCurrentPathDisplay())
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.15), lineWidth: 1))
                    
                    if !viewTrashBinMode && fileClipboard != nil {
                        Button(action: { executePasteAction() }) {
                            Text("PASTE").font(.system(size: 11, weight: .black, design: .rounded)).foregroundColor(.yellow)
                        }
                    }
                    
                    Button(action: { viewTrashBinMode.toggle() }) {
                        Text(viewTrashBinMode ? "Computer Drives" : "Recycle Bin")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(viewTrashBinMode ? Color.green.opacity(0.4) : Color.orange.opacity(0.4))
                            .cornerRadius(4)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.02))
                
                if !viewTrashBinMode {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Over-The-Air System Compiler Workspace")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.red.opacity(0.8))
                        
                        HStack(spacing: 8) {
                            TextField("URL Source Link...", text: $webURLString)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                            
                            TextField("App Label", text: $downloadName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .frame(width: 100)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                            
                            Button(action: {
                                fs.downloadApp(from: webURLString, saveAs: downloadName) { success in
                                    installAlertMessage = success ? "MANIFEST MODULE COMPILED SUCCESSFULLY." : "PACKET DISCOVERY INTERRUPT EXCEPTION."
                                    showInstallAlert = true
                                    if success { webURLString = ""; downloadName = "" }
                                }
                            }) {
                                Text("COMPILE")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Button(action: { showLocalFilePicker = true }) {
                            Label("Inject External Module Node Asset (.html / .js)", systemImage: "square.and.arrow.down.fill")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                }
                
                List {
                    if currentListItems.isEmpty {
                        Text("No data structures mapped inside this segment cluster.")
                            .font(.system(size: 12, design: .rounded)).foregroundColor(.gray)
                            .listRowBackground(Color.black)
                    } else {
                        ForEach(currentListItems, id: \.self) { file in
                            HStack {
                                
                                Image(systemName: file.isDarkOSDirectory ? "folder.fill" : fileIcon(for: file))
                                    .foregroundColor(viewTrashBinMode ? .orange : (file.isDarkOSDirectory ? .yellow : .red))
                                Text(file.lastPathComponent.uppercased())
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(file.isDarkOSDirectory ? "File Folder" : "\(file.pathExtension.uppercased()) File")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if viewTrashBinMode { return }
                                if file.isDarkOSDirectory {
                                    fs.navigateIntoFolder(file)
                                } else {
                                    routeFileSelection(file)
                                }
                            }
                            .contextMenu {
                                FileContextMenu(
                                    file: file,
                                    isDir: file.isDarkOSDirectory,
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
        return "C:\\DarkOS\\Drive" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
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
