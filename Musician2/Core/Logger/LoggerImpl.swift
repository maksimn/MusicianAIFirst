//
//  LoggerImpl.swift
//  CoreModule
//
//  Created by Maxim Ivanov on 24.03.2023.
//

import Foundation

public nonisolated final class LoggerImpl: Logger {

    private let category: String

    private let dateformat: DateFormatter = {
        let dateformat = DateFormatter()

        dateformat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        return dateformat
    }()

    public init(category: String) {
        self.category = category
    }

    public func log(_ message: String, level: LogLevel) {
        guard isDevelopment() else { return }

        print("\(dateformat.string(from: Date())) [\(level.rawValue)] [\(category)] \(message)")
    }
}
