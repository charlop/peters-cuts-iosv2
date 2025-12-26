//
//  MyAppointmentResponse.swift
//  Peters816
//
//  Response for user's current appointment
//

import Foundation

struct MyAppointmentResponse: Codable {
    let appointment: AppointmentDTO
    let queuePosition: Int
    let estimatedWaitTime: Int

    enum CodingKeys: String, CodingKey {
        case appointment
        case queuePosition = "position"
        case estimatedWaitTime
    }
}
