//
//  ObservableStore.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Observation

/// Makes the state of a store observable by SwiftUI.
///
/// The views read the state through this facade and dispatch the actions back into the store,
/// so the store itself stays free of any UI framework.
@Observable
final class ObservableStore<State>: ActionDispatcher {

    private(set) var state: State

    @ObservationIgnored
    private let store: Store<State>

    @ObservationIgnored
    private var subscription: Store<State>.Subscription?

    init(_ store: Store<State>) {
        self.state = store.state
        self.store = store

        subscription = store.subscribe { [weak self] state in
            self?.state = state
        }
    }

    func dispatch(_ action: Action) {
        store.dispatch(action)
    }
}
