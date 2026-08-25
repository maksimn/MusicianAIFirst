//
//  Musician2App.swift
//  Musician2
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import SwiftUI

private let builder = AppBuilder()
private let store = builder.build()

@main
struct Musician2App: App {

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
