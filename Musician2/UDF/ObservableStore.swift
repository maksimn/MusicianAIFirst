//
//  ObservableStore.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Observation
import UDF

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
    private let disposer = Disposer()

    init(_ store: Store<State>) {
        self.state = store.state
        self.store = store

        store.observe { [weak self] state in
            self?.state = state
        }
        .dispose(on: disposer)
    }

    func dispatch(_ action: Action) {
        store.dispatch(action)
    }
}
