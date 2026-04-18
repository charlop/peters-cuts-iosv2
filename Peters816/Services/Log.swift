//
//  Log.swift
//  Peters816
//
//  Structured logging using os.Logger
//

import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Peters816"

    static let api = Logger(subsystem: subsystem, category: "API")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let general = Logger(subsystem: subsystem, category: "General")

    // MARK: - Enhanced Logging Methods

    static func debug(
        _ logger: Logger,
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let context = formatContext(function: function, file: file, line: line)
        logger.debug("\(context) \(message)")
    }

    static func info(
        _ logger: Logger,
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let context = formatContext(function: function, file: file, line: line)
        logger.info("\(context) \(message)")
    }

    static func error(
        _ logger: Logger,
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let context = formatContext(function: function, file: file, line: line)
        logger.error("❌ \(context) \(message)")
    }

    static func fault(
        _ logger: Logger,
        _ message: String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        let context = formatContext(function: function, file: file, line: line)
        logger.fault("❌ \(context) \(message)")
    }

    // MARK: - Private Helpers

    private static func formatContext(function: String, file: String, line: Int) -> String {
        let fileName = (file as NSString).lastPathComponent
        let threadName = Thread.isMainThread ? "main" : (Thread.current.name ?? "bg")
        return "[\(threadName)][\(fileName):\(line)][\(function)]"
    }
}
