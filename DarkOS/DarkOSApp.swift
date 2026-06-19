// DarkOS/DarkOSApp.swift

import SwiftUI
import AVFoundation

@main
struct DarkOSApp: App {
    init() {
        configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            print("AVAudioSession configured successfully for background playback.")
        } catch {
            print("Failed to set AVAudioSession category: \(error.localizedDescription)")
        }
    }
}
