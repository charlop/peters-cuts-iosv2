//
//  MainViewModel.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Main screen view model - extracts business logic from ViewController
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

    // MARK: - Private Properties
    private var userDefaults = User()
    private var customGreetingMessage: String = ""
    private var shopClosedGreeting: String = "Peter's is closed, try checking the app after 9AM.\nSee the About page for shop hours."

    // Hardcoded messages (from original ViewController)
    private let signUpText = "Tap on User Info before you can book a haircut"
    private let existingUserGreeting = "looking to get a haircut?"
    private let haircut_upcoming_label = "Your spot is saved"
    private let yourEtaLabel = "Your haircut is in"
    private let defaultWaitTime = "Wait Time"
    private let generalGreeting = "How's it going"

    // MARK: - Public Methods

    func loadInitialData() async {
        currentState = .loadingView
        greetingText = "Loading the latest schedule..."

        // Load closed message and greeting in parallel
        async let closedMessage: () = fetchClosedMessage()
        async let greetingMessage: () = fetchGreetingMessage()

        await closedMessage
        await greetingMessage

        // Check for existing appointment
        await checkForExistingAppointment()

        // Start fetching ETA
        await getWaitTime()
    }

    func getWaitTime() async {
        do {
            let etaResponse = try await APIService.shared.getEta(for: userDefaults)
            userDefaults = User()

            let errorFatalBool = CONSTS.isFatal(errorId: etaResponse.getError())

            if etaResponse.getError() != CONSTS.ErrorNum.NO_ERROR.rawValue {
                await handleError(errorNum: etaResponse.getError())

                if errorFatalBool {
                    return
                }
            }

            // Update UI with ETA
            if etaResponse.getEtaMins() > 0.0 {
                updateUIState(newState: etaResponse.getAppointmentStatus())

                let etaHrs = Int(etaResponse.getEtaMins() / 60)
                let etaMins = Int(etaResponse.getEtaMins().truncatingRemainder(dividingBy: 60))

                var waitTimeString = ""
                if etaHrs > 0 {
                    waitTimeString += "\(etaHrs) hours "
                }
                waitTimeString += "\(etaMins) minutes"
                waitTimeText = waitTimeString
            }

            if etaResponse.getCurrentId() > 0 {
                currentCustomerNumber = String(etaResponse.getCurrentId())
            }

            if etaResponse.getUpcomingId() > 0 {
                nextAvailableNumber = String(etaResponse.getUpcomingId())
            }
        } catch {
            print("Error fetching ETA: \(error)")
        }
    }

    func getNumber(count: Int) async -> (success: Bool, message: String) {
        guard userDefaults.userInfoExists else {
            updateUIState(newState: .noUserInfo)
            return (false, "Please enter user info first")
        }

        do {
            let newUserDefaults = try await APIService.shared.getNumber(
                for: userDefaults,
                count: count,
                isReservation: false
            )
            userDefaults = newUserDefaults
            let firstAppointment = userDefaults.getFirstAppointment()

            if userDefaults.hasAppointment {
                // Success
                updateUIState(newState: firstAppointment.getAppointmentStatus())

                var notificationText = "Nice! Your haircut is in "
                if count > 1 {
                    notificationText = "You have reserved \(count) haircuts, first one is in "
                }
                notificationText += userDefaults.getFirstUpcomingEta().1

                await getWaitTime()
                return (true, notificationText)
            } else {
                // Error
                await handleError(errorNum: firstAppointment.getError())
                return (false, "Failed to get number")
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    func cancelAppointment() async -> (success: Bool, message: String) {
        guard userDefaults.userInfoExists else {
            updateUIState(newState: .noUserInfo)
            return (false, "No user info")
        }

        do {
            let delResponse = try await APIService.shared.cancelAppointment(for: userDefaults)

            if delResponse == CONSTS.ErrorNum.NO_ERROR.rawValue {
                updateUIState(newState: .noAppointment)
                greetingText = "\(generalGreeting), \(userDefaults.userName)? \(customGreetingMessage)"

                await getWaitTime()
                return (true, "Appointment Cancelled")
            } else {
                await handleError(errorNum: delResponse)
                return (false, "Cancellation failed")
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func checkForExistingAppointment() async {
        if !userDefaults.userInfoExists {
            updateUIState(newState: .noUserInfo)
        } else if userDefaults.hasAppointment {
            let etaLocal = userDefaults.getFirstUpcomingEta()
            if etaLocal.0 == CONSTS.ErrorNum.NO_ERROR.rawValue {
                greetingText = "Hey \(userDefaults.userName), Loading your latest appointment info \(customGreetingMessage)"
                waitTimeText = etaLocal.1
            } else {
                await handleError(errorNum: etaLocal.0)
            }
        }
    }

    private func fetchClosedMessage() async {
        do {
            let closedMessage = try await APIService.shared.getClosedMessage()
            let msgLength = closedMessage.messageText.count

            if closedMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                shopClosedGreeting = closedMessage.messageText
                updateUIState(newState: .shopClosed)
            }
        } catch {
            print("Error fetching closed message: \(error)")
        }
    }

    private func fetchGreetingMessage() async {
        do {
            let greetingMessage = try await APIService.shared.getGreetingMessage()
            let msgLength = greetingMessage.messageText.count

            if greetingMessage.errorNum == CONSTS.ErrorNum.NO_ERROR && msgLength >= 3 {
                customGreetingMessage = greetingMessage.messageText

                if !greetingText.hasSuffix(customGreetingMessage) {
                    greetingText += customGreetingMessage
                }
            }
        } catch {
            print("Error fetching greeting: \(error)")
        }
    }

    private func handleError(errorNum: Int) async {
        let errorDescription = CONSTS.getErrorDescription(errorId: errorNum)

        if errorNum == CONSTS.ErrorNum.NO_ERROR.rawValue {
            return
        }

        switch errorNum {
        case CONSTS.ErrorNum.NO_INTERNET.rawValue:
            greetingText = errorDescription.rawValue
        case CONSTS.ErrorNum.SHOP_CLOSED.rawValue:
            updateUIState(newState: .shopClosed)
            greetingText = shopClosedGreeting + customGreetingMessage
        case CONSTS.ErrorNum.NO_SPOTS_AVAILABLE.rawValue:
            updateUIState(newState: .shopClosed)
            greetingText = errorDescription.rawValue + customGreetingMessage
        default:
            greetingText = errorDescription.rawValue + customGreetingMessage
        }
    }

    private func updateUIState(newState: AppointmentStatus) {
        if newState == currentState {
            return
        }

        // Handle notification removal when state changes from has appointment
        if (currentState == .hasNumber || currentState == .hasReservation) && newState != currentState {
            NotificationService.shared.removeAllNotifications()
        }

        currentState = newState

        // Update greeting based on state
        switch newState {
        case .noAppointment:
            greetingText = "Hey \(userDefaults.userName), \(existingUserGreeting) \(customGreetingMessage)"
        case .hasNumber:
            greetingText = "Hey \(userDefaults.userName), \(haircut_upcoming_label)"
        case .hasReservation:
            greetingText = "Hey \(userDefaults.userName), \(haircut_upcoming_label)"
        case .shopClosed:
            // Keep existing shopClosedGreeting
            break
        case .noUserInfo:
            greetingText = "Hey, \(signUpText) \(customGreetingMessage)"
        case .loadingView:
            greetingText = "Loading the latest schedule..." + customGreetingMessage
            nextAvailableNumber = "--"
            currentCustomerNumber = "--"
        }
    }
}
