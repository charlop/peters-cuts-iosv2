//
//  AddressResponse.swift
//  Peters816
//
//  Response from config address endpoint
//

import Foundation

struct AddressResponse: Codable {
    let address: String
    let phone: String
}
