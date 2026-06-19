// DarkOS/VaultFolderPicker.swift

import SwiftUI

struct VaultFolderPicker: View {
    let fileURL: URL
    let onExport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeManager.shared
    @State private var currentDir: URL = FileSystemManager.shared.rootDirectory
    @State private var dirStack: [URL] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SELECT DESTINATION SECTOR")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.accent)
                Spacer()
                Button("CANCEL") {
                    dismiss()
                }
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            }
            .padding()
            .background(theme.panel)
            .overlay(Rectangle().frame(height: 1).foregroundColor(theme.border), alignment: .bottom)
            
            // Current path bar
            HStack {
                if !dirStack.isEmpty {
                    Button(action: {
                        if !dirStack.isEmpty {
                            currentDir = dirStack.removeLast()
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.accent)
                            .padding(6)
                            .background(theme.panel)
                            .cornerRadius(4)
                    }
                }
                
                Text(getCurrentPathDisplay())
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(theme.textMuted)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(theme.panelDeep)
            .overlay(Rectangle().frame(height: 1).foregroundColor(theme.border), alignment: .bottom)
            
            // Subfolder list
            List {
                let folders = getSubfolders()
                if folders.isEmpty {
                    Text("NO SUB-DIRECTORIES DISCOVERED IN THIS SECTOR.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(theme.textMuted)
                        .listRowBackground(theme.bgSolid)
                } else {
                    ForEach(folders, id: \.self) { folder in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.yellow)
                            Text(folder.lastPathComponent.uppercased())
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(theme.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8))
                                .foregroundColor(theme.textMuted)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dirStack.append(currentDir)
                            currentDir = folder
                        }
                        .listRowBackground(theme.bgSolid)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(theme.bgSolid)
            
            // Confirm button
            VStack {
                Button(action: {
                    onExport(currentDir)
                    dismiss()
                }) {
                    Text("EXPORT TO: \(currentDir.lastPathComponent == "C_Drive" ? "C:\\" : currentDir.lastPathComponent.uppercased())")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accent)
                        .cornerRadius(6)
                        .shadow(color: theme.glow, radius: 4)
                }
                .padding()
            }
            .background(theme.panel)
            .overlay(Rectangle().frame(height: 1).foregroundColor(theme.border), alignment: .top)
        }
        .background(theme.bgSolid.ignoresSafeArea())
    }
    
    private func getCurrentPathDisplay() -> String {
        let rootPath = FileSystemManager.shared.rootDirectory.path
        let subPath = currentDir.path.replacingOccurrences(of: rootPath, with: "")
        return "C:\\" + subPath.replacingOccurrences(of: "/", with: "\\").uppercased()
    }
    
    private func getSubfolders() -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: currentDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        return contents.filter { url in
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
            return isDir.boolValue
        }.sorted { $0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased() }
    }
}
