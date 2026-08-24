//
//  AlbumListSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

/// Fetches the albums from the repository and dispatches the result back to the store.
struct LoadAlbumsSideEffect: SideEffect {

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
struct LoadCachedAlbumsSideEffect: SideEffect {

    let repository: AlbumRepository

    func execute(with dispatcher: ActionDispatcher) {
        dispatcher.dispatch(AlbumListAction.cachedAlbumsLoaded(repository.loadCachedAlbums()))
    }
}

/// Notifies the other features about the loaded albums.
struct AlbumListLoadedSideEffect: SideEffect {

    let albums: [Album]

    let sender: AlbumListLoadedSender

    func execute(with dispatcher: ActionDispatcher) {
        sender.send(albums)
    }
}
