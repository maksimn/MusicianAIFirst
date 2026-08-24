//
//  UDF.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

protocol Action { }

protocol ActionDispatcher {

    func dispatch(_ action: Action)
}

protocol SideEffect {

    func execute(with: ActionDispatcher)
}

typealias Reducer<State> = (inout State, Action) -> SideEffect?

