//
//  CreateAppointmentRequest.swift
//  Peters816
//
//  Request to create a new appointment
//

import Foundation

struct CreateAppointmentRequest: Codable {
    let date: String // YYYY-MM-DD format
    let type: String // "walkin" or "reservation"
    let slotId: Int? // Required for reservations
    let requestedTime: String? // HH:MM format
}
