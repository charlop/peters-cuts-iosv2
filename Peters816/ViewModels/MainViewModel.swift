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

    // MARK: - Private Properties
    private let apiClient = APIClientV2.shared
    private let authService = AuthService.shared
    private var userDefaults = User()
    private var currentAppointmentId: String?

    // MARK: - Computed Properties
    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }

    func loadInitialData() async {
        currentState = .loadingView
        greetingText = "Loading the latest schedule..."

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
                greetingText = "Peter's is closed. Check back during business hours."
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
            if authService.isAuthenticated, let token = authService.currentToken {
                await checkMyAppointment(token: token)
            } else if userDefaults.userInfoExists {
                currentState = .noAppointment
                greetingText = "Hey \(userDefaults.userName), looking to get a haircut?"
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

        guard let token = authService.currentToken else {
            return (false, "Authentication required")
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
                requestedTime: nil
            )

            let response: CreateAppointmentResponse = try await apiClient.request(
                .createAppointment,
                body: request,
                token: token
            )

            currentAppointmentId = response.appointment.appointmentId
            currentState = .hasNumber
            greetingText = "Hey \(userDefaults.userName), your spot is saved"

            await getWaitTime()

            var message = "Nice! Your haircut is in "
            if count > 1 {
                message = "You have reserved \(count) haircuts, first one is in "
            }
            message += waitTimeText

            return (true, message)
        } catch let error as APIClientError {
            return (false, error.localizedDescription)
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    func cancelAppointment() async -> (success: Bool, message: String) {
        guard authService.isAuthenticated else {
            return (false, "Please sign in first")
        }

        guard let token = authService.currentToken else {
            return (false, "Authentication required")
        }

        guard let appointmentId = currentAppointmentId else {
            return (false, "No appointment to cancel")
        }

        do {
            let _: SuccessMessageResponse = try await apiClient.request(
                .cancelAppointment(id: appointmentId),
                token: token
            )

            currentAppointmentId = nil
            currentState = .noAppointment
            greetingText = "Hey \(userDefaults.userName), looking to get a haircut?"

            return (true, "Appointment Cancelled")
        } catch let error as APIClientError {
            return (false, error.localizedDescription)
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func checkMyAppointment(token: String) async {
        do {
            let response: MyAppointmentResponse = try await apiClient.request(
                .myAppointment,
                token: token
            )

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
