// DarkOS/ThemeManager.swift

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isLightTheme: Bool = UserDefaults.standard.bool(forKey: "isLightTheme") {
        didSet {
            UserDefaults.standard.set(isLightTheme, forKey: "isLightTheme")
        }
    }
    
        @Published var showDiagnostics: Bool = UserDefaults.standard.object(forKey: "showDiagnostics") as? Bool ?? true {
            didSet {
                UserDefaults.standard.set(showDiagnostics, forKey: "showDiagnostics")
            }
        }
    
    @Published var showDesktopLabels: Bool = UserDefaults.standard.object(forKey: "showDesktopLabels") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(showDesktopLabels, forKey: "showDesktopLabels")
        }
    }
    
    var bgSolid: Color { isLightTheme ? .white : .black }
    var bgGradientStart: Color { isLightTheme ? Color(red: 0.85, green: 0.95, blue: 1.0) : Color(red: 0.15, green: 0, blue: 0) }
    
    var accent: Color { isLightTheme ? .blue : .red }
    var text: Color { isLightTheme ? .black : .white }
    var textMuted: Color { isLightTheme ? .black.opacity(0.6) : .white.opacity(0.7) }
    
    var panel: Color { isLightTheme ? .black.opacity(0.05) : .white.opacity(0.12) }
    var panelDeep: Color { isLightTheme ? .white.opacity(0.8) : .black.opacity(0.4) }
    var border: Color { isLightTheme ? .black.opacity(0.1) : .white.opacity(0.15) }
    
    var shadow: Color { isLightTheme ? .black.opacity(0.15) : .black.opacity(0.8) }
    var glow: Color { isLightTheme ? .blue.opacity(0.3) : .red.opacity(0.4) }
}
