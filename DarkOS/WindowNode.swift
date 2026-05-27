// DarkOS/WindowNode.swift

import SwiftUI

struct WindowNode: View {
    let process: OSProcess
    @ObservedObject var pm: ProcessManager
    @Binding var minimizedWindows: Set<UUID>
    let desktopSize: CGSize
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var currentOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    @State private var baseScale: CGFloat = 1.0
    @GestureState private var dragScale: CGFloat = 0.0
    
    @State private var isMaximized: Bool = false
    @State private var isInteracting: Bool = false
    
    var body: some View {
        let isActive = pm.activeProcessID == process.id
        let isMinimized = minimizedWindows.contains(process.id)
        
        let activeOffset = isMaximized ? .zero : CGSize(width: currentOffset.width + dragOffset.width, height: currentOffset.height + dragOffset.height)
        let activeScale = isMaximized ? 1.0 : max(0.4, baseScale + dragScale)
        
        // Calculate visual dimensions
        let baseW = isMaximized ? desktopSize.width : 360.0
        let baseH = isMaximized ? desktopSize.height : 480.0
        
        ZStack {
            // THE FIX: The entire ZStack is scaled as one unit, pinning the handle to the frame
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    windowHeader(isActive: isActive)
                    windowContent(isActive: isActive)
                }
                .frame(width: baseW, height: baseH)
                
                if !isMaximized { resizeHandle }
            }
            .aeroGlassStyle(tint: isActive ? theme.accent : theme.bgSolid)
            .scaleEffect(activeScale)
            .frame(width: baseW * activeScale, height: baseH * activeScale)
        }
        .offset(activeOffset)
        .zIndex(isActive ? 100 : 0)
        .opacity(isMinimized ? 0.0 : 1.0)
        .allowsHitTesting(!isMinimized)
        .onTapGesture { if !isActive { pm.activeProcessID = process.id } }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isMinimized)
    }

    private func windowHeader(isActive: Bool) -> some View {
        HStack {
            Image(systemName: process.name == "BROWSER" ? "globe" : (process.name == "FILE_SAFE" ? "lock.shield.fill" : (process.name == "FILE_MANAGER" ? "folder.fill" : "cpu.fill")))
                .foregroundColor(theme.text).shadow(color: theme.glow, radius: 2)
            Text(process.name.replacingOccurrences(of: "_", with: " "))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(theme.text).shadow(color: theme.shadow, radius: 3)
            Spacer()
            HStack(spacing: 8) {
                Button(action: { minimizedWindows.insert(process.id); if pm.activeProcessID == process.id { pm.activeProcessID = nil } }) {
                    Text("—").font(.system(size: 11, weight: .bold)).foregroundColor(theme.text).frame(width: 26, height: 20).background(theme.panel).cornerRadius(3)
                }
                Button(action: { withAnimation(.spring()) { isMaximized.toggle() } }) {
                    Image(systemName: isMaximized ? "square.on.square" : "square").font(.system(size: 10, weight: .bold)).foregroundColor(theme.text).frame(width: 26, height: 20).background(theme.panel).cornerRadius(3)
                }
                Button(action: { pm.terminateProcess(id: process.id); minimizedWindows.remove(process.id) }) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .black)).foregroundColor(.white).frame(width: 38, height: 20).background(theme.accent.opacity(0.85)).cornerRadius(3)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(isActive ? theme.panel : theme.panel.opacity(0.5))
        .overlay(Rectangle().frame(height: 1).foregroundColor(theme.border), alignment: .bottom)
        .contentShape(Rectangle())
        .gesture(DragGesture(coordinateSpace: .named("desktop"))
            .updating($dragOffset) { value, state, _ in state = value.translation }
            .onEnded { value in currentOffset = CGSize(width: currentOffset.width + value.translation.width, height: currentOffset.height + value.translation.height) }
        )
    }
    
    @ViewBuilder
    private func windowContent(isActive: Bool) -> some View {
        Group {
            if process.name == "BROWSER" { BrowserView(isPresented: .constant(true)) }
            else if process.name == "FILE_SAFE" { LockerView() }
            else if process.name == "FILE_MANAGER" { FileManagerView(isPresented: .constant(true)) }
            else { OSWebViewWrapper(webView: process.webView) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .allowsHitTesting(isActive)
    }
    
    private var resizeHandle: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 12, weight: .black))
            .foregroundColor(theme.text.opacity(0.6))
            .padding(14)
            .background(Color.white.opacity(0.001))
            .gesture(DragGesture(coordinateSpace: .named("desktop"))
                .updating($dragScale) { value, state, _ in
                    let dragDistance = (value.translation.width * 0.6) + (value.translation.height * 0.8)
                    state = dragDistance / 600.0
                }
                .onEnded { value in
                    let dragDistance = (value.translation.width * 0.6) + (value.translation.height * 0.8)
                    baseScale = max(0.4, baseScale + (dragDistance / 600.0))
                }
            )
    }
}
