//
//  ContentView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 30.06.2026.
//

import SwiftUI
import UDF

struct AppView: View {

    @State var store: Store<AppState>

    var body: some View {
        VStack(spacing: 2) {
            AlbumListFeature(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            AudioPlayerFeature(store: store.scope(\.audioPlayer))
        }
    }
}
