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
    @State private var showSettings = false
    
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
            // High-end Red/Black Gradient Wallpaper simulating a real desktop background canvas
            LinearGradient(
                colors: [Color(red: 0.15, green: 0, blue: 0), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background Digital Matrix / Grid lines
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    Path { path in
                        let step: CGFloat = 40
                        for x in stride(from: 0, to: geo.size.width, by: step) {
                            path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        }
                        for y in stride(from: 0, to: geo.size.height, by: step) {
                            path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                    }
                    .stroke(Color.red.opacity(0.03), lineWidth: 1)
                    
                    if isGlitching {
                        let context = CIContext()
                        if let outputImage = CIFilter.randomGenerator().outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300)),
                           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                            Image(uiImage: UIImage(cgImage: cgImage))
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Double.random(in: 0...1) > 0.3 ? .white : .red)
                                .blendMode(.screen)
                                .opacity(Double.random(in: 0.1...0.3))
                                .frame(width: geo.size.width, height: Double.random(in: 0...1) > 0.7 ? geo.size.height : CGFloat.random(in: 20...120))
                                .offset(y: glitchYOffset)
                        }
                    }
                }
                .onReceive(glitchTimer) { _ in
                    if Double.random(in: 0...1) < 0.45 {
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
                // --- TOP AERO HEADER PANEL WIDGET ---
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("DARKOS MULTI-KERNEL // DESKTOP")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .red, radius: 2)
                        Text("PID_POOL: \(pm.runningProcesses.count) Active Processes  |  RAM: \(String(format: "%.1f", pm.currentRamUsage)) MB")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    
                    // --- UPDATE BOTH BUTTONS INSIDE YOUR TOP AERO HEADER PANEL ---
                    HStack(spacing: 12) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            // FIXED: Reverted targeting back to the system notification trigger ID
                            NotificationCenter.default.post(name: .darkOSToggleTaskManager, object: nil)
                        }) {
                            Label("Task Manager", systemImage: "gauge.with.needle.fill")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.white.opacity(0.12))
                                .cornerRadius(4)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            // RE-WIRED to trigger our new settings panel!
                            showSettings.toggle()
                        }) {
                            Image(systemName: "folder.badge.gearshape")
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial.opacity(0.4))
                .border(Color.white.opacity(0.1), width: 0.5)
                .padding([.horizontal, .top], 10)
                
                // --- MAIN DESKTOP SHORTCUT GRID LAYER ---
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 85, maximum: 100))], spacing: 25) {
                        // Standard hardcoded application entries to mimic built-in shortcuts
                        let builtInApps = ["Browser", "File_Safe", "File_Manager"]
                        
                        ForEach(builtInApps, id: \.self) { appName in
                            let virtualURL = fs.rootDirectory.appendingPathComponent(appName)
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                pm.launchProcess(from: virtualURL)
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        // Win7 style reflective backdrop
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 52, height: 52)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.8))
                                            .shadow(color: .black.opacity(0.3), radius: 3)
                                        
                                        Image(systemName: appName == "File_Safe" ? "lock.shield.fill" :
                                                         (appName == "Browser" ? "globe" :
                                                         (appName == "File_Manager" ? "terminal.fill" : "gauge.with.needle.fill")))
                                        .font(.title2)
                                        .foregroundColor(appName == "File_Safe" ? .green : .red)
                                    }
                                    
                                    Text(appName.replacingOccurrences(of: "_", with: " ").uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 4)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
                        // Custom deployed files on user's workspace layer
                        ForEach(fs.desktopShortcuts, id: \.self) { appURL in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                pm.launchProcess(from: appURL)
                            }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(colors: [.red.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 52, height: 52)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 0.8))
                                        
                                        Image(systemName: "bolt.shield.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    Text(appURL.deletingPathExtension().lastPathComponent.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 4)
                                        .lineLimit(1)
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive, action: { fs.removeDesktopShortcut(url: appURL) }) {
                                    Label("Unpin Asset", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // --- ICONIC GLASS TASKBAR ---
                HStack(spacing: 12) {
                    // Start Orb Button (Classic Win7 Style Circle layout)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showStartMenu.toggle()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.red, Color(red: 0.4, green: 0, blue: 0), .black],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 22
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.2))
                                .shadow(color: .red.opacity(showStartMenu ? 0.9 : 0.4), radius: 6)
                            
                            Image(systemName: "command")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1, height: 26)
                    
                    // Quick Launch pinning strip
                    HStack(spacing: 8) {
                        ForEach(fs.dockShortcuts, id: \.self) { shortcutURL in
                            Button(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                pm.launchProcess(from: shortcutURL)
                            }) {
                                Image(systemName: shortcutURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                                 (shortcutURL.lastPathComponent == "Browser" ? "globe" :
                                                 (shortcutURL.lastPathComponent == "File_Manager" ? "terminal.fill" : "gauge.with.needle.fill")))
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                                    .cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Active Window running state pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(pm.runningProcesses) { process in
                                let isActive = pm.activeProcessID == process.id
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    pm.activeProcessID = process.id
                                }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(isActive ? Color.green : Color.red)
                                            .frame(width: 6, height: 6)
                                        Text(process.name)
                                            .font(.system(size: 11, weight: isActive ? .black : .regular, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isActive ? Color.white.opacity(0.15) : Color.black.opacity(0.2))
                                    .cornerRadius(4)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial.opacity(0.95))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.25)), alignment: .top)
            }
            
            // --- FULL AERO APPLICATION MULTI-WINDOW COMPILER ENGINE ---
            ForEach(pm.runningProcesses) { process in
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea() // Translucent system layer backdrop reveal
                    
                    VStack(spacing: 0) {
                        // Title bar core element
                        HStack {
                            Image(systemName: process.name == "BROWSER" ? "globe" : (process.name == "FILE_SAFE" ? "lock.shield.fill" : "cpu.fill"))
                                .foregroundColor(.white)
                                .shadow(color: .red, radius: 2)
                            
                            Text(process.name.replacingOccurrences(of: "_", with: " "))
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black, radius: 3)
                            
                            Spacer()
                            
                            // Classic Windows action window matrix
                            HStack(spacing: 8) {
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    pm.activeProcessID = nil
                                }) {
                                    Text("—")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 20)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(3)
                                }
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    pm.terminateProcess(id: process.id)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.white)
                                        .frame(width: 38, height: 20)
                                        .background(Color.red.opacity(0.85))
                                        .cornerRadius(3)
                                        .shadow(color: .red, radius: 4)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                        
                        // Internal app viewport content container
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
                    .padding(.top, 25)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 70)
                    .aeroGlassStyle(tint: .red) // Inject frosted layout modifier template globally
                }
                .opacity(pm.activeProcessID == process.id ? 1.0 : 0.0)
                .allowsHitTesting(pm.activeProcessID == process.id)
                .animation(.easeOut(duration: 0.18), value: pm.activeProcessID)
            }
            
            // --- THE START MENU APPS PANEL OVERLAY ---
            // --- THE START MENU APPS PANEL OVERLAY ---
                        if showStartMenu {
                            ZStack {
                                // 1. The invisible "wall" that catches your taps outside the menu!
                                Color.black.opacity(0.001)
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        showStartMenu = false
                                    }
                                
                                // 2. The actual Start Menu UI
                                VStack {
                                    Spacer()
                                    HStack {
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("🔴 PROGRAMS REGISTER INDEX")
                                                .font(.system(size: 11, weight: .black, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(12)
                                                .background(Color.red.opacity(0.75))
                                            
                                            ScrollView {
                                                VStack(spacing: 2) {
                                                    ForEach(fs.installedApps, id: \.self) { appURL in
                                                        if appURL.lastPathComponent != "Browser.html" {
                                                            Button(action: {
                                                                pm.launchProcess(from: appURL)
                                                                showStartMenu = false
                                                            }) {
                                                                HStack(spacing: 12) {
                                                                    Image(systemName: appURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                                                                     (appURL.lastPathComponent == "Browser" ? "globe" :
                                                                                     (appURL.lastPathComponent == "File_Manager" ? "terminal.fill" : "gauge.with.needle.fill")))
                                                                    .foregroundColor(.red)
                                                                    .frame(width: 18)
                                                                    
                                                                    Text(appURL.deletingPathExtension().lastPathComponent.uppercased())
                                                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                                        .foregroundColor(.white)
                                                                    Spacer()
                                                                }
                                                                .padding(.vertical, 12)
                                                                .padding(.horizontal, 14)
                                                                .background(Color.white.opacity(0.04))
                                                                .cornerRadius(4)
                                                            }
                                                        }
                                                    }
                                                }
                                                .padding(8)
                                            }
                                            .frame(height: 250)
                                            .background(Color.black.opacity(0.4))
                                        }
                                        .frame(width: 280)
                                        .aeroGlassStyle(tint: .black)
                                        .padding(.leading, 12)
                                        .padding(.bottom, 68)
                                        Spacer()
                                    }
                                }
                            }
                        }
            if showFileManager {
                            FileManagerView(isPresented: $showFileManager)
                                .transition(.opacity)
                                .zIndex(99)
                        }
                        
                        // --- FLOATING AERO TASK MANAGER ---
                        if showTaskManager {
                            ZStack {
                                Color.black.opacity(0.4).ignoresSafeArea() // Dims the background slightly
                                
                                VStack(spacing: 0) {
                                    // Task Manager Title Bar
                                    HStack {
                                        Image(systemName: "gauge.with.needle.fill").foregroundColor(.white)
                                        Text("Task Manager")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 2)
                                        Spacer()
                                        Button(action: { showTaskManager = false }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 20)
                                                .background(Color.red.opacity(0.85))
                                                .cornerRadius(3)
                                        }
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Color.white.opacity(0.08))
                                    .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                                    
                                    // Task Manager List Core
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text("PROCESS").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.red.opacity(0.8)).frame(maxWidth: .infinity, alignment: .leading)
                                            Text("VIRT_RAM").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.red.opacity(0.8)).frame(width: 80, alignment: .center)
                                            Text("ACTION").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(.red.opacity(0.8)).frame(width: 90, alignment: .trailing)
                                        }
                                        .padding(.horizontal, 16).padding(.vertical, 10)
                                        .background(Color.black.opacity(0.3))
                                        
                                        if pm.runningProcesses.isEmpty {
                                            Text("NO CONCURRENT THREADS DETECTED.")
                                                .font(.system(size: 11, design: .monospaced)).foregroundColor(.gray)
                                                .padding()
                                        } else {
                                            ScrollView {
                                                VStack(spacing: 6) {
                                                    ForEach(pm.runningProcesses) { process in
                                                        HStack {
                                                            Text(process.name).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
                                                            Text("\(String(format: "%.1f", process.ramUsage)) MB").font(.system(size: 11, design: .monospaced)).foregroundColor(.white).frame(width: 80, alignment: .center)
                                                            Button(action: {
                                                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                                                pm.terminateProcess(id: process.id)
                                                            }) {
                                                                Text("KILL").font(.system(size: 10, weight: .black, design: .monospaced)).foregroundColor(.black).padding(.horizontal, 12).padding(.vertical, 6).background(Color.red).cornerRadius(3)
                                                            }
                                                            .frame(width: 90, alignment: .trailing)
                                                        }
                                                        .padding(.vertical, 8).padding(.horizontal, 12)
                                                        .background(Color.white.opacity(0.04))
                                                        .cornerRadius(4)
                                                    }
                                                }
                                                .padding(8)
                                            }
                                        }
                                        Spacer()
                                    }
                                    .background(Color.black.opacity(0.5))
                                }
                                .frame(width: 360, height: 420)
                                .aeroGlassStyle(tint: .red) // Boom. Frosted glass panel.
                            }
                            .zIndex(100)
                        }
            if showSettings {
                            ZStack {
                                Color.black.opacity(0.4).ignoresSafeArea() // Dims the background
                                
                                VStack(spacing: 0) {
                                    // Settings Title Bar
                                    HStack {
                                        Image(systemName: "gearshape.fill").foregroundColor(.white)
                                        Text("System Settings")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .shadow(color: .black, radius: 2)
                                        Spacer()
                                        Button(action: { showSettings = false }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 10, weight: .black))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 20)
                                                .background(Color.red.opacity(0.85))
                                                .cornerRadius(3)
                                        }
                                    }
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(Color.white.opacity(0.08))
                                    .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                                    
                                    // Settings Content Placeholder
                                    VStack {
                                        Spacer()
                                        Image(systemName: "wrench.and.screwdriver.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.white.opacity(0.3))
                                            .padding(.bottom, 8)
                                        
                                        Text("Placeholder for settings.")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.5))
                                }
                                .frame(width: 320, height: 380)
                                .aeroGlassStyle(tint: .red) // Keeps that premium glass aesthetic
                            }
                            .zIndex(101) // Ensures it floats over everything else
                        }
                } // <--- THIS IS THE END OF YOUR MAIN ZSTACK
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
