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
    @State private var selectedSafeFile: URL? = nil // Presentation routing target URL
    
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
            .animation(.default, value: isUnlocked)
            .onAppear {
                if isUnlocked { refreshFileList() }
            }
        }
    }
    
    // MARK: - Setup UI
    var setupScreen: some View {
        VStack(spacing: 20) {
            Text("Create Your Safe PIN").font(.title2).bold()
            SecureField("Enter 4-Digit PIN", text: $inputPIN)
                .textFieldStyle(.roundedBorder).keyboardType(.numberPad).multilineTextAlignment(.center)
            
            Button("Set PIN") {
                if inputPIN.count >= 4 {
                    if FileSafeManager.savePIN(inputPIN) {
                        pinExists = true
                        inputPIN = ""
                        errorMessage = ""
                    }
                } else {
                    errorMessage = "PIN must be at least 4 digits."
                }
            }
            .buttonStyle(.borderedProminent)
            Text(errorMessage).foregroundColor(.red)
        }
    }
    
    // MARK: - Lock UI
    var lockScreen: some View {
        VStack(spacing: 20) {
            Text("File_Safe is Locked").font(.title2).bold()
            SecureField("Enter PIN", text: $inputPIN)
                .textFieldStyle(.roundedBorder).keyboardType(.numberPad).multilineTextAlignment(.center)
            
            Button("Unlock") {
                if FileSafeManager.verifyPIN(inputPIN) {
                    isUnlocked = true
                    errorMessage = ""
                    refreshFileList()
                } else {
                    errorMessage = "Wrong PIN. Try again, dude."
                }
                inputPIN = ""
            }
            .buttonStyle(.borderedProminent)
            Text(errorMessage).foregroundColor(.red)
        }
    }
    
    // MARK: - Secret Locker Mainframe View
    var secretLockerScreen: some View {
        VStack(spacing: 15) {
            Text(viewSafeTrashMode ? "🗑️ Vault Recycle Bin" : "🔓 DarkOS File_Safe Vault")
                .font(.title2).bold()
                .foregroundColor(viewSafeTrashMode ? .orange : .green)
            
            HStack {
                if !viewSafeTrashMode && FileSafeManager.currentSafeDirectory != FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] {
                    Button(action: { FileSafeManager.navigateSafeBack(); refreshFileList() }) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                            Text("BACK")
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
                    .padding(.trailing, 8)
                    
                    if safeClipboard != nil {
                        Button(action: { executeSafePaste() }) {
                            Text("PASTE").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.yellow)
                        }
                        .padding(.trailing, 8)
                    }
                }
                
                Button(action: { viewSafeTrashMode.toggle(); refreshFileList() }) {
                    Text(viewSafeTrashMode ? "VAULT DRIVES" : "SECURE TRASH")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(viewSafeTrashMode ? .green : .orange)
                }
            }
            .padding(.horizontal, 4).padding(.vertical, 6)
            .background(Color.white.opacity(0.02))
            
            if !viewSafeTrashMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create New Secret Note").font(.caption).foregroundColor(.gray)
                    TextField("Filename (e.g., passkeys.txt)", text: $newFileName)
                        .textFieldStyle(.roundedBorder).autocapitalization(.none)
                    TextField("Secret Content...", text: $newFileContent).textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Button("Lock File into Safe") {
                            guard !newFileName.isEmpty && !newFileContent.isEmpty else { return }
                            if FileSafeManager.saveTextFile(filename: newFileName, content: newFileContent) {
                                newFileName = ""
                                newFileContent = ""
                                refreshFileList()
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                        
                        Button(action: { showFileImporter = true }) {
                            Label("Import iOS File", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding().background(Color.white.opacity(0.05)).cornerRadius(10)
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
                        print("Import error: \(error.localizedDescription)")
                    }
                }
            }
            
            List {
                if savedFiles.isEmpty {
                    Text("NO SECURE SECTOR RECORDS DETECTED.")
                        .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                        .listRowBackground(Color.black).padding()
                } else {
                    ForEach(savedFiles, id: \.self) { file in
                        let isDir = checkIsSafeDirectory(url: file)
                        
                        HStack {
                            Image(systemName: isDir ? "folder.fill" : "doc.text.fill")
                                .foregroundColor(viewSafeTrashMode ? .orange : (isDir ? .yellow : .green))
                            Text(file.lastPathComponent.uppercased())
                                .font(.system(size: 13, design: .monospaced)).foregroundColor(.white)
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
                                    Label("Restore to Vault Base", systemImage: "arrow.uturn.backward.circle.fill")
                                }
                                Button(role: .destructive, action: { try? FileManager.default.removeItem(at: file); refreshFileList() }) {
                                    Label("Permanently Destroy", systemImage: "trash.slash.fill")
                                }
                            } else {
                                Button(action: {
                                    renameTargetURL = file
                                    renameInputText = file.deletingPathExtension().lastPathComponent
                                    showSafeRenameAlert = true
                                }) {
                                    Label("Rename Vault Asset", systemImage: "pencil")
                                }
                                Button(action: { safeClipboard = file; clipboardIsCutOperation = false }) {
                                    Label("Copy Secured File", systemImage: "doc.on.doc.fill")
                                }
                                Button(action: { safeClipboard = file; clipboardIsCutOperation = true }) {
                                    Label("Cut Secured File", systemImage: "scissors")
                                }
                                Button(action: { FileSafeManager.moveSafeItemToTrash(fileURL: file); refreshFileList() }) {
                                    Label("Move to Secure Trash", systemImage: "trash.fill")
                                }
                                if !isDir {
                                    Button(action: {
                                        _ = FileSafeManager.exportToInternalPath(fileURL: file)
                                    }) {
                                        Label("Export to C_Drive Workspace", systemImage: "square.and.arrow.up.fill")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            
            HStack {
                Button("Lock Safe") { isUnlocked = false }.buttonStyle(.bordered)
                Spacer()
                Button("Nuke Safe (Reset)") {
                    if FileSafeManager.deletePIN() {
                        pinExists = false
                        isUnlocked = false
                    }
                }.foregroundColor(.red)
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
            TextField("New Sector Name", text: $renameInputText)
                .autocapitalization(.none)
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
        if viewSafeTrashMode { return "VAULT://ISOLATED_CLUSTER/.SAFETRASH" }
        let docPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path
        let subPath = FileSafeManager.currentSafeDirectory.path.replacingOccurrences(of: docPath, with: "")
        return "VAULT://SECURE_NODE" + subPath.uppercased()
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
