//
//  CreateAppointmentResponse.swift
//  Peters816
//
//  Response from creating an appointment
//

import Foundation

struct CreateAppointmentResponse: Codable {
    let appointment: AppointmentDTO
    let message: String
}
