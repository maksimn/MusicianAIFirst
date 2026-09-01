//
//  AlbumListFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 16.07.2026.
//

import SwiftUI
import UDF

struct AlbumListFeature: View {

    private let albumTracklistStore: ObservableStore<AlbumTracklistState>

    @State private var store: ObservableStore<AlbumListState>

    init(store: Store<AppState>) {
        _store = State(wrappedValue: ObservableStore(store.scope(\.albumList)))
        self.albumTracklistStore = ObservableStore(store.scope(\.albumTracklist))
    }

    var body: some View {
        AlbumListView(store: store) {
            // The tapped album is already in the state of the album tracklist feature:
            // it has been put there by the AlbumTapped action.
            AlbumDetailsView(store: albumTracklistStore)
        }
    }
}
