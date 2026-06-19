// DarkOS/AudioPlayerView.swift

import SwiftUI
import AVKit

struct AudioPlayerView: View {
    let url: URL
    let theme = ThemeManager.shared
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            
            Image(systemName: "music.note")
                .font(.system(size: 22.5))
                .foregroundColor(theme.accent)
                .shadow(color: theme.glow, radius: 4)
            
            Text(url.lastPathComponent.uppercased())
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(theme.text)
                .lineLimit(1)
                .padding(.horizontal, 12)
            
            HStack(spacing: 20) {
                Button(action: togglePlay) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 26.5))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: stopPlayback) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 26.5))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.panelDeep)
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func togglePlay() {
        if player == nil {
            player = AVPlayer(url: url)
        }
        
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }
    
    private func stopPlayback() {
        player?.pause()
        player = nil
        isPlaying = false
    }
}
