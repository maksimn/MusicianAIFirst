//
//  AlbumListFeature.swift
//  Musician2
//
//  Created by Maksim Ivanov on 16.07.2026.
//

import SwiftUI

struct AlbumListFeature: View {

    var body: some View {
        AlbumListView(
            viewModel: AlbumListViewModel(
                repository: AlbumRepository(
                    dataLoader: URLSessionNetworkDataLoader(),
                    cacheService: FileCacheService()
                ),
                albumListLoadedSender: AlbumListLoadedStream.shared
            )
        )
    }
}
