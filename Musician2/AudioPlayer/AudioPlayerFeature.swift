//
//  AudioPlayerFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.07.2026.
//

import SwiftUI
import UDF

struct AudioPlayerFeature: View {

    @State private var store: ObservableStore<AudioPlayerState>

    init(store: Store<AudioPlayerState>) {
        _store = State(wrappedValue: ObservableStore(store))
    }

    var body: some View {
        AudioPlayerView(store: store)
    }
}
