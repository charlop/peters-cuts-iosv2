//
//  AppointmentDTO.swift
//  Peters816
//
//  Appointment data from API v2
//

import Foundation

enum AppointmentStatusV2: String, Codable {
    case available
    case booked
    case serving
    case completed
    case cancelled
    case noshow
}

enum AppointmentTypeV2: String, Codable {
    case walkin
    case reservation
    case `break`
    case adminBooking = "admin-booking"
}

struct AppointmentDTO: Codable {
    let appointmentId: String
    let date: String
    let slotId: Int
    let customerName: String?
    let customerPhone: String
    let appointmentStartTime: String
    let appointmentEndTime: String
    let checkinTime: String?
    let status: AppointmentStatusV2
    let type: AppointmentTypeV2
    let createdAt: String
    let updatedAt: String
    let breakTemplateId: String?
    let breakLabel: String?
    let bookedBy: String?
    let notes: String?
}
