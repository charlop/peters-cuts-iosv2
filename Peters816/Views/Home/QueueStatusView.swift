//
//  QueueStatusView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Display current and next customer numbers
//

import SwiftUI

struct QueueStatusView: View {
    let currentNumber: String
    let nextNumber: String
    let waitTime: String
    let hasAppointment: Bool

    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 16) {
            // Wait time (prominent, at top)
            let waitTitle = hasAppointment ? "Your Wait Time is" : "Estimated Wait"
            if !waitTime.isEmpty {
                if #available(iOS 26, *) {
                    GlassEffectContainer {
                        QueueNumberCard(title: waitTitle, value: waitTime)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .glassEffectID("waitTime", in: namespace)
                    }
                } else {
                    QueueNumberCard(title: waitTitle, value: waitTime)
                }
            }
            
            // Number display cards with Liquid Glass morphing
            let nextTitle = hasAppointment ? "Your Number" : "Next Available #"
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        QueueNumberCard(title: "Current #", value: currentNumber)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .glassEffectID("current", in: namespace)

                        
                        QueueNumberCard(title: nextTitle, value: nextNumber)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .glassEffectID("next", in: namespace)
                    }
                }
            } else {
                HStack(spacing: 20) {
                    QueueNumberCard(title: "Current #", value: currentNumber)
                    QueueNumberCard(title: nextTitle, value: nextNumber)
                }
            }
        }
        .padding()
    }
}

struct QueueNumberCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        // Note: When inside GlassEffectContainer (iOS 26), the glass effect
        // is applied by the parent container's .glassEffect() modifier.
        // For iOS 18-25 fallback, we apply glassBackground() directly.
    }
}

#Preview {
    QueueStatusView(
        currentNumber: "42",
        nextNumber: "45",
        waitTime: "15 minutes",
        hasAppointment: false
    )
    .padding()
}
