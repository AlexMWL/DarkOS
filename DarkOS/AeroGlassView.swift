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
            .background(.ultraThinMaterial.opacity(0.65))
            .background(
                LinearGradient(
                    colors: [tintColor.opacity(0.25), Color.black.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
            .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func aeroGlassStyle(tint: Color = .red) -> some View {
        self.modifier(AeroGlassModifier(tintColor: tint))
    }
}
