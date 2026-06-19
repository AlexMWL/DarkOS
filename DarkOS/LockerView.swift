// DarkOS/LockerView.swift

import SwiftUI
import UniformTypeIdentifiers

enum VaultState {
    case setup, locked, decrypting, unlocked
}

struct LockerView: View {
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var currentState: VaultState = FileVaultManager.isPINSet() ? .locked : .setup
    @State private var inputPIN = ""
    @State private var errorMessage = ""
    @State private var failedAttempts = FileVaultManager.getFailedAttempts()
    
    @State private var savedFiles: [URL] = []
    @State private var newFileName = ""
    @State private var newFileContent = ""
    
    @State private var showNewFolderAlert = false
    @State private var folderNameInput = ""
    @State private var viewSafeTrashMode = false
    
    @State private var showSafeRenameAlert = false
    @State private var renameTargetURL: URL? = nil
    @State private var renameInputText = ""
    
    @State private var safeClipboard: URL? = nil
    @State private var clipboardIsCutOperation = false
    
    @State private var showFileImporter = false
    @State private var selectedSafeFile: URL? = nil
    @State private var fileToExport: URL? = nil
    @State private var showControlPanel = false
    
    let keypadKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "<"]
    
    var body: some View {
        VStack {
            switch currentState {
            case .setup: pinPadScreen(title: "INITIALIZE BITLOCKER", subtitle: "Set a new 4-digit crypt key")
            case .locked: pinPadScreen(title: "RESTRICTED SECTOR", subtitle: "Enter Crypt Key to unlock")
            case .decrypting: decryptingScreen
            case .unlocked: secretLockerScreen
            }
        }
        .padding()
        .background(theme.bgSolid.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.3), value: currentState)
        .onAppear { if currentState == .unlocked { refreshFileList() } }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item], allowsMultipleSelection: false) { result in handleFileImport(result: result) }
        .alert("ALLOCATE VAULT DIRECTORY", isPresented: $showNewFolderAlert) {
            TextField("Directory Sector Label", text: $folderNameInput).autocapitalization(.none)
            Button("PROCEED") { if !folderNameInput.isEmpty { FileVaultManager.createSafeFolder(named: folderNameInput); refreshFileList() }; folderNameInput = "" }
            Button("CANCEL", role: .cancel) { folderNameInput = "" }
        }
        .alert("RENAME VAULT ASSET", isPresented: $showSafeRenameAlert) {
            TextField("New Sector Name", text: $renameInputText).autocapitalization(.none)
            Button("MODIFY") { if let target = renameTargetURL, !renameInputText.isEmpty { FileVaultManager.renameSafeFile(fileURL: target, to: renameInputText); refreshFileList() }; renameTargetURL = nil; renameInputText = "" }
            Button("CANCEL", role: .cancel) { renameTargetURL = nil; renameInputText = "" }
        }
        .sheet(item: $selectedSafeFile) { url in FileDetailView(fileURL: url) }
        .sheet(item: $fileToExport) { file in
            VaultFolderPicker(fileURL: file) { destinationDir in
                _ = FileVaultManager.exportAndMove(fileURL: file, to: destinationDir)
                refreshFileList()
            }
        }
        .sheet(isPresented: $showControlPanel) {
            VaultControlPanel(showControlPanel: $showControlPanel, currentState: $currentState)
        }
    }
    
    private func pinPadScreen(title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: currentState == .setup ? "lock.shield.fill" : "lock.fill").font(.system(size: 28.5)).foregroundColor(theme.accent)
                Text(title).font(.system(size: 12.5, weight: .black, design: .rounded)).foregroundColor(theme.text)
                Text(subtitle).font(.system(size: 8.5, design: .monospaced)).foregroundColor(theme.textMuted)
            }
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in Circle().fill(inputPIN.count > index ? theme.accent : theme.panelDeep).frame(width: 10, height: 10) }
            }
            if !errorMessage.isEmpty { Text(errorMessage).font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.red)
            } else if failedAttempts > 0 && currentState == .locked { Text("FAILED ATTEMPTS: \(failedAttempts)").font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.red) }
            
            LazyVGrid(columns: [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))], spacing: 10) {
                ForEach(keypadKeys, id: \.self) { key in
                    Button(action: { handleKeypress(key) }) { Text(key).font(.system(size: 16.5, weight: .bold, design: .monospaced)).foregroundColor(theme.text).frame(width: 50, height: 50).background(theme.panel).clipShape(Circle()) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var decryptingScreen: some View {
        VStack(spacing: 20) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: theme.accent)).scaleEffect(1.5)
            Text("DECRYPTING VAULT SECTOR...").font(.system(size: 10.5, weight: .bold, design: .monospaced)).foregroundColor(theme.accent)
        }
    }
    
    private var secretLockerScreen: some View {
        VStack(spacing: 12) {
            vaultHeader
            vaultNavBar
            if !viewSafeTrashMode { vaultCompiler }
            vaultList
            vaultFooter
        }
    }
    
    private var vaultHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewSafeTrashMode ? "ISOLATED VAULT TRASH" : "FILE VAULT").font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(viewSafeTrashMode ? .orange : theme.accent)
                Text("\(savedFiles.count) Secure Objects Detected").font(.system(size: 8.5, design: .monospaced)).foregroundColor(theme.textMuted)
            }
            Spacer()
            Image(systemName: "lock.shield").font(.caption2).foregroundColor(theme.accent)
        }
        .padding(.bottom, 8)
    }
    
    private var vaultNavBar: some View {
        HStack {
            if !viewSafeTrashMode {
                HStack(spacing: 4) {
                    Button(action: { FileVaultManager.navigateSafeBack(); refreshFileList() }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.caption2)
                            .foregroundColor(FileVaultManager.safeBackStack.isEmpty ? .gray : theme.accent)
                    }
                    .disabled(FileVaultManager.safeBackStack.isEmpty)
                    
                    Button(action: { FileVaultManager.navigateSafeForward(); refreshFileList() }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.caption2)
                            .foregroundColor(FileVaultManager.safeForwardStack.isEmpty ? .gray : theme.accent)
                    }
                    .disabled(FileVaultManager.safeForwardStack.isEmpty)
                }
                .padding(.trailing, 4)
            }
            
            Text(getSafePathDisplay()).font(.system(size: 8.5, design: .monospaced)).foregroundColor(theme.textMuted).lineLimit(1)
            Spacer()
            if !viewSafeTrashMode {
                Button(action: { showNewFolderAlert = true }) { Image(systemName: "folder.badge.plus").foregroundColor(theme.accent) }
                if safeClipboard != nil { Button("PASTE") { executeSafePaste() }.font(.system(size: 8.5, weight: .bold, design: .monospaced)).foregroundColor(.yellow) }
                Button(action: { showControlPanel = true }) { Image(systemName: "gearshape.fill").foregroundColor(theme.accent) }
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    let trashItems = FileVaultManager.listSafeTrashContents()
                    for file in trashItems {
                        try? FileManager.default.removeItem(at: file)
                    }
                    refreshFileList()
                }) {
                    Image(systemName: "trash.slash.fill")
                        .foregroundColor(.red)
                }
            }
            Button(action: { viewSafeTrashMode.toggle(); refreshFileList() }) { Image(systemName: viewSafeTrashMode ? "shield.fill" : "trash.fill").foregroundColor(viewSafeTrashMode ? theme.accent : .orange).padding(6).background(theme.panel).cornerRadius(4) }
        }
        .padding(8).background(theme.panelDeep).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 1))
    }
    
    private var vaultCompiler: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Target Name (e.g., wallet.txt)", text: $newFileName).textFieldStyle(.plain).padding(8).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4).font(.system(size: 9.5, design: .monospaced))
                Button(action: { showFileImporter = true }) { Image(systemName: "square.and.arrow.down").foregroundColor(theme.text).padding(8).background(theme.panelDeep).cornerRadius(4) }
            }
            HStack {
                TextField("Raw text payload...", text: $newFileContent).textFieldStyle(.plain).padding(8).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4).font(.system(size: 9.5, design: .monospaced))
                Button("COMMIT") { guard !newFileName.isEmpty && !newFileContent.isEmpty else { return }; if FileVaultManager.saveTextFile(filename: newFileName, content: newFileContent) { newFileName = ""; newFileContent = ""; refreshFileList() } }
                    .font(.system(size: 8.5, weight: .bold)).padding(.horizontal, 12).padding(.vertical, 8).background(theme.accent).foregroundColor(.white).cornerRadius(4)
            }
        }
        .padding(10).background(theme.panel).cornerRadius(6)
    }
    
    private var vaultList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(savedFiles, id: \.self) { file in
                    VaultFileRow(
                        file: file, theme: theme, viewSafeTrashMode: viewSafeTrashMode,
                        renameTargetURL: $renameTargetURL, renameInputText: $renameInputText,
                        showSafeRenameAlert: $showSafeRenameAlert, safeClipboard: $safeClipboard,
                        clipboardIsCutOperation: $clipboardIsCutOperation, fileToExport: $fileToExport,
                        refreshAction: refreshFileList
                    )
                    .onTapGesture { if viewSafeTrashMode { return }; if file.isDarkOSDirectory { FileVaultManager.navigateSafeIntoFolder(file); refreshFileList() } else { selectedSafeFile = file } }
                }
            }
            .padding(.vertical, 4)
        }
        .background(theme.bgSolid).clipped()
    }
    
    private var vaultFooter: some View {
        HStack {
            Button(action: { currentState = .locked }) { HStack { Image(systemName: "lock.fill"); Text("SECURE SYSTEM") }.font(.system(size: 8.5, weight: .bold)).foregroundColor(theme.text).padding(8).background(theme.panel).cornerRadius(4) }
            Spacer()
        }
    }
    
    private func handleKeypress(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(); errorMessage = ""
        if key == "C" { inputPIN = "" } else if key == "<" { if !inputPIN.isEmpty { inputPIN.removeLast() } } else if inputPIN.count < 4 { inputPIN.append(key) }
        if inputPIN.count == 4 { processPinEntry() }
    }
    
    private func processPinEntry() {
        if currentState == .setup { if FileVaultManager.savePIN(inputPIN) { inputPIN = ""; currentState = .locked }
        } else if currentState == .locked {
            if FileVaultManager.verifyPIN(inputPIN) { inputPIN = ""; failedAttempts = 0; triggerDecryptionSequence() } else { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(); errorMessage = "CRYPT_KEY_REJECTED"; inputPIN = ""; failedAttempts = FileVaultManager.getFailedAttempts() }
        }
    }
    
    private func triggerDecryptionSequence() {
        currentState = .decrypting
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(); currentState = .unlocked; refreshFileList() }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selectedURL = urls.first else { return }
            if selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }
                if let fileData = try? Data(contentsOf: selectedURL) {
                    let targetURL = FileVaultManager.currentSafeDirectory.appendingPathComponent(selectedURL.lastPathComponent)
                    try? fileData.write(to: targetURL, options: .atomic)
                    refreshFileList()
                }
            }
        case .failure(let error): print("Vault error: \(error.localizedDescription)")
        }
    }
    
    private func refreshFileList() { savedFiles = viewSafeTrashMode ? FileVaultManager.listSafeTrashContents() : FileVaultManager.listCurrentSafeContents() }
    private func getSafePathDisplay() -> String {
        let rootPath = FileVaultManager.vaultRootDirectory.path
        let subPath = FileVaultManager.currentSafeDirectory.path.replacingOccurrences(of: rootPath, with: "")
        return "S:\\BitLocker\\Vault" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    private func executeSafePaste() {
        guard let source = safeClipboard else { return }; UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if clipboardIsCutOperation { FileVaultManager.moveSafeFile(fileURL: source, to: FileVaultManager.currentSafeDirectory); safeClipboard = nil } else { FileVaultManager.copySafeFile(fileURL: source, to: FileVaultManager.currentSafeDirectory) }
        refreshFileList()
    }
}

struct FileDetailView: View {
    let fileURL: URL
    @ObservedObject private var theme = ThemeManager.shared
    @State private var rawData: Data? = nil
    @State private var textContent: String? = nil
    @State private var isImage = false
    @State private var isPDF = false
    @State private var isAudio = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(fileURL.lastPathComponent.uppercased()).font(.system(size: 12.5, weight: .bold, design: .monospaced)).foregroundColor(theme.accent)
            Group {
                if isImage, let data = rawData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 400)
                } else if isPDF { PDFKitView(url: fileURL).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isAudio { AudioPlayerView(url: fileURL).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let text = textContent { ScrollView { Text(text).font(.system(size: 10.5, design: .monospaced)).padding().frame(maxWidth: .infinity, alignment: .leading).background(theme.panel).foregroundColor(theme.text) }
                } else { VStack { Image(systemName: "doc.zipper").font(.caption2).foregroundColor(theme.textMuted); Text("BINARY DATA SECTOR LOCKED").foregroundColor(theme.text) } }
            }
            .cornerRadius(4)
            Spacer()
        }
        .padding().background(theme.bgSolid.ignoresSafeArea()).onAppear { loadFileData() }
    }
    
    private func loadFileData() {
        guard let data = FileVaultManager.readBinaryFile(at: fileURL) else { return }
        rawData = data
        let ext = fileURL.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(ext) { isImage = true } else if ext == "pdf" { isPDF = true } else if ["mp3", "wav", "m4a"].contains(ext) { isAudio = true } else if let decodedString = String(data: data, encoding: .utf8) { textContent = decodedString }
    }
}

struct VaultFileRow: View {
    let file: URL
    let theme: ThemeManager
    let viewSafeTrashMode: Bool
    @Binding var renameTargetURL: URL?
    @Binding var renameInputText: String
    @Binding var showSafeRenameAlert: Bool
    @Binding var safeClipboard: URL?
    @Binding var clipboardIsCutOperation: Bool
    @Binding var fileToExport: URL?
    let refreshAction: () -> Void

    var body: some View {
        HStack {
            Image(systemName: file.isDarkOSDirectory ? "folder.fill" : (["mp3", "wav", "m4a"].contains(file.pathExtension.lowercased()) ? "music.note" : "lock.doc.fill")).foregroundColor(file.isDarkOSDirectory ? .yellow : theme.accent)
            Text(file.lastPathComponent.uppercased()).font(.system(size: 9.5, weight: .semibold, design: .monospaced)).foregroundColor(theme.text)
            Spacer()
        }
        .padding(10).background(theme.panel).cornerRadius(6).contentShape(Rectangle())
        .contextMenu {
            let isModulesDir = FileVaultManager.isProtectedModulesFolder(file)
            if viewSafeTrashMode {
                Button(action: { FileVaultManager.restoreFromSafeTrash(fileURL: file); refreshAction() }) { Label("Restore Asset", systemImage: "arrow.uturn.backward.circle.fill") }
                Button(role: .destructive, action: {
                    if !FileVaultManager.isProtectedModulesFolder(file) {
                        try? FileManager.default.removeItem(at: file)
                    }
                    refreshAction()
                }) { Label("Purge Binary", systemImage: "trash.slash.fill") }
                    .disabled(isModulesDir)
            } else {
                Button(action: { renameTargetURL = file; renameInputText = file.deletingPathExtension().lastPathComponent; showSafeRenameAlert = true }) { Label("Rename Token", systemImage: "pencil") }
                    .disabled(isModulesDir)
                Button(action: { safeClipboard = file; clipboardIsCutOperation = false }) { Label("Copy", systemImage: "doc.on.doc.fill") }
                    .disabled(isModulesDir)
                Button(action: { safeClipboard = file; clipboardIsCutOperation = true }) { Label("Cut", systemImage: "scissors") }
                    .disabled(isModulesDir)
                Button(action: { FileVaultManager.moveSafeItemToTrash(fileURL: file); refreshAction() }) { Label("Drop into Safe Trash", systemImage: "trash.fill") }
                    .disabled(isModulesDir)
                if !file.isDarkOSDirectory { Button(action: { fileToExport = file }) { Label("Export out to Workspace", systemImage: "square.and.arrow.up.fill") } }
            }
        }
    }
}

struct VaultControlPanel: View {
    @Binding var showControlPanel: Bool
    @Binding var currentState: VaultState
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var showWipeConfirmationAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("VAULT CONTROL PANEL")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.accent)
                Spacer()
                Button("DISMISS") {
                    showControlPanel = false
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            }
            .padding()
            .background(theme.panel)
            .overlay(Rectangle().frame(height: 1).foregroundColor(theme.border), alignment: .bottom)
            
            // Content
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "exclamationmark.shield")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accent)
                
                VStack(spacing: 8) {
                    Text("SECURE SYSTEM CONSOLE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(theme.text)
                    Text("Perform low-level maintenance operations on the File Vault sector.")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button(action: {
                    showWipeConfirmationAlert = true
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Wipe Sector!")
                    }
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(6)
                    .shadow(color: .red.opacity(0.3), radius: 4)
                }
                .padding(.horizontal, 24)
                .alert("WIPE VAULT SECTOR", isPresented: $showWipeConfirmationAlert) {
                    Button("ERASE ALL DATA", role: .destructive) {
                        FileVaultManager.wipeEntireVault()
                        currentState = .setup
                        showControlPanel = false
                    }
                    Button("CANCEL", role: .cancel) {}
                } message: {
                    Text("WARNING: This will permanently erase the entire File Vault and all files contained inside it.")
                }
                
                Spacer()
            }
            .padding()
            .background(theme.bgSolid)
        }
        .background(theme.bgSolid.ignoresSafeArea())
    }
}
