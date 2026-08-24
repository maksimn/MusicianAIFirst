//
//  Store.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Foundation

/// A simple `State` manager.
///
/// Every dispatched action is passed to the reducer together with the current state.
/// The reducer produces the new state and, optionally, a side effect. The store then
/// notifies all the subscribers about the new state and executes the side effect,
/// which may dispatch further actions back into the store.
final class Store<State>: ActionDispatcher {

    /// The current state. Changes only as a result of `dispatch(_:)`.
    private(set) var state: State

    private let reducer: Reducer<State>

    private var subscribers: [UUID: (State) -> Void] = [:]

    init(initialState: State, reducer: @escaping Reducer<State>) {
        self.state = initialState
        self.reducer = reducer
    }

    /// Reduces the state with the given action, notifies the subscribers
    /// and executes the side effect returned by the reducer, if any.
    func dispatch(_ action: Action) {
        let sideEffect = reducer(&state, action)

        notifySubscribers()

        sideEffect?.execute(with: self)
    }

    /// Subscribes to the state updates.
    ///
    /// The subscriber is called immediately with the current state and then on every change.
    /// - Returns: A subscription that stops the notifications when cancelled or deallocated.
    @discardableResult
    func subscribe(_ subscriber: @escaping (State) -> Void) -> Subscription {
        let id = UUID()

        subscribers[id] = subscriber
        subscriber(state)

        return Subscription { [weak self] in
            self?.subscribers[id] = nil
        }
    }

    private func notifySubscribers() {
        // Iterate over a snapshot: a subscriber may add or remove subscriptions while being notified.
        let subscribers = Array(self.subscribers.values)

        for subscriber in subscribers {
            subscriber(state)
        }
    }
}

extension Store {

    /// A handle that keeps a subscription alive. Cancels itself on deinit.
    final class Subscription {

        private var onCancel: (() -> Void)?

        fileprivate init(cancel: @escaping () -> Void) {
            self.onCancel = cancel
        }

        deinit {
            onCancel?()
        }

        func cancel() {
            onCancel?()
            onCancel = nil
        }
    }
}
