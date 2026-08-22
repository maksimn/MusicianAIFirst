//
//  ActionStream.swift
//  Musician2
//
//  Created by Maksim Ivanov on 22.08.2026.
//

import Foundation

/// A multicast stream of an action's values: every listener gets its own `AsyncStream`,
/// and `send(_:)` delivers the value to all of them.
/// The state is guarded by a lock, so the type is safe to use from any isolation domain.
nonisolated final class ActionStream<Value: Sendable>: @unchecked Sendable {

    /// Every access returns a new stream, so the action may be listened to by several listeners.
    var values: AsyncStream<Value> {
        AsyncStream { continuation in
            let id = UUID()

            add(continuation, for: id)

            continuation.onTermination = { [weak self] _ in
                self?.removeContinuation(for: id)
            }
        }
    }

    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    private let lock = NSLock()

    func send(_ value: Value) {
        let continuations = currentContinuations()

        for continuation in continuations {
            continuation.yield(value)
        }
    }

    private func add(_ continuation: AsyncStream<Value>.Continuation, for id: UUID) {
        lock.lock()
        defer { lock.unlock() }

        continuations[id] = continuation
    }

    private func removeContinuation(for id: UUID) {
        lock.lock()
        defer { lock.unlock() }

        continuations[id] = nil
    }

    private func currentContinuations() -> [AsyncStream<Value>.Continuation] {
        lock.lock()
        defer { lock.unlock() }

        return Array(continuations.values)
    }
}
