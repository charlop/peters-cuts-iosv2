//
//  CheckDeviceResponse.swift
//  Peters816
//
//  Response from checking device trust
//

import Foundation

struct CheckDeviceResponse: Codable {
    let authenticated: Bool
    let requiresVerification: Bool?
    let phoneNumber: String?
    let token: String?
}
