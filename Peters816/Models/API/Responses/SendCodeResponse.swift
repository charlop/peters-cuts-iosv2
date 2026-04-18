//
//  SendCodeResponse.swift
//  Peters816
//
//  Response from sending verification code
//

import Foundation

struct SendCodeResponse: Codable {
    let message: String
    let codeId: String
}
