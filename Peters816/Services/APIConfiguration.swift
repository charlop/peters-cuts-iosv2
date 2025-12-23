//
//  APIConfiguration.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//

import Foundation

struct APIConfiguration {
    // MARK: - Base URL
    /// Base URL for the API
    /// Change this when migrating from PHP to Node.js backend
    static var baseURL: URL {
        #if DEBUG
        // For development, you can point to a different server
        return URL(string: "https://peterscuts.com/lib/app_request2.php")!
        #else
        return URL(string: "https://peterscuts.com/lib/app_request2.php")!
        #endif
    }

    // MARK: - Endpoints
    /// When migrating to Node.js, these can be converted to path components
    /// Example: baseURL.appendingPathComponent(Endpoints.eta)
    enum Endpoints {
        static let eta = "eta"
        static let getNumber = "number"
        static let cancel = "cancel"
        static let openings = "openings"
        static let closedMessage = "closed"
        static let greeting = "greeting"
        static let hours = "hours"
        static let address = "address"
    }
}
