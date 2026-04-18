//
//  VerifyCodeResponse.swift
//  Peters816
//
//  Response from verifying SMS code
//

import Foundation

struct VerifyCodeResponse: Codable {
    let token: String
    let phoneNumber: String
    let message: String
}
