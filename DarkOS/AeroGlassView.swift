//
//  AeroGlassView.swift
//  DarkOS
//
//  Created by DiscoTots on 5/22/26.
//

import SwiftUI

struct AeroGlassModifier: ViewModifier {
    var tintColor: Color = Color.red
    
    func body(content: Content) -> some View {
        content
            // 1. Frosted overlay using built-in system materials
            .background(.ultraThinMaterial.opacity(0.65))
            // 2. Linear gradient to simulate reflection light hit from top-left
            .background(
                LinearGradient(
                    colors: [
                        tintColor.opacity(0.25),
                        Color.black.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // 3. Crisp highlight border around the window frame
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear, tintColor.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .cornerRadius(12)
            // 4. Subtle drop shadow to lift the window off the grid wallpaper
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func aeroGlassStyle(tint: Color = .red) -> some View {
        self.modifier(AeroGlassModifier(tintColor: tint))
    }
}
