//
//  TimerAPI.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import Foundation

protocol TimerAPI {

    func start(block: @escaping @MainActor () -> Void)

    func stop()
}

final class TimerAPIImpl: TimerAPI {

    private var timer: Timer?

    func start(block: @escaping @MainActor () -> Void) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor in
                block()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}