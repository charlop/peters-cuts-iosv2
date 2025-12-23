//
//  TermsOfUseView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Terms of Use screen
//

import SwiftUI

struct TermsOfUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Use")
                    .font(.title)
                    .bold()

                Text("""
                Please read these terms carefully before using the Peters Haircuts mobile application.

                By accessing or using this app, you agree to be bound by these Terms of Use.

                1. Appointments and Reservations
                   - Reservations must be honored or cancelled with at least 1 hour notice
                   - Walk-in queue numbers are first-come, first-served
                   - The shop reserves the right to cancel or modify appointments

                2. User Information
                   - You agree to provide accurate contact information
                   - Your information will be used solely for appointment notifications

                3. Limitation of Liability
                   - Wait times are estimates and may vary
                   - The shop is not liable for any inconvenience caused by wait time variations

                4. Changes to Terms
                   - These terms may be modified at any time
                   - Continued use of the app constitutes acceptance of modified terms
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Terms of Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TermsOfUseView()
    }
}
