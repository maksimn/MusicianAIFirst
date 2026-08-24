//
//  AlbumListFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 16.07.2026.
//

import SwiftUI

struct AlbumListFeature: View {

    @State private var store = ObservableStore(
        Store(
            initialState: AlbumListState(),
            reducer: AlbumListReducer(
                repository: AlbumRepositoryImpl(
                    dataLoader: URLSessionNetworkDataLoader(),
                    cacheService: FileCacheService()
                ),
                albumListLoadedSender: AlbumListLoadedStream.shared
            ).reduce
        )
    )

    var body: some View {
        AlbumListView(store: store)
    }
}
