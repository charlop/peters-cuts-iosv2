//
//  SendCodeRequest.swift
//  Peters816
//
//  Request to send SMS verification code
//

import Foundation

struct SendCodeRequest: Codable {
    let phoneNumber: String
}
