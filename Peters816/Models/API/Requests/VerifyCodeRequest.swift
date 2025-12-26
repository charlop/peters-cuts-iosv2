//
//  VerifyCodeRequest.swift
//  Peters816
//
//  Request to verify SMS code and get JWT
//

import Foundation

struct VerifyCodeRequest: Codable {
    let codeId: String
    let code: String
    let name: String?
}
