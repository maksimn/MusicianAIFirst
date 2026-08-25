//
//  AlbumListSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Fetches the albums from the repository and dispatches the result back to the store.
struct LoadAlbumsSideEffect: SideEffectProtocol {

    let repository: AlbumRepository

    func execute(with dispatcher: ActionDispatcher) {
        Task {
            do {
                let albums = try await repository.fetchAlbums()

                dispatcher.dispatch(AlbumListAction.albumsLoaded(albums))
            } catch {
                dispatcher.dispatch(AlbumListAction.loadingFailed(error))
            }
        }
    }
}

/// Reads the albums cached by the previous successful fetching.
struct LoadCachedAlbumsSideEffect: SideEffectProtocol {

    let repository: AlbumRepository

    func execute(with dispatcher: ActionDispatcher) {
        dispatcher.dispatch(AlbumListAction.albumsLoaded(repository.loadCachedAlbums()))
    }
}
