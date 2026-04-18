//
//  AvailableSlotsResponse.swift
//  Peters816
//
//  Response for available appointment slots
//

import Foundation

struct AppointmentSlot: Codable {
    let appointmentId: String
    let slotId: Int
    let appointmentStartTime: String
    let appointmentEndTime: String
    let status: String
}

struct AvailableSlotsResponse: Codable {
    let date: String
    let availableSlots: [AppointmentSlot]
    let count: Int
}
