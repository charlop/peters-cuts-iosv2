//
//  User.swift
//  Peters816
//
//  Created by Chris on 2016-10-12.
//  Copyright © 2016 Chris Charlopov. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

// MARK: - User
final class User {
    // MARK: - Properties
    private struct Constants {
        static let defaultHoursText = "Please call/text Peter for current shop hours."
        static let notificationTitles = [
            20: "Your haircut is in 20 minutes!",
            40: "Your haircut is in 40 minutes!"
        ]
    }
    
    private struct UserKeys {
        static let name = "name"
        static let phone = "phone"
        static let email = "email"
        static let appointment = "appointment"
        static let hoursText = "hoursText"
        static let addrUrl = "addrUrl"
    }
    
    private var name: String
    private var phone: String
    private var email: String
    private var appointmentArray: [Appointment]
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Initialize with stored values or defaults
        self.name = userDefaults.string(forKey: UserKeys.name) ?? ""
        self.phone = userDefaults.string(forKey: UserKeys.phone) ?? ""
        self.email = userDefaults.string(forKey: UserKeys.email) ?? ""
        self.appointmentArray = [Appointment()]
        
        loadAppointments()
        validateIds()
    }
    
    // MARK: - Public Methods
    func addOrUpdateAppointment(newAppointment: Appointment) {
        if newAppointment.getAppointmentStatus() == CONSTS.AppointmentStatus.NO_APPOINTMENT {
            handleNoAppointment(newAppointment)
        } else {
            handleExistingAppointment(newAppointment)
        }
        saveAppointments()
    }
    
    func saveUserDetails(name: String, phone: String, email: String = "") {
        removeAllAppointments() // Reset appointments when user info changes
        
        self.name = name
        self.phone = phone
        self.email = email
        
        userDefaults.set(name, forKey: UserKeys.name)
        userDefaults.set(phone, forKey: UserKeys.phone)
        userDefaults.set(email, forKey: UserKeys.email)
    }
    
    func getFirstUpcomingEta() -> (CONSTS.ErrorNum.RawValue, String) {
        guard hasAppointment else {
            return (CONSTS.ErrorNum.NO_NUMBER.rawValue, "")
        }
        
        let etaMins = appointmentArray[0].getEtaMins()
        
        if etaMins < 0 {
            return (appointmentArray[0].getError(), "")
        }
        
        return (CONSTS.ErrorNum.NO_ERROR.rawValue, formatEtaString(minutes: etaMins))
    }
    
    func removeAllAppointments() {
        appointmentArray = [Appointment()]
        userDefaults.removeObject(forKey: UserKeys.appointment)
    }
    
    // MARK: - Hours and Address Management
    @discardableResult
    func saveHoursText(_ hoursText: String) -> String {
        let text = hoursText.isEmpty ? Constants.defaultHoursText : hoursText
        userDefaults.set(text, forKey: UserKeys.hoursText)
        return text
    }
    
    func getHoursText() -> String {
        return userDefaults.string(forKey: UserKeys.hoursText) ?? saveHoursText("")
    }
    
    func saveAddrUrl(_ addrUrl: String) {
        userDefaults.set(addrUrl, forKey: UserKeys.addrUrl)
    }
    
    func getAddrUrl() -> String {
        return userDefaults.string(forKey: UserKeys.addrUrl) ?? ""
    }
    
    // MARK: - User Info Access
    var userInfoExists: Bool {
        !name.isEmpty && !phone.isEmpty
    }
    
    var userName: String { name }
    var userPhone: String { phone }
    var userEmail: String { email }
    
    func getFirstAppointment() -> Appointment {
        validateIds()
        return appointmentArray[0]
    }
    
    var hasAppointment: Bool {
        validateIds()
        if appointmentArray.count == 0 { return false }
        return appointmentArray[0].getAppointmentStatus() != .NO_APPOINTMENT
    }
    
    // MARK: - Private Methods
    private func loadAppointments() {
        guard let data = userDefaults.object(forKey: UserKeys.appointment) as? Data else { return }
        
        do {
            if let appointments = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: Appointment.self, from: data) {
                appointmentArray = appointments
            }
        } catch {
            print("Failed to unarchive appointment array: \(error)")
        }
    }
    
    private func saveAppointments() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: appointmentArray as NSArray, requiringSecureCoding: false) {
            userDefaults.set(data, forKey: UserKeys.appointment)
        }
    }
    
    private func handleNoAppointment(_ newAppointment: Appointment) {
        if hasAppointment {
            removeAllAppointments()
        }
        appointmentArray = [newAppointment]
    }
    
    private func handleExistingAppointment(_ newAppointment: Appointment) {
        if appointmentArray.count > 1 {
            validateIds()
            if !newAppointment.appointmentUnchanged(newAppointment: appointmentArray[0]) {
                removeAllAppointments()
                addAppointment(newAppointment)
            } else {
                updateExistingAppointment(with: newAppointment)
            }
        } else {
            addAppointment(newAppointment)
        }
    }
    
    private func updateExistingAppointment(with newAppointment: Appointment) {
        appointmentArray[0].setCurrentId(currentId: newAppointment.getCurrentId())
        appointmentArray[0].updateError(newError: newAppointment.getError())
        appointmentArray[0].setAppointmentStartTime(etaMinVal: newAppointment.getEtaMins())
    }
    
    private func addAppointment(_ newAppointment: Appointment) {
        if hasAppointment {
            if appointmentArray[0].getEtaMins() > newAppointment.getEtaMins() {
                appointmentArray.insert(newAppointment, at: 0)
                createNotifications(for: newAppointment.getEtaMins())
            } else {
                appointmentArray.append(newAppointment)
            }
        } else {
            appointmentArray = [newAppointment]
            createNotifications(for: newAppointment.getEtaMins())
        }
        saveAppointments()
    }
    
    private func validateIds() {
        appointmentArray.removeAll { !$0.isValid() }
    }
    
    private func formatEtaString(minutes: Double) -> String {
        var result = ""
        if minutes > 60 {
            result += "\(Int(floor(minutes / 60))) hours "
        }
        result += "\(Int(minutes) % 60) minutes"
        return result
    }
    
    // MARK: - Notifications
    private func createNotifications(for etaMin: Double) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing notifications if any
        center.getPendingNotificationRequests { [weak self] notifications in
            if !notifications.isEmpty {
                self?.removeAllAppointments()
            }
        }
        
        // Create new notifications for different time intervals
        Constants.notificationTitles.forEach { minutes, message in
            guard etaMin > Double(minutes) else { return }
            
            scheduleNotification(
                title: "Message from Peter",
                body: message,
                timeInterval: (etaMin - Double(minutes)) * 60
            )
        }
    }
    
    private func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
