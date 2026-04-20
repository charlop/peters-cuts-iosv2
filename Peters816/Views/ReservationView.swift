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
            if shouldDismiss && viewModel.reservationCount < 4 {
                // Success case with option to reserve another
                Button("Done") {
                    dismiss()
                }
                Button("Reserve Another") {
                    // Just dismiss alert, stay on screen
                }
            } else {
                // Error case or max reservations reached
                Button("OK") {
                    if shouldDismiss {
                        dismiss()
                    }
                }
            }
        } message: {
            if shouldDismiss && viewModel.reservationCount < 4 {
                Text("\(alertMessage)\n\nReserve another appointment?")
            } else if viewModel.reservationCount >= 4 {
                Text("\(alertMessage)\n\nYou've reached the maximum of 4 reservations.")
            } else {
                Text(alertMessage)
            }
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
        // Backend sends times in EST but with a Z (UTC) indicator
        // Strip the Z and milliseconds to parse as EST
        let cleanedString = appointmentStartTime
            .replacingOccurrences(of: ".000Z", with: "")
            .replacingOccurrences(of: "Z", with: "")

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        inputFormatter.timeZone = TimeZone(identifier: "America/New_York") // Parse as EST

        guard let date = inputFormatter.date(from: cleanedString) else {
            return appointmentStartTime
        }

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "h:mm a"
        outputFormatter.timeZone = TimeZone(identifier: "America/New_York") // Display in EST

        return outputFormatter.string(from: date)
    }
}

@MainActor
class ReservationViewModel: ObservableObject {
    @Published var availableSlots: [ReservationSlot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDate: String = ""
    @Published var toast: ToastMessage?
    @Published var reservationCount: Int = 0

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
            }.sorted { slot1, slot2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = TimeZone(identifier: "America/New_York")

                let clean1 = slot1.appointmentStartTime.replacingOccurrences(of: ".000Z", with: "").replacingOccurrences(of: "Z", with: "")
                let clean2 = slot2.appointmentStartTime.replacingOccurrences(of: ".000Z", with: "").replacingOccurrences(of: "Z", with: "")

                guard let date1 = formatter.date(from: clean1),
                      let date2 = formatter.date(from: clean2) else {
                    return false
                }
                return date1 < date2
            }

            // Update reservation count from server
            reservationCount = response.count

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

        guard userDefaults.userInfoExists else {
            return (false, "Please enter your user info before making a reservation")
        }

        do {
            let request = CreateAppointmentRequest(
                date: getCurrentDate(),
                type: "reservation",
                slotId: slot.slotId,
                requestedTime: nil,
                count: 1
            )

            let _: CreateAppointmentResponse = try await authService.authenticatedRequest(
                .createAppointment,
                body: request
            )

            // Remove the booked slot immediately (optimistic update)
            availableSlots.removeAll { $0.slotId == slot.slotId }

            // Refresh from server to get updated slot list and reservation count
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
