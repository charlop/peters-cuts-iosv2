//
//  GlassCard.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Reusable glass effect component with iOS 26 compatibility
//

import SwiftUI

/// Extension to apply glass effects with backward compatibility
extension View {
    /// Apply Liquid Glass effect on iOS 26+, fallback to ultraThinMaterial on iOS 18-25
    @ViewBuilder
    func glassBackground() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular)
        } else {
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Apply glass button style on iOS 26+, fallback to bordered prominent on iOS 18-25
    @ViewBuilder
    func glassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
}

/// A card view with glass effect and optional content
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .glassBackground()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Basic glass card
        GlassCard {
            VStack {
                Text("Current #")
                    .font(.caption)
                Text("42")
                    .font(.largeTitle)
                    .bold()
            }
        }

        // Glass button
        Button("Tap Me") {
            print("Tapped")
        }
        .glassButtonStyle()
        .padding()

        // Manual glass background
        Text("Hello World")
            .padding()
            .glassBackground()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
