import SwiftUI
import UniformTypeIdentifiers
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @StateObject private var fs = FileSystemManager.shared
    @StateObject private var pm = ProcessManager.shared
    
    // UI Panel Toggles
    @State private var showStartMenu = false
    @State private var showFileManager = false
    @State private var showTaskManager = false
    
    // Glitch Framework States
    @State private var isGlitching = false
    @State private var glitchYOffset: CGFloat = 0.0
    private let glitchTimer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()
    
    // Deployment States
    @State private var webURLString = ""
    @State private var downloadName = ""
    @State private var showLocalFilePicker = false
    @State private var installAlertMessage = ""
    @State private var showInstallAlert = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Path { path in
                        let step: CGFloat = 30
                        for x in stride(from: 0, to: geo.size.width, by: step) {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        for y in stride(from: 0, to: geo.size.height, by: step) {
                            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                    }
                    .stroke(Color.red.opacity(0.04), lineWidth: 1)
                    
                    if isGlitching {
                        let context = CIContext()
                        if let outputImage = CIFilter.randomGenerator().outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300)),
                           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                            Image(uiImage: UIImage(cgImage: cgImage))
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Double.random(in: 0...1) > 0.3 ? .white : .red)
                                .blendMode(.screen)
                                .opacity(Double.random(in: 0.15...0.45))
                                .frame(width: geo.size.width, height: Double.random(in: 0...1) > 0.7 ? geo.size.height : CGFloat.random(in: 20...120))
                                .offset(y: glitchYOffset)
                        }
                    }
                }
                .onReceive(glitchTimer) { _ in
                    if Double.random(in: 0...1) < 0.55 {
                        glitchYOffset = CGFloat.random(in: 0...(geo.size.height - 150))
                        isGlitching = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.04...0.12)) {
                            isGlitching = false
                        }
                    }
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Status Header Panel
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DARKOS MULTI-KERNEL // POOL_ACTIVE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .shadow(color: .red.opacity(0.8), radius: 4)
                        Text("ACTIVE_THREADS: \(pm.runningProcesses.count) // MEM_CONSUMED: \(String(format: "%.1f", pm.currentRamUsage)) MB")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    Spacer()
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        showTaskManager.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.needle.fill")
                            Text("TASK_MGR")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.vertical, 6).padding(.horizontal, 10)
                        .background(Color.red.opacity(0.1))
                        .border(Color.red.opacity(0.4), width: 1)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showFileManager.toggle()
                    }) {
                        Image(systemName: "terminal.fill").font(.title3).foregroundColor(.red).padding(.leading, 10)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(Color.black.opacity(0.9))
                
                // USER PROGRAM DECK CONTEXT INDEX
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 95, maximum: 110))], spacing: 25) {
                        if fs.desktopShortcuts.isEmpty {
                            Text("DESKTOP SECURE LAYER EMPTY.\nLAUNCH START_MGR TO PIN APPLICATION NODES.")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.red.opacity(0.2))
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(fs.desktopShortcuts, id: \.self) { appURL in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    pm.launchProcess(from: appURL)
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12).fill(Color.black)
                                                .frame(width: 60, height: 60)
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1.5))
                                            
                                            Image(systemName: appURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                                             (appURL.lastPathComponent == "Browser" ? "globe" :
                                                             (appURL.lastPathComponent == "File_Manager" ? "terminal.fill" :
                                                             (appURL.lastPathComponent == "Task_Manager" ? "gauge.with.needle.fill" : "bolt.shield.fill"))))
                                            .font(.title3).foregroundColor(.red)
                                        }
                                        Text(appURL.deletingPathExtension().lastPathComponent.uppercased())
                                            .font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundColor(.white).lineLimit(1)
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive, action: { fs.removeDesktopShortcut(url: appURL) }) {
                                        Label("Unpin from Desktop", systemImage: "trash")
                                    }
                                    if !fs.dockShortcuts.contains(appURL) {
                                        Button(action: { fs.addDockShortcut(url: appURL) }) {
                                            Label("Pin to Core Dock", systemImage: "pin.fill")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 25).padding(.horizontal, 20)
                }
                
                Spacer()
                
                // BOTTOM DOCK SHORTCUT LAYOUT STRIP
                // --- NEW WIN7 AERO TASKBAR BAR LAYOUT DECK ---
                HStack(spacing: 12) {
                    // Round Start Orb Button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showStartMenu.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.red, Color(red: 0.3, green: 0, blue: 0)],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 22
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .shadow(color: .red.opacity(0.6), radius: showStartMenu ? 8 : 3)
                            
                            Image(systemName: "command")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.leading, 6)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 1, height: 28)
                    
                    // Quick Launch Shortcut Icons Layout Panel
                    HStack(spacing: 8) {
                        ForEach(fs.dockShortcuts, id: \.self) { shortcutURL in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                pm.launchProcess(from: shortcutURL)
                            }) {
                                Image(systemName: shortcutURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                                 (shortcutURL.lastPathComponent == "Browser" ? "globe" :
                                                 (shortcutURL.lastPathComponent == "File_Manager" ? "terminal.fill" :
                                                 (shortcutURL.lastPathComponent == "Task_Manager" ? "gauge.with.needle.fill" : "bolt.shield.fill"))))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    // Shiny backdrop hover effect
                                    .background(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                                    .cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Open Active Window Tab Rows
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(pm.runningProcesses) { process in
                                let isActive = pm.activeProcessID == process.id
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    pm.activeProcessID = process.id
                                }) {
                                    Text(process.name)
                                        .font(.system(size: 11, weight: isActive ? .bold : .regular, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        // Active apps look highlighted and lit up in the taskbar stack
                                        .background(isActive ? Color.red.opacity(0.4) : Color.white.opacity(0.06))
                                        .cornerRadius(4)
                                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(isActive ? Color.red : Color.white.opacity(0.15), lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                // Gives the bottom ribbon dock a distinct sleek background blend border layer
                .background(.ultraThinMaterial)
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.2)), alignment: .top)
                .padding(8).background(Color.black.opacity(0.95))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.red.opacity(0.3)), alignment: .top)
            }
            
            // MULTITASKING APPLICATION WINDOW RENDER CORES
            // Locate where you loop through running processes inside ContentView.swift:
            ForEach(pm.runningProcesses) { process in
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea() // Gives a translucent reveal behind windows
                    
                    VStack(spacing: 0) {
                        // --- NEW AERO GLOSS WINDOW TITLEBAR ---
                        HStack {
                            Image(systemName: process.name == "BROWSER" ? "globe" : "cpu.fill")
                                .foregroundColor(.white)
                                .shadow(color: .red, radius: 2)
                            
                            Text(process.name)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                // Windows 7 style text shadow aura
                                .shadow(color: .black, radius: 3)
                            
                            Spacer()
                            
                            // Classic Windows 7 rounded button cluster
                            HStack(spacing: 6) {
                                // Minimize
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    pm.activeProcessID = nil
                                }) {
                                    Text("—")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 26, height: 18)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(3)
                                }
                                
                                // Close / Terminate Button (Glows brighter bright red on hover/tap)
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    pm.terminateProcess(id: process.id)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 18)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(3)
                                        .shadow(color: .red, radius: 4)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        // Adds the frosted glass look exclusively onto the titlebar frame
                        .background(.thinMaterial.opacity(0.7))
                        
                        // Sub-window core runtime view
                        Group {
                            if process.name == "BROWSER" {
                                BrowserView(isPresented: Binding(
                                    get: { pm.activeProcessID == process.id },
                                    set: { if !$0 { pm.activeProcessID = nil } }
                                ))
                            } else if process.name == "FILE_SAFE" {
                                LockerView().background(Color.black)
                            } else {
                                OSWebViewWrapper(webView: process.webView)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 20) // Margins to simulate desktop padding borders
                    .padding(.horizontal, 10)
                    .padding(.bottom, 60)
                    // Inject the modifier here to turn the entire canvas envelope into an Aero-frame!
                    .aeroGlassStyle(tint: .red)
                }
                .opacity(pm.activeProcessID == process.id ? 1.0 : 0.0)
                .allowsHitTesting(pm.activeProcessID == process.id)
                .animation(.easeOut(duration: 0.15), value: pm.activeProcessID)
            }
            
            // SYSTEM TASK MANAGER PANEL OVERLAY
            if showTaskManager {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing: 0) {
                        HStack {
                            Text("⚙️ DARKOS KERNEL TASK MANAGER")
                                .font(.system(size: 12, weight: .black, design: .monospaced)).foregroundColor(.red)
                            Spacer()
                            Button("MINIMIZE") { showTaskManager = false }
                                .font(.system(size: 11, design: .monospaced)).foregroundColor(.white)
                        }
                        .padding().background(Color.red.opacity(0.15))
                        
                        HStack {
                            Text("PROCESS STRING")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.red.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("VIRT_RAM")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.red.opacity(0.5))
                                .frame(width: 80, alignment: .center)
                            
                            Text("ACTION")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.red.opacity(0.5))
                                .frame(width: 90, alignment: .trailing)
                        }
                        .padding(.horizontal, 16).padding(.top, 15).padding(.bottom, 8)
                        
                        Rectangle().fill(Color.red.opacity(0.3)).frame(height: 1).padding(.horizontal, 16)
                        
                        if pm.runningProcesses.isEmpty {
                            Text("NO THREAD CONCURRENCY DETECTED.")
                                .font(.system(size: 11, design: .monospaced)).foregroundColor(.white.opacity(0.4))
                                .padding()
                        } else {
                            ScrollView {
                                VStack(spacing: 6) {
                                    ForEach(pm.runningProcesses) { process in
                                        HStack(alignment: .center) {
                                            Text(process.name)
                                                .font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
                                            
                                            Text("\(String(format: "%.1f", process.ramUsage)) MB")
                                                .font(.system(size: 11, design: .monospaced)).foregroundColor(.green)
                                                .frame(width: 80, alignment: .center)
                                            
                                            Button(action: {
                                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                                pm.terminateProcess(id: process.id)
                                            }) {
                                                Text("KILL_PROC")
                                                    .font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.black)
                                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                                    .background(Color.red).cornerRadius(2)
                                            }
                                            .frame(width: 90, alignment: .trailing)
                                        }
                                        .padding(.vertical, 10).padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.02))
                                        .border(Color.red.opacity(0.1), width: 1)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.top, 8)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: 380, height: 460)
                    .background(Color(white: 0.04)).border(Color.red, width: 2)
                    .shadow(color: .red.opacity(0.3), radius: 20)
                }
            }
            
            // THE START MENU APP REPOSITORY GRID
            if showStartMenu {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("🔴 SYSTEM APPLICATIONS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.red.opacity(0.6))
                            
                            ScrollView {
                                VStack(spacing: 2) {
                                    ForEach(fs.installedApps, id: \.self) { appURL in
                                        if appURL.lastPathComponent != "Browser.html" {
                                            HStack {
                                                Button(action: {
                                                    pm.launchProcess(from: appURL)
                                                    showStartMenu = false
                                                }) {
                                                    HStack(spacing: 10) {
                                                        Image(systemName: appURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                                                         (appURL.lastPathComponent == "Browser" ? "globe" :
                                                                         (appURL.lastPathComponent == "File_Manager" ? "terminal.fill" :
                                                                         (appURL.lastPathComponent == "Task_Manager" ? "gauge.with.needle.fill" : "terminal"))))
                                                        .foregroundColor(.red)
                                                        
                                                        Text(appURL.deletingPathExtension().lastPathComponent.uppercased())
                                                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 14)
                                            .background(Color.black.opacity(0.2))
                                        }
                                    }
                                }
                            }
                            .frame(height: 260)
                        }
                        .frame(width: 290)
                        // Apply our beautiful new Aero frosted effect here!
                        .aeroGlassStyle(tint: .black)
                        .padding(.leading, 10)
                        .padding(.bottom, 68) // Perfectly aligns right above the new Taskbar ring height
                        
                        Spacer()
                    }
                }
                .background(Color.clear.onTapGesture { showStartMenu = false })
            }
            
            if showFileManager {
                FileManagerView(isPresented: $showFileManager)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .darkOSToggleFileManager)) { _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showFileManager.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: .darkOSToggleTaskManager)) { _ in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            showTaskManager.toggle()
        }
        .alert(installAlertMessage, isPresented: $showInstallAlert) {
            Button("ACKNOWLEDGE", role: .cancel) { }
        }
    }
}
