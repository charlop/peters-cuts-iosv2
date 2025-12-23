//
//  UserDefaultsService.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Centralized UserDefaults persistence service
//

import Foundation

// MARK: - UserDefaultsService
final class UserDefaultsService: @unchecked Sendable {
    static let shared = UserDefaultsService()

    private let userDefaults: UserDefaults

    // MARK: - Keys
    private enum Keys {
        static let userName = "name"
        static let userPhone = "phone"
        static let userEmail = "email"
        static let appointments = "appointment"
        static let hoursText = "hoursText"
        static let addressURL = "addrUrl"
    }

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - User Info

    func saveUserInfo(name: String, phone: String, email: String = "") {
        userDefaults.set(name, forKey: Keys.userName)
        userDefaults.set(phone, forKey: Keys.userPhone)
        userDefaults.set(email, forKey: Keys.userEmail)
    }

    func getUserName() -> String? {
        return userDefaults.string(forKey: Keys.userName)
    }

    func getUserPhone() -> String? {
        return userDefaults.string(forKey: Keys.userPhone)
    }

    func getUserEmail() -> String? {
        return userDefaults.string(forKey: Keys.userEmail)
    }

    var hasUserInfo: Bool {
        guard let name = getUserName(), let phone = getUserPhone() else {
            return false
        }
        return !name.isEmpty && !phone.isEmpty
    }

    // MARK: - Appointments

    func saveAppointments(_ appointments: [Appointment]) {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: appointments as NSArray,
            requiringSecureCoding: false
        ) else {
            print("Failed to archive appointments")
            return
        }
        userDefaults.set(data, forKey: Keys.appointments)
    }

    func loadAppointments() -> [Appointment] {
        guard let data = userDefaults.object(forKey: Keys.appointments) as? Data else {
            return [Appointment()]
        }

        do {
            if let appointments = try NSKeyedUnarchiver.unarchivedArrayOfObjects(
                ofClass: Appointment.self,
                from: data
            ) {
                return appointments
            }
        } catch {
            print("Failed to unarchive appointments: \(error)")
        }

        return [Appointment()]
    }

    func removeAllAppointments() {
        userDefaults.removeObject(forKey: Keys.appointments)
    }

    // MARK: - Shop Info

    func saveHoursText(_ text: String) {
        let hoursText = text.isEmpty ? "Please call/text Peter for current shop hours." : text
        userDefaults.set(hoursText, forKey: Keys.hoursText)
    }

    func getHoursText() -> String {
        return userDefaults.string(forKey: Keys.hoursText) ?? "Please call/text Peter for current shop hours."
    }

    func saveAddressURL(_ url: String) {
        userDefaults.set(url, forKey: Keys.addressURL)
    }

    func getAddressURL() -> String {
        return userDefaults.string(forKey: Keys.addressURL) ?? ""
    }

    // MARK: - Clear All Data

    func clearAllData() {
        let keys = [
            Keys.userName,
            Keys.userPhone,
            Keys.userEmail,
            Keys.appointments,
            Keys.hoursText,
            Keys.addressURL
        ]

        keys.forEach { userDefaults.removeObject(forKey: $0) }
    }
}
