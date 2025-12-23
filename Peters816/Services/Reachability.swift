//
//  Reachability.swift
//  Peters816
//
//  Created by Chris Charlopov on 7/30/17.
//  Updated by Claude on 2025-12-23 to use async/await
//  Copyright © 2017 spandan. All rights reserved.
//

import Foundation
import Network

/// Modern network reachability checker using Network framework
public actor Reachability {

    /// Check if device is connected to the network
    public static func isConnectedToNetwork() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "com.peters816.reachability")

            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }

            monitor.start(queue: queue)

            // Timeout after 1 second
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                continuation.resume(returning: false)
                monitor.cancel()
            }
        }
    }

    /// Check if connected via WiFi
    public static func isConnectedViaWiFi() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
            let queue = DispatchQueue(label: "com.peters816.reachability.wifi")

            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }

            monitor.start(queue: queue)

            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                continuation.resume(returning: false)
                monitor.cancel()
            }
        }
    }

    /// Check if connected via Cellular
    public static func isConnectedViaCellular() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
            let queue = DispatchQueue(label: "com.peters816.reachability.cellular")

            monitor.pathUpdateHandler = { path in
                continuation.resume(returning: path.status == .satisfied)
                monitor.cancel()
            }

            monitor.start(queue: queue)

            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                continuation.resume(returning: false)
                monitor.cancel()
            }
        }
    }
}
