//
//  Reachability.swift
//  Peters816
//
//  Created by Chris Charlopov on 7/30/17.
//  Updated by Claude on 2025-12-22 to use modern Network framework
//  Copyright © 2017 spandan. All rights reserved.
//

import Foundation
import Network

/// Modern network reachability checker using Network framework
public class Reachability {
    /// Check if device is connected to the network
    /// Uses the modern NWPathMonitor API (iOS 12+) instead of deprecated SCNetworkReachability
    class func isConnectedToNetwork() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "com.peters816.reachability")
        monitor.start(queue: queue)

        // Wait for initial path update (with timeout)
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()

        return isConnected
    }

    /// Check if connected via WiFi
    class func isConnectedViaWiFi() -> Bool {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "com.peters816.reachability.wifi")
        monitor.start(queue: queue)

        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()

        return isConnected
    }

    /// Check if connected via Cellular
    class func isConnectedViaCellular() -> Bool {
        let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false

        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }

        let queue = DispatchQueue(label: "com.peters816.reachability.cellular")
        monitor.start(queue: queue)

        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()

        return isConnected
    }
}
