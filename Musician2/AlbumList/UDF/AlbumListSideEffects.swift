//
//  AlbumListSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import Foundation
import UDF

/// Fetches the albums from the network, stores them and dispatches the result back to the store.
///
/// The albums are dispatched as they come from the storage, not as they were decoded: saving merges
/// the feed with the locally owned track data, so only a re-read carries the favorites along.
struct LoadAlbumsSideEffect: SideEffectProtocol {

    let dataLoader: NetworkDataLoader

    let cacheService: AlbumCacheService

    func execute(with dispatcher: ActionDispatcher) {
        Task {
            do {
                let url = URL(string: "http://maksimn.github.io/albums.json")!
                let data = try await dataLoader.download(url)
                let albums = try JSONDecoder().decode([Album].self, from: data)

                try cacheService.saveAlbums(albums)

                dispatcher.dispatch(AlbumListAction.albumsLoaded((try? cacheService.loadAlbums()) ?? albums))
            } catch {
                dispatcher.dispatch(AlbumListAction.loadingFailed(error))
            }
        }
    }
}

/// Reads the albums stored by the previous successful fetching.
struct LoadCachedAlbumsSideEffect: SideEffectProtocol {

    let cacheService: AlbumCacheService

    func execute(with dispatcher: ActionDispatcher) {
        dispatcher.dispatch(AlbumListAction.albumsLoaded((try? cacheService.loadAlbums()) ?? []))
    }
}
