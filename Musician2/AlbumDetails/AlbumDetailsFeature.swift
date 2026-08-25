//
//  AlbumDetailsFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 23.08.2026.
//

import SwiftUI
import UDF

struct AlbumDetailsFeature: View {

    @State private var store: ObservableStore<AlbumDetailsState>

    init(store: Store<AlbumDetailsState>) {
        _store = State(wrappedValue: ObservableStore(store))
    }

    var body: some View {
        AlbumDetailsView(store: store)
    }
}
