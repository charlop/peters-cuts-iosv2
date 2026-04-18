//
//  APIEndpoints.swift
//  Peters816
//
//  API v2 endpoint definitions
//

import Foundation

enum APIEndpoint {
    case health
    case sendCode
    case verifyCode
    case checkDevice
    case queueStatus
    case myAppointment
    case availableSlots(date: String)
    case createAppointment
    case cancelAppointment(id: String)

    var path: String {
        switch self {
        case .health:
            return "/health"
        case .sendCode:
            return "/auth/send-code"
        case .verifyCode:
            return "/auth/verify-code"
        case .checkDevice:
            return "/auth/check-device"
        case .queueStatus:
            return "/queue/status"
        case .myAppointment:
            return "/queue/my-appointment"
        case .availableSlots(let date):
            return "/appointments/available?date=\(date)"
        case .createAppointment:
            return "/appointments"
        case .cancelAppointment(let id):
            return "/appointments/\(id)"
        }
    }

    var method: String {
        switch self {
        case .health, .queueStatus, .myAppointment, .availableSlots:
            return "GET"
        case .sendCode, .verifyCode, .checkDevice, .createAppointment:
            return "POST"
        case .cancelAppointment:
            return "DELETE"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .myAppointment, .createAppointment, .cancelAppointment:
            return true
        default:
            return false
        }
    }
}
