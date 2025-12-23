//
//  APIResponses.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//

import Foundation

// MARK: - API Response Models

/// Response for ETA requests
struct ETAResponse: Codable {
    let etaMins: Double
    let hasNum: Bool
    let reservation: Bool
    let id: Int
    let curNum: Int
    let error: Int?

    enum CodingKeys: String, CodingKey {
        case etaMins
        case hasNum
        case reservation
        case id
        case curNum
        case error
    }
}

/// Wrapper for ETA array responses
struct ETAArrayResponse: Codable {
    let etaArray: [ETAResponse]?
    let error: Int?
}

/// Response for get number/reservation requests
struct NumberResponse: Codable {
    let etaMins: Double?
    let id: Int?
    let error: Int?
}

/// Response for cancellation requests
struct CancelResponse: Codable {
    let delResult: String?
    let error: Int?
}

/// Response for available openings
struct OpeningResponse: Codable {
    let startTime: String
    let id: Int
    let error: Int?
    let fatal: Int?

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case id
        case error
        case fatal
    }
}

/// Wrapper for openings array
struct OpeningsResult {
    let availableSpots: [String: Int]
    let availableSpotsArray: [String]
    let error: Int?
}

// MARK: - API Errors

enum APIError: Error {
    case noInternet
    case invalidResponse
    case noData
    case decodingError(Error)
    case serverError(Int)
    case unknown

    var localizedDescription: String {
        switch self {
        case .noInternet:
            return "No internet connection"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
