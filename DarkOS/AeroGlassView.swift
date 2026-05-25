// DarkOS/AeroGlassView.swift

import SwiftUI

struct AeroGlassModifier: ViewModifier {
    var tintColor: Color
    @ObservedObject var theme = ThemeManager.shared
    
    func body(content: Content) -> some View {
        let isLight = theme.isLightTheme
        
        content
            .background(.ultraThinMaterial.opacity(isLight ? 0.85 : 0.65))
            .background(
                LinearGradient(
                    colors: [tintColor.opacity(isLight ? 0.15 : 0.25), theme.bgSolid.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [theme.text.opacity(0.4), .clear, tintColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .cornerRadius(12)
            .shadow(color: theme.shadow, radius: 10, x: 0, y: 5)
    }
}

extension View {
    func aeroGlassStyle(tint: Color) -> some View {
        self.modifier(AeroGlassModifier(tintColor: tint))
    }
}
