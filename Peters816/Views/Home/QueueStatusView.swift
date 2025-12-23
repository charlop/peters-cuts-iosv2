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

    @Namespace private var namespace

    var body: some View {
        VStack(spacing: 16) {
            // Number display cards with Liquid Glass morphing
            if #available(iOS 26, *) {
                GlassEffectContainer(spacing: 20) {
                    HStack(spacing: 20) {
                        QueueNumberCard(title: "Current #", value: currentNumber)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .glassEffectID("current", in: namespace)

                        QueueNumberCard(title: "Next Available #", value: nextNumber)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                            .glassEffectID("next", in: namespace)
                    }
                }
            } else {
                HStack(spacing: 20) {
                    QueueNumberCard(title: "Current #", value: currentNumber)
                    QueueNumberCard(title: "Next Available #", value: nextNumber)
                }
            }

            // Wait time
            if !waitTime.isEmpty {
                Text(waitTime)
                    .font(.headline)
                    .foregroundColor(.secondary)
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
        waitTime: "15 minutes"
    )
    .padding()
}
