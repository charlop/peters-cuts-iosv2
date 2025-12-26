//
//  ReservationView.swift
//  Peters816
//
//  Reservation booking screen using API v2
//

import SwiftUI

struct ReservationView: View {
    @StateObject private var viewModel = ReservationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var shouldDismiss = false
    @State private var showPhoneVerification = false

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
                        ForEach(viewModel.availableSlots, id: \.slotId) { slot in
                            HStack {
                                Text(slot.formattedTime)
                                    .font(.body)

                                Spacer()

                                Button("Book") {
                                    Task {
                                        // Check auth first
                                        if !viewModel.isAuthenticated {
                                            showPhoneVerification = true
                                            return
                                        }

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
                        Text("Available Times for \(viewModel.selectedDate)")
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
        .toast($viewModel.toast)
        .sheet(isPresented: $showPhoneVerification) {
            NavigationStack {
                PhoneVerificationView()
            }
        }
    }
}

struct ReservationSlot {
    let slotId: Int
    let appointmentStartTime: String
    let appointmentEndTime: String

    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: appointmentStartTime) else {
            return appointmentStartTime
        }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return timeFormatter.string(from: date)
    }
}

@MainActor
class ReservationViewModel: ObservableObject {
    @Published var availableSlots: [ReservationSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: String = ""
    @Published var toast: ToastMessage?

    private let apiClient = APIClientV2.shared
    private let authService = AuthService.shared
    private var userDefaults = User()

    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }

    func loadAvailableSlots() async {
        isLoading = true
        errorMessage = nil

        let dateString = getCurrentDate()
        selectedDate = formatDateForDisplay(dateString)

        // Check reachability first
        let hasConnection = await Reachability.isConnectedToNetwork()
        if !hasConnection {
            errorMessage = "No internet connection"
            toast = ToastMessage(message: "No internet connection. Please check your network.", type: .error, duration: 4.0)
            availableSlots = []
            isLoading = false
            return
        }

        do {
            let response: AvailableSlotsResponse = try await apiClient.request(
                .availableSlots(date: dateString)
            )

            availableSlots = response.availableSlots.map { slot in
                ReservationSlot(
                    slotId: slot.slotId,
                    appointmentStartTime: slot.appointmentStartTime,
                    appointmentEndTime: slot.appointmentEndTime
                )
            }

            if availableSlots.isEmpty {
                errorMessage = "No slots available for today. Please check back later."
            }
        } catch let error as APIClientError {
            let message = error.localizedDescription
            errorMessage = message
            toast = ToastMessage(message: message, type: .error, duration: 4.0)
            availableSlots = []
        } catch {
            let errorMsg = error.localizedDescription
            let message = errorMsg.contains("hostname") ? "Server unavailable. Please try again later." : errorMsg
            errorMessage = message
            toast = ToastMessage(message: message, type: .error, duration: 4.0)
            availableSlots = []
        }

        isLoading = false
    }

    func bookSlot(_ slot: ReservationSlot) async -> (success: Bool, message: String) {
        guard authService.isAuthenticated else {
            return (false, "Please sign in first")
        }

        guard let token = authService.currentToken else {
            return (false, "Authentication required")
        }

        guard userDefaults.userInfoExists else {
            return (false, "Please enter your user info before making a reservation")
        }

        do {
            let request = CreateAppointmentRequest(
                date: getCurrentDate(),
                type: "reservation",
                slotId: slot.slotId,
                requestedTime: nil
            )

            let _: CreateAppointmentResponse = try await apiClient.request(
                .createAppointment,
                body: request,
                token: token
            )

            await loadAvailableSlots()
            return (true, "Your appointment is saved for \(slot.formattedTime)")
        } catch let error as APIClientError {
            return (false, error.localizedDescription)
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func formatDateForDisplay(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        return outputFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        ReservationView()
    }
}
