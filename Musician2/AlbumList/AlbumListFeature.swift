//
//  AlbumListFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 16.07.2026.
//

import SwiftUI
import UDF

struct AlbumListFeature: View {

    private let albumDetailsStore: Store<AlbumDetailsState>

    @State private var store: ObservableStore<AlbumListState>

    init(store: Store<AppState>) {
        self.albumDetailsStore = store.scope(\.albumDetails)
        _store = State(wrappedValue: ObservableStore(store.scope(\.albumList)))
    }

    var body: some View {
        AlbumListView(store: store) {
            // The tapped album is already in the state of the album details feature:
            // it has been put there by the AlbumTapped action.
            AlbumDetailsFeature(store: albumDetailsStore)
        }
    }
}
