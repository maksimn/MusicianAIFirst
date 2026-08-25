//
//  AlbumListReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Produces the new state of the album list feature for every dispatched action.
///
/// The reducer itself only changes the state: everything else — fetching, reading the cache,
/// notifying the other features — is left to the returned side effects.
struct AlbumListReducer {

    private let repository: AlbumRepository

    init(repository: AlbumRepository) {
        self.repository = repository
    }

    func reduce(_ state: inout AlbumListState, _ action: Action) -> SideEffect {
        guard let action = action as? AlbumListAction else { return nil }

        switch action {
        case .loadAlbums:
            guard state.albums.isEmpty, !state.isLoading else { return nil }

            state.isLoading = true
            state.error = nil

            return LoadAlbumsSideEffect(repository: repository)

        case .albumsLoaded(let albums):
            state.isLoading = false
            state.albums = albums.sorted(by: { $0.albumYear > $1.albumYear })

            return nil

        case .loadingFailed(let error):
            state.isLoading = false
            state.error = error

            // If network fails, keep showing cached albums.
            return state.albums.isEmpty ? LoadCachedAlbumsSideEffect(repository: repository) : nil

        default:
            return nil
        }
    }
}
