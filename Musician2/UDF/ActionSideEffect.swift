//
//  DispatchActionSideEffect.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Dispatches an action back into the store.
///
/// A reducer may only change its own part of the state, so an event the other features
/// have to know about is announced with the action this side effect dispatches.
struct ActionSideEffect: SideEffectProtocol {

    private let action: Action

    init(_ action: Action) {
        self.action = action
    }

    func execute(with dispatcher: ActionDispatcher) {
        dispatcher.dispatch(action)
    }
}
