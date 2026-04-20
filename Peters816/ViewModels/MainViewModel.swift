//
//  MainViewModel.swift
//  Peters816
//
//  Main screen view model using API v2
//

import Foundation
import Combine

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentState: AppointmentStatus = .noAppointment
    @Published var waitTimeText: String = ""
    @Published var greetingText: String = ""
    @Published var currentCustomerNumber: String = "--"
    @Published var nextAvailableNumber: String = "--"
    @Published var isLoading: Bool = false
    @Published var toast: ToastMessage?
    @Published var appointmentCount: Int = 0
    @Published var shopGreeting: String?

    // MARK: - Private Properties
    private let apiClient = APIClientV2.shared
    private let authService = AuthService.shared
    private var userDefaults = User()
    private var currentAppointmentId: String?
    private var appointmentIds: [String] = []

    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }

    func loadInitialData() async {
        currentState = .loadingView
        greetingText = "Loading the latest schedule..."

        if let response: GreetingResponse = try? await apiClient.request(.configGreeting),
           !response.greeting.isEmpty {
            shopGreeting = response.greeting
        }

        await getWaitTime()
    }

    func getWaitTime() async {
        // Check reachability first
        let hasConnection = await Reachability.isConnectedToNetwork()
        if !hasConnection {
            currentState = .noUserInfo
            greetingText = "No internet connection"
            toast = ToastMessage(message: "No internet connection. Please check your network.", type: .error, duration: 4.0)
            return
        }

        do {
            let queueStatus: QueueStatusResponse = try await apiClient.request(.queueStatus)

            if !queueStatus.isOpen {
                currentState = .shopClosed
                greetingText = queueStatus.closureMessage ?? "Peter's is closed. Check back during business hours."
                return
            }

            if queueStatus.slotsAvailable == 0 {
                currentState = .noSlotsAvailable
                if let nextDay = queueStatus.nextOpenDay, nextDay != "today" {
                    greetingText = "Peter's is fully booked. Next availability: \(nextDay)."
                } else {
                    greetingText = "Peter's is fully booked for today. Check back soon!"
                }
                return
            }

            if let currentNum = queueStatus.currentNumber {
                currentCustomerNumber = String(currentNum)
            }

            let estimatedMins = queueStatus.estimatedWaitTime
            let hours = estimatedMins / 60
            let mins = estimatedMins % 60

            var waitTimeString = ""
            if hours > 0 {
                waitTimeString += "\(hours) hours "
            }
            waitTimeString += "\(mins) minutes"
            waitTimeText = waitTimeString

            nextAvailableNumber = String(queueStatus.queueLength + 1)

            // Check if user has an appointment
            if authService.isAuthenticated {
                await checkMyAppointment()
            } else if userDefaults.userInfoExists {
                currentState = .noAppointment
                greetingText = shopGreeting ?? "Hey \(userDefaults.userName), looking to get a haircut?"
            } else {
                currentState = .noUserInfo
                greetingText = "Tap on User Info before you can book a haircut"
            }
        } catch let error as APIClientError {
            handleNetworkError(error)
        } catch {
            let errorMsg = error.localizedDescription
            currentState = .noUserInfo
            greetingText = "Unable to connect to server"
            toast = ToastMessage(message: errorMsg.contains("hostname") ? "Server unavailable. Please try again later." : errorMsg, type: .error, duration: 5.0)
        }
    }

    func getNumber(count: Int) async -> (success: Bool, message: String) {
        guard authService.isAuthenticated else {
            return (false, "Please sign in first")
        }

        guard userDefaults.userInfoExists else {
            currentState = .noUserInfo
            return (false, "Please enter user info first")
        }

        do {
            let request = CreateAppointmentRequest(
                date: getCurrentDate(),
                type: "walkin",
                slotId: nil,
                requestedTime: nil,
                count: count
            )

            let response: CreateAppointmentResponse = try await authService.authenticatedRequest(
                .createAppointment,
                body: request
            )

            appointmentIds = response.appointments.map { $0.appointmentId }
            currentAppointmentId = response.appointments.first?.appointmentId
            appointmentCount = response.count
            currentState = .hasNumber
            greetingText = "Hey \(userDefaults.userName), you have \(response.count) appointment\(response.count > 1 ? "s" : "")"

            await getWaitTime()
        } catch let error as APIClientError {
            return (false, error.localizedDescription)
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }

        var message = "Nice! Your haircut is in "
        if count > 1 {
            message = "You have reserved \(count) haircuts, first one is in "
        }
        message += waitTimeText

        return (true, message)
    }

    func cancelAppointment() async -> (success: Bool, message: String) {
        guard authService.isAuthenticated else {
            return (false, "Please sign in first")
        }

        // Cancel all appointments
        let idsToCancel = appointmentIds.isEmpty ? (currentAppointmentId.map { [$0] } ?? []) : appointmentIds

        guard !idsToCancel.isEmpty else {
            return (false, "No appointment to cancel")
        }

        var cancelledCount = 0
        for appointmentId in idsToCancel {
            do {
                let _: SuccessMessageResponse = try await authService.authenticatedRequest(
                    .cancelAppointment(id: appointmentId)
                )
                cancelledCount += 1
            } catch {
                // Continue cancelling others even if one fails
                continue
            }
        }

        // Clear state
        currentAppointmentId = nil
        appointmentIds = []
        appointmentCount = 0
        currentState = .noAppointment
        greetingText = "Hey \(userDefaults.userName), looking to get a haircut?"

        if cancelledCount == idsToCancel.count {
            let message = idsToCancel.count > 1 ? "All \(idsToCancel.count) appointments cancelled" : "Appointment cancelled"
            return (true, message)
        } else if cancelledCount > 0 {
            return (true, "Cancelled \(cancelledCount) of \(idsToCancel.count) appointments")
        } else {
            return (false, "Failed to cancel appointments")
        }
    }

    // MARK: - Private Methods

    private func checkMyAppointment() async {
        do {
            let response: MyAppointmentResponse = try await authService.authenticatedRequest(.myAppointment)

            currentAppointmentId = response.appointment.appointmentId

            switch response.appointment.type {
            case .walkin:
                currentState = .hasNumber
            case .reservation:
                currentState = .hasReservation
            default:
                currentState = .noAppointment
                return
            }

            greetingText = "Hey \(userDefaults.userName), your spot is saved"

            let estimatedMins = response.estimatedWaitTime
            let hours = estimatedMins / 60
            let mins = estimatedMins % 60

            var waitTimeString = ""
            if hours > 0 {
                waitTimeString += "\(hours) hours "
            }
            waitTimeString += "\(mins) minutes"
            waitTimeText = waitTimeString
        } catch {
            // Only reset state if we don't have a current appointment
            if currentAppointmentId == nil {
                currentState = .noAppointment
                if userDefaults.userInfoExists {
                    greetingText = "Hey \(userDefaults.userName), looking to get a haircut?"
                }
            }
        }
    }

    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func handleNetworkError(_ error: APIClientError) {
        currentState = .noUserInfo
        let message: String

        switch error {
        case .networkError(let underlyingError):
            let errorDescription = underlyingError.localizedDescription
            if errorDescription.contains("hostname") {
                message = "Server unavailable. Please try again later."
                greetingText = "Unable to connect to server"
            } else if errorDescription.contains("internet") || errorDescription.contains("network") {
                message = "No internet connection. Please check your network."
                greetingText = "No internet connection"
            } else {
                message = "Network error: \(errorDescription)"
                greetingText = "Connection error"
            }
        case .unauthorized:
            authService.signOut()
            message = "Session expired. Please sign in again."
            greetingText = "Session expired"
        case .httpError(let statusCode, let serverMessage):
            message = "Server error (\(statusCode)): \(serverMessage)"
            greetingText = "Server error"
        default:
            message = error.localizedDescription
            greetingText = "Error"
        }

        toast = ToastMessage(message: message, type: .error, duration: 5.0)
    }
}
