//
//  CreateAppointmentResponse.swift
//  Peters816
//
//  Response from creating an appointment
//

import Foundation

struct CreateAppointmentResponse: Codable {
    let appointments: [AppointmentDTO]
    let count: Int
    let message: String
}
