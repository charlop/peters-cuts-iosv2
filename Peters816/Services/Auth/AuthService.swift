//
//  AuthService.swift
//  Peters816
//
//  Authentication service for SMS verification and JWT management
//

import Foundation
import UIKit

@MainActor
class AuthService {
    static let shared = AuthService()

    private let apiClient = APIClientV2.shared
    private let keychain = KeychainService.shared

    private init() {}

    // MARK: - Public Properties

    var isAuthenticated: Bool {
        return keychain.getToken() != nil
    }

    var currentToken: String? {
        return keychain.getToken()
    }

    var currentPhoneNumber: String? {
        return keychain.getPhoneNumber()
    }

    // MARK: - Device Fingerprint

    private var deviceFingerprint: String {
        if let saved = keychain.getDeviceFingerprint() {
            return saved
        }

        let fingerprint = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        _ = keychain.saveDeviceFingerprint(fingerprint)
        return fingerprint
    }

    // MARK: - Authentication Methods

    func checkDeviceTrust(phoneNumber: String) async throws -> Bool {
        let request = CheckDeviceRequest(
            phoneNumber: formatPhoneNumber(phoneNumber),
            deviceFingerprint: deviceFingerprint
        )
        print(request)
        let response: CheckDeviceResponse = try await apiClient.request(
            .checkDevice,
            body: request
        )

        print(response)

        if response.authenticated, let token = response.token {
            _ = keychain.saveToken(token)
            _ = keychain.savePhoneNumber(phoneNumber)
            return true
        }

        return false
    }

    func sendVerificationCode(phoneNumber: String) async throws -> String {
        let request = SendCodeRequest(phoneNumber: formatPhoneNumber(phoneNumber))

        let response: SendCodeResponse = try await apiClient.request(
            .sendCode,
            body: request
        )

        return response.codeId
    }

    func verifyCode(codeId: String, code: String, name: String? = nil) async throws {
        let request = VerifyCodeRequest(codeId: codeId, code: code, name: name)

        let response: VerifyCodeResponse = try await apiClient.request(
            .verifyCode,
            body: request
        )

        _ = keychain.saveToken(response.token)
        _ = keychain.savePhoneNumber(response.phoneNumber)
    }

    func signOut() {
        _ = keychain.clearAll()
    }

    // MARK: - Phone Number Formatting

    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if digits.hasPrefix("1") && digits.count == 11 {
            return "+\(digits)"
        } else if digits.count == 10 {
            return "+1\(digits)"
        }

        return "+1\(digits)"
    }
}
