// DarkOS/InternalFileViewer.swift

import SwiftUI
import AVKit

struct InternalFileViewer: View {
    let fileURL: URL
    var forceTextView: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var textBuffer: String = ""
    @State private var isText = false
    @State private var isImage = false
    @State private var isVideo = false
    @State private var isPDF = false
    @State private var isAudio = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fileURL.lastPathComponent.uppercased())
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                Spacer()
                Button("CLOSE") { dismiss() }
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color(white: 0.05))
            
            Group {
                if isImage {
                    ScrollView([.horizontal, .vertical]) {
                        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                } else if isVideo {
                    VideoPlayer(player: AVPlayer(url: fileURL))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isPDF {
                    PDFKitView(url: fileURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isAudio {
                    AudioPlayerView(url: fileURL)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isText {
                    ScrollView {
                        Text(textBuffer)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.questionmark")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("UNRECOGNIZED FILE TYPE SYSTEM EXTENSION")
                            .font(.system(size: 9.5, design: .monospaced))
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            evaluateAssetType()
        }
    }
    
    private func evaluateAssetType() {
        
        if forceTextView {
            isText = true
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                textBuffer = content
            } else {
                textBuffer = "UNABLE TO READ RAW DATA AS STRING REPRESENTATION."
            }
            return
        }
        
        let ext = fileURL.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "heic"].contains(ext) {
            isImage = true
        } else if ["mp4", "mov", "m4v"].contains(ext) {
            isVideo = true
        } else if ext == "pdf" {
            isPDF = true
        } else if ["mp3", "wav", "m4a"].contains(ext) {
            isAudio = true
        } else {
            isText = true
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                textBuffer = content
            } else {
                textBuffer = "UNABLE TO READ RAW DATA AS STRING REPRESENTATION."
            }
        }
    }
}
