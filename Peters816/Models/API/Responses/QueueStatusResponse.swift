//
//  QueueStatusResponse.swift
//  Peters816
//
//  Response for queue status
//

import Foundation

struct QueueStatusResponse: Codable {
    let currentNumber: Int?
    let queueLength: Int
    let estimatedWaitTime: Int
    let isOpen: Bool
    let slotsAvailable: Int
    let nextOpenDay: String?
    let lastUpdated: String
}
