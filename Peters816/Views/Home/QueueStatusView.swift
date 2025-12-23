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
            // Number display cards
            // TODO: When Liquid Glass SDK is available, use GlassEffectContainer:
            // GlassEffectContainer(spacing: 20) {
            //     HStack(spacing: 20) {
            //         QueueNumberCard(...)
            //             .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            //             .glassEffectID("current", in: namespace)
            //         ...
            //     }
            // }
            HStack(spacing: 20) {
                QueueNumberCard(title: "Current #", value: currentNumber)
                QueueNumberCard(title: "Next Available #", value: nextNumber)
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
        .glassBackground()
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
