//
//  KeychainService.swift
//  Peters816
//
//  Secure storage for JWT token and user data
//

import Foundation
import Security

final class KeychainService: @unchecked Sendable {
    static let shared = KeychainService()

    private let serviceName = "com.peters816.app"

    private enum Keys {
        static let jwtToken = "jwtToken"
        static let phoneNumber = "phoneNumber"
        static let deviceFingerprint = "deviceFingerprint"
    }

    private init() {}

    // MARK: - JWT Token

    func saveToken(_ token: String) -> Bool {
        return save(token, forKey: Keys.jwtToken)
    }

    func getToken() -> String? {
        return get(forKey: Keys.jwtToken)
    }

    func deleteToken() -> Bool {
        return delete(forKey: Keys.jwtToken)
    }

    // MARK: - Phone Number

    func savePhoneNumber(_ phoneNumber: String) -> Bool {
        return save(phoneNumber, forKey: Keys.phoneNumber)
    }

    func getPhoneNumber() -> String? {
        return get(forKey: Keys.phoneNumber)
    }

    func deletePhoneNumber() -> Bool {
        return delete(forKey: Keys.phoneNumber)
    }

    // MARK: - Device Fingerprint

    func saveDeviceFingerprint(_ fingerprint: String) -> Bool {
        return save(fingerprint, forKey: Keys.deviceFingerprint)
    }

    func getDeviceFingerprint() -> String? {
        return get(forKey: Keys.deviceFingerprint)
    }

    // MARK: - Clear All

    func clearAll() -> Bool {
        let tokenDeleted = deleteToken()
        let phoneDeleted = deletePhoneNumber()
        return tokenDeleted && phoneDeleted
    }

    // MARK: - Private Keychain Methods

    private func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
