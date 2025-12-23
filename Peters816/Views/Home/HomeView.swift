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
    @State private var navigateToReservation = false

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with About and User Info buttons
                HStack {
                    NavigationLink(value: NavigationDestination.about) {
                        Text("About")
                            .font(.system(size: 17))
                    }

                    Spacer()

                    NavigationLink(value: NavigationDestination.userInfo) {
                        Text("User Info")
                            .font(.system(size: 17))
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                // Main content based on state
                VStack(spacing: 30) {
                    // Greeting text
                    Text(viewModel.greetingText)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

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
                                let result = await viewModel.getNumber(count: haircutCount)
                                if result.success {
                                    showAlert(title: "Success", message: result.message)
                                } else {
                                    showAlert(title: "Error", message: result.message)
                                }
                            }
                        },
                        onReservation: {
                            navigateToReservation = true
                        },
                        onCancel: {
                            Task {
                                let result = await viewModel.cancelAppointment()
                                showAlert(title: result.success ? "Success" : "Error", message: result.message)
                            }
                        }
                    )
                }

                Spacer()
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
        .navigationDestination(isPresented: $navigateToReservation) {
            ReservationView()
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
