//
//  LoggingTimerAPI.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// Adds logging to a `TimerAPI` without changing its implementation.
///
/// Only the start / stop calls are logged: the timer block itself fires several times per second
/// and logging it would flood the log.
final class LoggingTimerAPI: TimerAPI {

    private let decorated: TimerAPI

    private let logger: Logger

    init(decorated: TimerAPI, logger: Logger) {
        self.decorated = decorated
        self.logger = logger
    }

    func start(block: @escaping @MainActor () -> Void) {
        logger.log("TimerAPI.start(block:) called.", level: .info)
        decorated.start(block: block)
    }

    func stop() {
        logger.log("TimerAPI.stop() called.", level: .info)
        decorated.stop()
    }
}
