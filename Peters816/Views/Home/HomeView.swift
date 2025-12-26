//
//  HomeView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Main home screen with queue status and booking actions
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var haircutCount = 1
    @State private var showPhoneVerification = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    Image("logo1")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 320)
                        .padding(.top, 8)

                    // Greeting text
                    Text(viewModel.greetingText)
                        .font(.title3)
                        .multilineTextAlignment(.center)

                    // Queue status (when not loading or closed)
                    if viewModel.currentState != .loadingView && viewModel.currentState != .shopClosed {
                        QueueStatusView(
                            currentNumber: viewModel.currentCustomerNumber,
                            nextNumber: viewModel.nextAvailableNumber,
                            waitTime: viewModel.waitTimeText
                        )
                    }

                    // Action buttons
                    ActionButtonsView(
                        currentState: viewModel.currentState,
                        haircutCount: $haircutCount,
                        onGetNumber: {
                            Task {
                                // Check auth first
                                if !viewModel.isAuthenticated {
                                    showPhoneVerification = true
                                    return
                                }

                                let result = await viewModel.getNumber(count: haircutCount)
                                if result.success {
                                    showAlert(title: "Success", message: result.message)
                                } else {
                                    showAlert(title: "Error", message: result.message)
                                }
                            }
                        },
                        onCancel: {
                            Task {
                                // Check auth first
                                if !viewModel.isAuthenticated {
                                    showPhoneVerification = true
                                    return
                                }

                                let result = await viewModel.cancelAppointment()
                                showAlert(title: result.success ? "Success" : "Error", message: result.message)
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }
            .opacity(viewModel.isLoading ? 0.5 : 1.0)

            // Loading overlay
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Peter's Haircuts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(value: NavigationDestination.about) {
                    Text("About")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: NavigationDestination.userInfo) {
                    Text("User Info")
                }
            }
        }
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
            case .phoneVerification:
                PhoneVerificationView()
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            Task {
                await viewModel.getWaitTime()
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showPhoneVerification) {
            NavigationStack {
                PhoneVerificationView()
            }
        }
        .toast($viewModel.toast)
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
