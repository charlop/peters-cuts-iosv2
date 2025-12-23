//
//  AppointmentStatus.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Appointment state enumeration
//

import Foundation

enum AppointmentStatus {
    case noAppointment
    case hasNumber
    case hasReservation
    case shopClosed
    case noUserInfo
    case loadingView
}

// MARK: - Legacy Support
// Keep CONSTS.AppointmentStatus for backwards compatibility during migration
extension CONSTS {
    typealias AppointmentStatus = Peters816.AppointmentStatus
}
