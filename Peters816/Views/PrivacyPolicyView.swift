//
//  PrivacyPolicyView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Privacy Policy screen
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .bold()

                Text("""
                This Privacy Policy describes how Peters Haircuts collects, uses, and protects your personal information.

                Information We Collect:
                - Name
                - Phone number
                - Email address (optional)
                - Appointment booking information

                How We Use Your Information:
                - To manage your appointment queue position
                - To send appointment notifications
                - To contact you regarding your appointment

                Data Storage:
                - Your information is stored securely on our servers
                - We do not share your information with third parties
                - You may request deletion of your data at any time

                Notifications:
                - You may receive notifications about your appointments
                - You can disable notifications in your device settings

                Contact:
                If you have questions about this Privacy Policy, please contact us at (519) 816-2887.

                Last Updated: December 2025
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
