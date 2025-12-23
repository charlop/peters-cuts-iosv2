//
//  NotificationService.swift
//  Peters816
//
//  Created by Claude on 2025-12-22.
//  Handles all local notification scheduling and management
//

import Foundation
import UserNotifications

// MARK: - NotificationService
final class NotificationService: @unchecked Sendable {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Notification Messages
    private enum NotificationMessage {
        static let title = "Message from Peter"
        static let body20Min = "Your haircut is in 20 minutes!"
        static let body40Min = "Your haircut is in 40 minutes!"
    }

    // MARK: - Public Methods

    /// Request notification permissions from user
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted
    }

    /// Schedule notifications for an appointment
    /// - Parameter etaMinutes: Estimated time in minutes until appointment
    func scheduleAppointmentNotifications(etaMinutes: Double) {
        // Remove any existing notifications first
        removeAllNotifications()

        // Schedule 40-minute warning if ETA is more than 40 minutes
        if etaMinutes > 40 {
            scheduleNotification(
                title: NotificationMessage.title,
                body: NotificationMessage.body40Min,
                timeInterval: (etaMinutes - 40) * 60
            )
        }

        // Schedule 20-minute warning if ETA is more than 20 minutes
        if etaMinutes > 20 {
            scheduleNotification(
                title: NotificationMessage.title,
                body: NotificationMessage.body20Min,
                timeInterval: (etaMinutes - 20) * 60
            )
        }
    }

    /// Remove all scheduled and delivered notifications
    func removeAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    /// Get count of pending notifications (for debugging)
    func getPendingNotificationCount() async -> Int {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        return pending.count
    }

    // MARK: - Private Methods

    private func scheduleNotification(title: String, body: String, timeInterval: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
