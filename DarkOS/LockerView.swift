// DarkOS/LockerView.swift

import SwiftUI
import UniformTypeIdentifiers

enum VaultState {
    case setup, locked, decrypting, unlocked
}

struct LockerView: View {
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var currentState: VaultState = FileSafeManager.isPINSet() ? .locked : .setup
    @State private var inputPIN = ""
    @State private var errorMessage = ""
    @State private var failedAttempts = FileSafeManager.getFailedAttempts()
    
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
            Button("PROCEED") { if !folderNameInput.isEmpty { FileSafeManager.createSafeFolder(named: folderNameInput); refreshFileList() }; folderNameInput = "" }
            Button("CANCEL", role: .cancel) { folderNameInput = "" }
        }
        .alert("RENAME VAULT ASSET", isPresented: $showSafeRenameAlert) {
            TextField("New Sector Name", text: $renameInputText).autocapitalization(.none)
            Button("MODIFY") { if let target = renameTargetURL, !renameInputText.isEmpty { FileSafeManager.renameSafeFile(fileURL: target, to: renameInputText); refreshFileList() }; renameTargetURL = nil; renameInputText = "" }
            Button("CANCEL", role: .cancel) { renameTargetURL = nil; renameInputText = "" }
        }
        .sheet(item: $selectedSafeFile) { url in FileDetailView(fileURL: url) }
    }
    
    private func pinPadScreen(title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Image(systemName: currentState == .setup ? "lock.shield.fill" : "lock.fill").font(.system(size: 30)).foregroundColor(theme.accent)
                Text(title).font(.system(size: 14, weight: .black, design: .rounded)).foregroundColor(theme.text)
                Text(subtitle).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.textMuted)
            }
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { index in Circle().fill(inputPIN.count > index ? theme.accent : theme.panelDeep).frame(width: 10, height: 10) }
            }
            if !errorMessage.isEmpty { Text(errorMessage).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.red)
            } else if failedAttempts > 0 && currentState == .locked { Text("FAILED ATTEMPTS: \(failedAttempts)").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.red) }
            
            LazyVGrid(columns: [GridItem(.fixed(50)), GridItem(.fixed(50)), GridItem(.fixed(50))], spacing: 10) {
                ForEach(keypadKeys, id: \.self) { key in
                    Button(action: { handleKeypress(key) }) { Text(key).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(theme.text).frame(width: 50, height: 50).background(theme.panel).clipShape(Circle()) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var decryptingScreen: some View {
        VStack(spacing: 20) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: theme.accent)).scaleEffect(1.5)
            Text("DECRYPTING VAULT SECTOR...").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(theme.accent)
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
                Text(viewSafeTrashMode ? "ISOLATED SAFE TRASH" : "BITLOCKER VAULT").font(.system(size: 13, weight: .black, design: .rounded)).foregroundColor(viewSafeTrashMode ? .orange : theme.accent)
                Text("\(savedFiles.count) Secure Objects Detected").font(.system(size: 10, design: .monospaced)).foregroundColor(theme.textMuted)
            }
            Spacer()
            Image(systemName: "lock.shield").font(.title2).foregroundColor(theme.accent)
        }
        .padding(.bottom, 8)
    }
    
    private var vaultNavBar: some View {
        HStack {
            if !viewSafeTrashMode && FileSafeManager.currentSafeDirectory != FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] {
                Button(action: { FileSafeManager.navigateSafeBack(); refreshFileList() }) { Image(systemName: "arrow.up.left.square.fill").font(.title3).foregroundColor(theme.accent) }
            }
            Text(getSafePathDisplay()).font(.system(size: 10, design: .monospaced)).foregroundColor(theme.textMuted).lineLimit(1)
            Spacer()
            if !viewSafeTrashMode {
                Button(action: { showNewFolderAlert = true }) { Image(systemName: "folder.badge.plus").foregroundColor(theme.accent) }
                if safeClipboard != nil { Button("PASTE") { executeSafePaste() }.font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.yellow) }
            }
            Button(action: { viewSafeTrashMode.toggle(); refreshFileList() }) { Image(systemName: viewSafeTrashMode ? "shield.fill" : "trash.fill").foregroundColor(viewSafeTrashMode ? theme.accent : .orange).padding(6).background(theme.panel).cornerRadius(4) }
        }
        .padding(8).background(theme.panelDeep).cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(theme.border, lineWidth: 1))
    }
    
    private var vaultCompiler: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Target Name (e.g., wallet.txt)", text: $newFileName).textFieldStyle(.plain).padding(8).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4).font(.system(size: 11, design: .monospaced))
                Button(action: { showFileImporter = true }) { Image(systemName: "square.and.arrow.down").foregroundColor(theme.text).padding(8).background(theme.panelDeep).cornerRadius(4) }
            }
            HStack {
                TextField("Raw text payload...", text: $newFileContent).textFieldStyle(.plain).padding(8).background(theme.panelDeep).foregroundColor(theme.text).cornerRadius(4).font(.system(size: 11, design: .monospaced))
                Button("COMMIT") { guard !newFileName.isEmpty && !newFileContent.isEmpty else { return }; if FileSafeManager.saveTextFile(filename: newFileName, content: newFileContent) { newFileName = ""; newFileContent = ""; refreshFileList() } }
                    .font(.system(size: 10, weight: .bold)).padding(.horizontal, 12).padding(.vertical, 8).background(theme.accent).foregroundColor(.white).cornerRadius(4)
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
                        clipboardIsCutOperation: $clipboardIsCutOperation, refreshAction: refreshFileList
                    )
                    .onTapGesture { if viewSafeTrashMode { return }; if file.isDarkOSDirectory { FileSafeManager.currentSafeDirectory = file; refreshFileList() } else { selectedSafeFile = file } }
                }
            }
            .padding(.vertical, 4)
        }
        .background(theme.bgSolid).clipped()
    }
    
    private var vaultFooter: some View {
        HStack {
            Button(action: { currentState = .locked }) { HStack { Image(systemName: "lock.fill"); Text("SECURE SYSTEM") }.font(.system(size: 10, weight: .bold)).foregroundColor(theme.text).padding(8).background(theme.panel).cornerRadius(4) }
            Spacer()
            Button("WIPE SECTOR") { if FileSafeManager.deletePIN() { currentState = .setup } }.font(.system(size: 10, weight: .bold)).foregroundColor(.red)
        }
    }
    
    private func handleKeypress(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(); errorMessage = ""
        if key == "C" { inputPIN = "" } else if key == "<" { if !inputPIN.isEmpty { inputPIN.removeLast() } } else if inputPIN.count < 4 { inputPIN.append(key) }
        if inputPIN.count == 4 { processPinEntry() }
    }
    
    private func processPinEntry() {
        if currentState == .setup { if FileSafeManager.savePIN(inputPIN) { inputPIN = ""; currentState = .locked }
        } else if currentState == .locked {
            if FileSafeManager.verifyPIN(inputPIN) { inputPIN = ""; failedAttempts = 0; triggerDecryptionSequence() } else { UIImpactFeedbackGenerator(style: .heavy).impactOccurred(); errorMessage = "CRYPT_KEY_REJECTED"; inputPIN = ""; failedAttempts = FileSafeManager.getFailedAttempts() }
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
                    let targetURL = FileSafeManager.currentSafeDirectory.appendingPathComponent(selectedURL.lastPathComponent)
                    try? fileData.write(to: targetURL, options: .atomic)
                    refreshFileList()
                }
            }
        case .failure(let error): print("Vault error: \(error.localizedDescription)")
        }
    }
    
    private func refreshFileList() { savedFiles = viewSafeTrashMode ? FileSafeManager.listSafeTrashContents() : FileSafeManager.listCurrentSafeContents() }
    private func getSafePathDisplay() -> String {
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        let subPath = FileSafeManager.currentSafeDirectory.path.replacingOccurrences(of: docPath, with: "")
        return "S:\\BitLocker\\Vault" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    private func executeSafePaste() {
        guard let source = safeClipboard else { return }; UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if clipboardIsCutOperation { FileSafeManager.moveSafeFile(fileURL: source, to: FileSafeManager.currentSafeDirectory); safeClipboard = nil } else { FileSafeManager.copySafeFile(fileURL: source, to: FileSafeManager.currentSafeDirectory) }
        refreshFileList()
    }
}

struct FileDetailView: View {
    let fileURL: URL
    @ObservedObject private var theme = ThemeManager.shared
    @State private var rawData: Data? = nil
    @State private var textContent: String? = nil
    @State private var isImage = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(fileURL.lastPathComponent.uppercased()).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(theme.accent)
            Group {
                if isImage, let data = rawData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 400)
                } else if let text = textContent { ScrollView { Text(text).font(.system(size: 12, design: .monospaced)).padding().frame(maxWidth: .infinity, alignment: .leading).background(theme.panel).foregroundColor(theme.text) }
                } else { VStack { Image(systemName: "doc.zipper").font(.largeTitle).foregroundColor(theme.textMuted); Text("BINARY DATA SECTOR LOCKED").foregroundColor(theme.text) } }
            }
            .cornerRadius(4)
            Spacer()
        }
        .padding().background(theme.bgSolid.ignoresSafeArea()).onAppear { loadFileData() }
    }
    
    private func loadFileData() {
        guard let data = FileSafeManager.readBinaryFile(at: fileURL) else { return }
        rawData = data
        let ext = fileURL.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic", "webp"].contains(ext) { isImage = true } else if let decodedString = String(data: data, encoding: .utf8) { textContent = decodedString }
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
    let refreshAction: () -> Void

    var body: some View {
        HStack {
            Image(systemName: file.isDarkOSDirectory ? "folder.fill" : "lock.doc.fill").foregroundColor(file.isDarkOSDirectory ? .yellow : theme.accent)
            Text(file.lastPathComponent.uppercased()).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(theme.text)
            Spacer()
        }
        .padding(10).background(theme.panel).cornerRadius(6).contentShape(Rectangle())
        .contextMenu {
            if viewSafeTrashMode {
                Button(action: { FileSafeManager.restoreFromSafeTrash(fileURL: file); refreshAction() }) { Label("Restore Asset", systemImage: "arrow.uturn.backward.circle.fill") }
                Button(role: .destructive, action: { try? FileManager.default.removeItem(at: file); refreshAction() }) { Label("Purge Binary", systemImage: "trash.slash.fill") }
            } else {
                Button(action: { renameTargetURL = file; renameInputText = file.deletingPathExtension().lastPathComponent; showSafeRenameAlert = true }) { Label("Rename Token", systemImage: "pencil") }
                Button(action: { safeClipboard = file; clipboardIsCutOperation = false }) { Label("Copy", systemImage: "doc.on.doc.fill") }
                Button(action: { safeClipboard = file; clipboardIsCutOperation = true }) { Label("Cut", systemImage: "scissors") }
                Button(action: { FileSafeManager.moveSafeItemToTrash(fileURL: file); refreshAction() }) { Label("Drop into Safe Trash", systemImage: "trash.fill") }
                if !file.isDarkOSDirectory { Button(action: { _ = FileSafeManager.exportToInternalPath(fileURL: file) }) { Label("Export out to Workspace", systemImage: "square.and.arrow.up.fill") } }
            }
        }
    }
}
