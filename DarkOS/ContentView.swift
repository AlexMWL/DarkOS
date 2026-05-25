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
    
    // Window Drag & Resize Memory Banks
    @State private var minimizedWindows: Set<UUID> = []
    
    // Glitch Framework States
    @State private var isGlitching = false
    private let ciContext = CIContext()
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
                desktopBackground
                
                VStack(spacing: 0) {
                    topHeader
                    
                    GeometryReader { geo in
                        ZStack {
                            desktopGrid
                            
                            ForEach(pm.runningProcesses) { process in
                                WindowNode(process: process, pm: pm, minimizedWindows: $minimizedWindows, desktopSize: geo.size)
                            }
                        }
                    }
                    
                    taskbar
                }
                
                if showStartMenu { startMenuOverlay }
                if showTaskManager { taskManagerOverlay }
                if showSettings { settingsOverlay }
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
    
    private var desktopBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.15, green: 0, blue: 0), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
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
                                            if let outputImage = CIFilter.randomGenerator().outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300)),
                                               let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
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
            }.ignoresSafeArea()
        }
    }
    
    private var topHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("DarkOS by Lex // Desktop")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .red, radius: 2)
                Text("PID_Pool: \(pm.runningProcesses.count) Active Processes  |  RAM Used: \(String(format: "%.1f", pm.currentRamUsage)) MB")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    NotificationCenter.default.post(name: .darkOSToggleTaskManager, object: nil)
                }) {
                    Label("Task Butcher", systemImage: "gauge.with.needle.fill")
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
    }
    
    private var desktopGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85, maximum: 100))], spacing: 25) {
                let builtInApps = ["Browser", "File_Safe", "File_Manager"]
                
                ForEach(builtInApps, id: \.self) { appName in
                    let virtualURL = fs.rootDirectory.appendingPathComponent(appName)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        pm.launchProcess(from: virtualURL)
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
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
    }
    
    private var taskbar: some View {
        HStack(spacing: 12) {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showStartMenu.toggle()
            }) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [.red, Color(red: 0.4, green: 0, blue: 0), .black], center: .center, startRadius: 0, endRadius: 22))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.2))
                        .shadow(color: .red.opacity(showStartMenu ? 0.9 : 0.4), radius: 6)
                    
                    Image(systemName: "command").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                }
            }
            
            Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 26)
            
            HStack(spacing: 8) {
                ForEach(fs.dockShortcuts, id: \.self) { shortcutURL in
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        pm.launchProcess(from: shortcutURL)
                    }) {
                        Image(systemName: shortcutURL.lastPathComponent == "File_Safe" ? "lock.shield.fill" :
                                         (shortcutURL.lastPathComponent == "Browser" ? "globe" :
                                         (shortcutURL.lastPathComponent == "File_Manager" ? "terminal.fill" : "gauge.with.needle.fill")))
                            .font(.system(size: 15)).foregroundColor(.white).frame(width: 36, height: 36)
                            .background(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                            .cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.25), lineWidth: 0.8))
                    }
                }
            }
            
            Spacer()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(pm.runningProcesses) { process in
                        let isActive = pm.activeProcessID == process.id
                        let isMinimized = minimizedWindows.contains(process.id)
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if isMinimized { minimizedWindows.remove(process.id) }
                            pm.activeProcessID = process.id
                        }) {
                            HStack(spacing: 6) {
                                Circle().fill(isActive ? Color.green : (isMinimized ? Color.gray : Color.red)).frame(width: 6, height: 6)
                                Text(process.name).font(.system(size: 11, weight: isActive ? .black : .regular, design: .rounded))
                                    .foregroundColor(isMinimized ? .white.opacity(0.4) : .white)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(isActive ? Color.white.opacity(0.15) : Color.black.opacity(0.2))
                            .cornerRadius(4).overlay(RoundedRectangle(cornerRadius: 4).stroke(isActive ? Color.white.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
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
    
    private var startMenuOverlay: some View {
        ZStack {
            Color.black.opacity(0.001)
                .ignoresSafeArea()
                .onTapGesture {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showStartMenu = false
                }
            
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
    
    private var taskManagerOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "gauge.with.needle.fill").foregroundColor(.white)
                    Text("Task Butcher")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                    Spacer()
                    Button(action: { showTaskManager = false }) {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .black)).foregroundColor(.white).frame(width: 36, height: 20).background(Color.red.opacity(0.85)).cornerRadius(3)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                
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
            .aeroGlassStyle(tint: .red)
        }
        .zIndex(100)
    }
    
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "gearshape.fill").foregroundColor(.white)
                    Text("System Settings")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                    Spacer()
                    Button(action: { showSettings = false }) {
                        Image(systemName: "xmark").font(.system(size: 10, weight: .black)).foregroundColor(.white).frame(width: 36, height: 20).background(Color.red.opacity(0.85)).cornerRadius(3)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                
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
            .aeroGlassStyle(tint: .red)
        }
        .zIndex(101)
    }
}

struct WindowNode: View {
    let process: OSProcess
    @ObservedObject var pm: ProcessManager
    @Binding var minimizedWindows: Set<UUID>
    let desktopSize: CGSize
    
    @State private var currentOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    
    @State private var baseScale: CGFloat = 1.0
    @State private var dragScale: CGFloat = 0.0
    
    @State private var isMaximized: Bool = false
    @State private var isInteracting: Bool = false
    
    var body: some View {
        let isActive = pm.activeProcessID == process.id
        let isMinimized = minimizedWindows.contains(process.id)
        
        let activeOffset = isMaximized ? .zero : CGSize(width: currentOffset.width + dragOffset.width, height: currentOffset.height + dragOffset.height)
        
        let activeWidth = isMaximized ? desktopSize.width : 360
        let activeHeight = isMaximized ? desktopSize.height : 480
        
        let activeScale = isMaximized ? 1.0 : max(0.4, baseScale + dragScale)
        
        let visualWidth = activeWidth * activeScale
        let visualHeight = activeHeight * activeScale
        
        ZStack(alignment: .center) {
            
            VStack(spacing: 0) {
                
                HStack {
                    Image(systemName: process.name == "BROWSER" ? "globe" : (process.name == "FILE_SAFE" ? "lock.shield.fill" : (process.name == "FILE_MANAGER" ? "folder.fill" : "cpu.fill")))
                        .foregroundColor(.white)
                        .shadow(color: .red, radius: 2)
                    
                    Text(process.name.replacingOccurrences(of: "_", with: " "))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 3)
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            minimizedWindows.insert(process.id)
                            if pm.activeProcessID == process.id { pm.activeProcessID = nil }
                        }) {
                            Text("—").font(.system(size: 11, weight: .bold)).foregroundColor(.white).frame(width: 26, height: 20).background(Color.white.opacity(0.15)).cornerRadius(3)
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isMaximized.toggle()
                            }
                        }) {
                            Image(systemName: isMaximized ? "square.on.square" : "square")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 26, height: 20)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(3)
                        }
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            pm.terminateProcess(id: process.id)
                            minimizedWindows.remove(process.id)
                        }) {
                            Image(systemName: "xmark").font(.system(size: 10, weight: .black)).foregroundColor(.white).frame(width: 38, height: 20).background(Color.red.opacity(0.85)).cornerRadius(3).shadow(color: .red, radius: 4)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(isActive ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.15)), alignment: .bottom)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isInteracting = true
                            if pm.activeProcessID != process.id { pm.activeProcessID = process.id }
                            if isMaximized { isMaximized = false }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isInteracting = false
                            currentOffset = CGSize(width: currentOffset.width + value.translation.width, height: currentOffset.height + value.translation.height)
                            dragOffset = .zero
                        }
                )
                
                Group {
                    if process.name == "BROWSER" {
                        BrowserView(isPresented: Binding(
                            get: { pm.activeProcessID == process.id },
                            set: { if !$0 { pm.activeProcessID = nil } }
                        ))
                    } else if process.name == "FILE_SAFE" {
                        LockerView().background(Color.black)
                    } else if process.name == "FILE_MANAGER" {
                        FileManagerView(isPresented: Binding(
                            get: { true },
                            set: { if !$0 { pm.terminateProcess(id: process.id) } }
                        ))
                        .background(Color.black)
                    } else {
                        OSWebViewWrapper(webView: process.webView)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(Color.white.opacity(isInteracting ? 0.001 : 0))
                .clipped()
                .allowsHitTesting(isActive)
            }
            .frame(width: activeWidth, height: activeHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aeroGlassStyle(tint: isActive ? .red : .black)
            .scaleEffect(activeScale)
            
            if !isMaximized {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(14)
                            .background(Color.white.opacity(0.001))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isInteracting = true
                                        if pm.activeProcessID != process.id { pm.activeProcessID = process.id }
                                        
                                        let dragDistance = (value.translation.width * 0.6) + (value.translation.height * 0.8)
                                        dragScale = dragDistance / 600.0
                                    }
                                    .onEnded { value in
                                        isInteracting = false
                                        let dragDistance = (value.translation.width * 0.6) + (value.translation.height * 0.8)
                                        baseScale = max(0.4, baseScale + (dragDistance / 600.0))
                                        dragScale = .zero
                                    }
                            )
                    }
                }
            }
        }
        .frame(width: visualWidth, height: visualHeight)
        .offset(activeOffset)
        .zIndex(isActive ? 100 : Double(pm.runningProcesses.firstIndex(where: { $0.id == process.id }) ?? 0))
        .opacity(isMinimized ? 0.0 : 1.0)
        .scaleEffect(isMinimized ? 0.8 : 1.0)
        .allowsHitTesting(!isMinimized)
        .onTapGesture {
            if !isActive {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                pm.activeProcessID = process.id
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isMinimized)
    }
}
