import SwiftUI
import UniformTypeIdentifiers

struct LockerView: View {
    @State private var isUnlocked = false
    @State private var pinExists = FileSafeManager.isPINSet()
    
    @State private var inputPIN = ""
    @State private var errorMessage = ""
    
    // Arrays tracking real item URLs
    @State private var savedFiles: [URL] = []
    @State private var newFileName = ""
    @State private var newFileContent = ""
    
    // Folder & Secure Trash Mode Toggles
    @State private var showNewFolderAlert = false
    @State private var folderNameInput = ""
    @State private var viewSafeTrashMode = false
    
    // Rename Matrix
    @State private var showSafeRenameAlert = false
    @State private var renameTargetURL: URL? = nil
    @State private var renameInputText = ""
    
    // Clipboard Matrix for Vault File Swapping
    @State private var safeClipboard: URL? = nil
    @State private var clipboardIsCutOperation = false
    
    @State private var showFileImporter = false
    @State private var selectedSafeFile: URL? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if !pinExists {
                    setupScreen
                } else if !isUnlocked {
                    lockScreen
                } else {
                    secretLockerScreen
                }
            }
            .padding()
            .background(Color.black.ignoresSafeArea()) // Keep it deep locked black
            .animation(.easeInOut, value: isUnlocked)
            .onAppear {
                if isUnlocked { refreshFileList() }
            }
        }
    }
    
    // MARK: - SETUP PIN CODE CONTROL UI
    var setupScreen: some View {
        VStack(spacing: 25) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.5), radius: 6)
            
            Text("Initialize BitLocker Crypt Sector")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            SecureField("Setup 4-Digit Passkey", text: $inputPIN)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .frame(width: 220)
            
            Button(action: {
                if inputPIN.count >= 4 {
                    if FileSafeManager.savePIN(inputPIN) {
                        pinExists = true
                        inputPIN = ""
                        errorMessage = ""
                    }
                } else {
                    errorMessage = "Crypt parameters require at least 4 numbers."
                }
            }) {
                Text("MOUNT SECURE SYSTEM")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
            Text(errorMessage).font(.caption).foregroundColor(.red)
        }
    }
    
    // MARK: - VERIFY VAULT PIN CONTROL UI
    var lockScreen: some View {
        VStack(spacing: 25) {
            Image(systemName: "shield.keys.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("Crypt Sector Access Restrained")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            SecureField("Enter Secure Node PIN", text: $inputPIN)
                .textFieldStyle(.plain)
                .font(.system(size: 14, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(6)
                .frame(width: 220)
            
            Button(action: {
                if FileSafeManager.verifyPIN(inputPIN) {
                    isUnlocked = true
                    errorMessage = ""
                    refreshFileList()
                } else {
                    errorMessage = "Security mismatch verification fault code, dude."
                }
                inputPIN = ""
            }) {
                Text("DECRYPT DRIVE PORT")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .background(Color.green)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
            Text(errorMessage).font(.caption).foregroundColor(.red)
        }
    }
    
    // MARK: - SECURE MATRIX RECORD FILES DIRECTORY
    var secretLockerScreen: some View {
        VStack(spacing: 15) {
            HStack {
                Text(viewSafeTrashMode ? "🔐 Isolated Safe Trash Buffer" : "🛡️ BitLocker // Virtual Private Safe")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(viewSafeTrashMode ? .orange : .green)
                Spacer()
            }
            
            HStack {
                if !viewSafeTrashMode && FileSafeManager.currentSafeDirectory != FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] {
                    Button(action: { FileSafeManager.navigateSafeBack(); refreshFileList() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.square.fill")
                            Text("UP DIR")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.green)
                    }
                }
                
                Text(getSafePathDisplay())
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.gray).lineLimit(1)
                
                Spacer()
                
                if !viewSafeTrashMode {
                    Button(action: { showNewFolderAlert = true }) {
                        Image(systemName: "folder.badge.plus").foregroundColor(.green)
                    }
                    
                    if safeClipboard != nil {
                        Button("PASTE") { executeSafePaste() }
                            .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.yellow)
                    }
                }
                
                Button(action: { viewSafeTrashMode.toggle(); refreshFileList() }) {
                    Text(viewSafeTrashMode ? "SAFE SECURE" : "VAULT TRASH")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(viewSafeTrashMode ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundColor(viewSafeTrashMode ? .green : .orange)
                        .cornerRadius(3)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.04))
            .cornerRadius(4)
            
            if !viewSafeTrashMode {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Crypt File Generation Node").font(.caption).foregroundColor(.gray)
                    
                    TextField("Secure Label Target Name (e.g., wallet.txt)", text: $newFileName)
                        .textFieldStyle(.plain).padding(8).background(Color.black).foregroundColor(.white).cornerRadius(4).font(.system(size: 12, design: .monospaced))
                    
                    TextField("Raw payload binary context...", text: $newFileContent)
                        .textFieldStyle(.plain).padding(8).background(Color.black).foregroundColor(.white).cornerRadius(4).font(.system(size: 12, design: .monospaced))
                    
                    HStack {
                        Button("COMMIT TO VAULT") {
                            guard !newFileName.isEmpty && !newFileContent.isEmpty else { return }
                            if FileSafeManager.saveTextFile(filename: newFileName, content: newFileContent) {
                                newFileName = ""
                                newFileContent = ""
                                refreshFileList()
                            }
                        }
                        .font(.system(size: 11, weight: .bold)).tint(.green).buttonStyle(.borderedProminent)
                        
                        Button(action: { showFileImporter = true }) {
                            Label("Import File Frame", systemImage: "square.and.arrow.down")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding().background(Color.white.opacity(0.04)).cornerRadius(6)
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: false
                ) { result in
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
                    case .failure(let error):
                        print("Vault error code mapping exception: \(error.localizedDescription)")
                    }
                }
            }
            
            List {
                if savedFiles.isEmpty {
                    Text("NO SECURE DESCRIPTOR BLOCKS INITIALIZED IN SECTOR.")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                        .listRowBackground(Color.black)
                } else {
                    ForEach(savedFiles, id: \.self) { file in
                        let isDir = checkIsSafeDirectory(url: file)
                        
                        HStack {
                            Image(systemName: isDir ? "folder.fill" : "lock.doc.fill")
                                .foregroundColor(viewSafeTrashMode ? .orange : (isDir ? .yellow : .green))
                            Text(file.lastPathComponent.uppercased())
                                .font(.system(size: 12, design: .monospaced)).foregroundColor(.white)
                            Spacer()
                        }
                        .listRowBackground(Color.black)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if viewSafeTrashMode { return }
                            if isDir {
                                FileSafeManager.currentSafeDirectory = file
                                refreshFileList()
                            } else {
                                selectedSafeFile = file
                            }
                        }
                        .contextMenu {
                            if viewSafeTrashMode {
                                Button(action: { FileSafeManager.restoreFromSafeTrash(fileURL: file); refreshFileList() }) {
                                    Label("Restore Asset", systemImage: "arrow.uturn.backward.circle.fill")
                                }
                                Button(role: .destructive, action: { try? FileManager.default.removeItem(at: file); refreshFileList() }) {
                                    Label("Purge Binary", systemImage: "trash.slash.fill")
                                }
                            } else {
                                Button(action: {
                                    renameTargetURL = file
                                    renameInputText = file.deletingPathExtension().lastPathComponent
                                    showSafeRenameAlert = true
                                }) {
                                    Label("Rename Token", systemImage: "pencil")
                                }
                                Button(action: { safeClipboard = file; clipboardIsCutOperation = false }) {
                                    Label("Copy", systemImage: "doc.on.doc.fill")
                                }
                                Button(action: { safeClipboard = file; clipboardIsCutOperation = true }) {
                                    Label("Cut", systemImage: "scissors")
                                }
                                Button(action: { FileSafeManager.moveSafeItemToTrash(fileURL: file); refreshFileList() }) {
                                    Label("Drop into Safe Trash", systemImage: "trash.fill")
                                }
                                if !isDir {
                                    Button(action: {
                                        _ = FileSafeManager.exportToInternalPath(fileURL: file)
                                    }) {
                                        Label("Export out to Workspace", systemImage: "square.and.arrow.up.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            HStack {
                Button("SECURE SYSTEM") { isUnlocked = false }.font(.system(size: 11)).buttonStyle(.bordered)
                Spacer()
                Button("RESET SYSTEM SECTOR") {
                    if FileSafeManager.deletePIN() {
                        pinExists = false
                        isUnlocked = false
                    }
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.red)
            }
        }
        .alert("ALLOCATE VAULT DIRECTORY", isPresented: $showNewFolderAlert) {
            TextField("Directory Sector Label", text: $folderNameInput).autocapitalization(.none)
            Button("PROCEED") {
                if !folderNameInput.isEmpty {
                    FileSafeManager.createSafeFolder(named: folderNameInput)
                    refreshFileList()
                }
                folderNameInput = ""
            }
            Button("CANCEL", role: .cancel) { folderNameInput = "" }
        }
        .alert("RENAME VAULT ASSET", isPresented: $showSafeRenameAlert) {
            TextField("New Sector Name", text: $renameInputText).autocapitalization(.none)
            Button("MODIFY") {
                if let target = renameTargetURL, !renameInputText.isEmpty {
                    FileSafeManager.renameSafeFile(fileURL: target, to: renameInputText)
                    refreshFileList()
                }
                renameTargetURL = nil
                renameInputText = ""
            }
            Button("CANCEL", role: .cancel) {
                renameTargetURL = nil
                renameInputText = ""
            }
        }
        .sheet(item: $selectedSafeFile) { url in
            FileDetailView(fileURL: url)
        }
    }
    
    private func refreshFileList() {
        savedFiles = viewSafeTrashMode ? FileSafeManager.listSafeTrashContents() : FileSafeManager.listCurrentSafeContents()
    }
    
    private func checkIsSafeDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    private func getSafePathDisplay() -> String {
        if viewSafeTrashMode { return "VAULT:\\SystemIsolated\\.SafeTrash" }
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        let subPath = FileSafeManager.currentSafeDirectory.path.replacingOccurrences(of: docPath, with: "")
        return "S:\\BitLocker\\SecureVault" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    
    private func executeSafePaste() {
        guard let source = safeClipboard else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if clipboardIsCutOperation {
            FileSafeManager.moveSafeFile(fileURL: source, to: FileSafeManager.currentSafeDirectory)
            safeClipboard = nil
        } else {
            FileSafeManager.copySafeFile(fileURL: source, to: FileSafeManager.currentSafeDirectory)
        }
        refreshFileList()
    }
}

// MARK: - DETAILED FILE VIEW OVERLAY
struct FileDetailView: View {
    let fileURL: URL
    @State private var rawData: Data? = nil
    @State private var textContent: String? = nil
    @State private var isImage = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(fileURL.lastPathComponent.uppercased())
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            Group {
                if isImage, let data = rawData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 400)
                        .border(Color.green.opacity(0.3), width: 1)
                } else if let text = textContent {
                    ScrollView {
                        Text(text)
                            .font(.system(size: 12, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .foregroundColor(.white)
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.zipper")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("BINARY DATA SECTOR LOCKED")
                            .font(.system(size: 11, design: .monospaced))
                        Text("\(rawData?.count ?? 0) BYTES")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color.white.opacity(0.02))
                }
            }
            .cornerRadius(4)
            
            Spacer()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            loadFileData()
        }
    }
    
    private func loadFileData() {
        guard let data = FileSafeManager.readBinaryFile(at: fileURL) else {
            textContent = "ERROR: Failed to read safe sector."
            return
        }
        rawData = data
        
        let ext = fileURL.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic"].contains(ext) {
            isImage = true
        } else {
            if let decodedString = String(data: data, encoding: .utf8) {
                textContent = decodedString
            }
        }
    }
}

// MARK: - EXTENSION MATRIX FOR MODAL ROUTING CONFORMANCE
extension URL: Identifiable {
    public var id: String { self.absoluteString }
}
