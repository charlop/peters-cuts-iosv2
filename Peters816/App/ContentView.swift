//
//  ContentView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Main navigation container
//

import SwiftUI

struct ContentView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                    case .about:
                        AboutView()
                    case .userInfo:
                        UserInfoView()
                    case .reservation:
                        ReservationView()
                    case .termsOfUse:
                        TermsOfUseView()
                    case .privacyPolicy:
                        PrivacyPolicyView()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
