//
//  CheckDeviceRequest.swift
//  Peters816
//
//  Request to check if device is trusted
//

import Foundation

struct CheckDeviceRequest: Codable {
    let phoneNumber: String
    let deviceFingerprint: String
}
