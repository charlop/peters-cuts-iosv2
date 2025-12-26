//
//  APIClientV2.swift
//  Peters816
//
//  REST API client with JSON encoding/decoding
//

import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case httpError(statusCode: Int, message: String)
    case decodingError(Error)
    case encodingError(Error)
    case missingToken
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Request encoding error: \(error.localizedDescription)"
        case .missingToken:
            return "Authentication token is missing"
        case .unauthorized:
            return "Unauthorized - please sign in again"
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}

@MainActor
class APIClientV2 {
    static let shared = APIClientV2()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = buildURL(for: endpoint) else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        
        print(url)
        print("requiresAuth? \(endpoint.requiresAuth)")
        if endpoint.requiresAuth {
            guard let token = token else {
                throw APIClientError.missingToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let token = token {
            // Include token if provided, even if not required
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
                print(String(data: request.httpBody!, encoding: .utf8))
            } catch {
                print("found the error")
                throw APIClientError.encodingError(error)
            }
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("bad server response")
                print(response)
                throw APIClientError.networkError(URLError(.badServerResponse))
            }
            print("success")
            print(String(data: data, encoding: .utf8))
            if httpResponse.statusCode == 401 {
                throw APIClientError.unauthorized
            }

            if httpResponse.statusCode >= 400 {
                let errorMessage: String
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    errorMessage = errorResponse.error
                } else {
                    errorMessage = "Unknown error"
                }
                throw APIClientError.httpError(statusCode: httpResponse.statusCode, message: errorMessage)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIClientError.decodingError(error)
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.networkError(error)
        }
    }

    // MARK: - Private Methods

    private func buildURL(for endpoint: APIEndpoint) -> URL? {
        let baseURL = APIConfiguration.baseURL
        return URL(string: baseURL.absoluteString + endpoint.path)
    }
}
