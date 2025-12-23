//
//  User.swift
//  Peters816
//
//  Created by Chris on 2016-10-12.
//  Copyright © 2016 Chris Charlopov. All rights reserved.
//  Refactored 2025-12-22 to use services
//

import Foundation
import UIKit
import UserNotifications

// MARK: - User
final class User {
    // MARK: - Properties
    private var name: String
    private var phone: String
    private var email: String
    private var appointmentArray: [Appointment]

    private let storage = UserDefaultsService.shared
    private let notifications = NotificationService.shared

    // MARK: - Initialization
    init() {
        // Load from UserDefaultsService
        self.name = storage.getUserName() ?? ""
        self.phone = storage.getUserPhone() ?? ""
        self.email = storage.getUserEmail() ?? ""
        self.appointmentArray = storage.loadAppointments()

        validateIds()
    }
    
    // MARK: - Public Methods
    func addOrUpdateAppointment(newAppointment: Appointment) {
        if newAppointment.getAppointmentStatus() == CONSTS.AppointmentStatus.noAppointment {
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

        storage.saveUserInfo(name: name, phone: phone, email: email)
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
        storage.removeAllAppointments()
    }
    
    // MARK: - Hours and Address Management
    @discardableResult
    func saveHoursText(_ hoursText: String) -> String {
        storage.saveHoursText(hoursText)
        return storage.getHoursText()
    }

    func getHoursText() -> String {
        return storage.getHoursText()
    }

    func saveAddrUrl(_ addrUrl: String) {
        storage.saveAddressURL(addrUrl)
    }

    func getAddrUrl() -> String {
        return storage.getAddressURL()
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
        return appointmentArray[0].getAppointmentStatus() != .noAppointment
    }
    
    // MARK: - Private Methods
    private func saveAppointments() {
        storage.saveAppointments(appointmentArray)
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
        notifications.scheduleAppointmentNotifications(etaMinutes: etaMin)
    }
}
