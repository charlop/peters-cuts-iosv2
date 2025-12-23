//
//  ReservationView.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Reservation booking screen
//

import SwiftUI

struct ReservationView: View {
    @StateObject private var viewModel = ReservationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var shouldDismiss = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading available times...")
            } else if viewModel.availableSlots.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("No available time slots")
                        .font(.headline)

                    Text(viewModel.errorMessage ?? "Please check back later")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                List {
                    Section {
                        ForEach(viewModel.availableSlots, id: \.time) { slot in
                            HStack {
                                Text(slot.time)
                                    .font(.body)

                                Spacer()

                                Button("Book") {
                                    Task {
                                        let result = await viewModel.bookSlot(slot)
                                        alertTitle = result.success ? "Success" : "Error"
                                        alertMessage = result.message
                                        shouldDismiss = result.success
                                        showAlert = true
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    } header: {
                        Text("Available Times")
                    } footer: {
                        Text("Please be on time for your appointment or give at least 1 hour notice if you can't make it.")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Make a Reservation")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadAvailableSlots()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if shouldDismiss {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
}

struct ReservationSlot {
    let time: String
    let id: Int
}

@MainActor
class ReservationViewModel: ObservableObject {
    @Published var availableSlots: [ReservationSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadAvailableSlots() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await APIService.shared.getOpenings()

            if let error = result.error {
                let errorDescription = CONSTS.getErrorDescription(errorId: error)
                errorMessage = errorDescription.rawValue
                availableSlots = []
            } else {
                availableSlots = result.availableSpotsArray.compactMap { time in
                    if let id = result.availableSpots[time] {
                        return ReservationSlot(time: time, id: id)
                    }
                    return nil
                }
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            availableSlots = []
        }

        isLoading = false
    }

    func bookSlot(_ slot: ReservationSlot) async -> (success: Bool, message: String) {
        var user = User()

        guard user.userInfoExists else {
            return (false, "Please enter your user info before making a reservation")
        }

        do {
            let newUser = try await APIService.shared.getNumber(
                for: user,
                count: 1,
                isReservation: true,
                reservationId: slot.id
            )
            user = newUser
            let appointment = user.getFirstAppointment()

            if appointment.getIsReservation() {
                await loadAvailableSlots() // Refresh the list
                return (true, "Your appointment is saved for \(slot.time)")
            } else {
                return (false, "Failed to book reservation")
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        ReservationView()
    }
}
