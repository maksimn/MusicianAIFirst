//
//  AlbumListReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

/// Produces the new state of the album list feature for every dispatched action.
///
/// The reducer itself only changes the state: everything else — fetching, reading the cache,
/// notifying the other features — is left to the returned side effects.
struct AlbumListReducer {

    private let repository: AlbumRepository

    private let albumListLoadedSender: AlbumListLoadedSender

    private let isReversed: Bool

    init(repository: AlbumRepository, albumListLoadedSender: AlbumListLoadedSender, isReversed: Bool = true) {
        self.repository = repository
        self.albumListLoadedSender = albumListLoadedSender
        self.isReversed = isReversed
    }

    func reduce(_ state: inout AlbumListState, _ action: Action) -> SideEffect? {
        guard let action = action as? AlbumListAction else { return nil }

        switch action {
        case .loadAlbums:
            guard state.albums.isEmpty, !state.isLoading else { return nil }

            state.isLoading = true
            state.error = nil

            return LoadAlbumsSideEffect(repository: repository)

        case .albumsLoaded(let albums):
            state.isLoading = false
            state.albums = ordered(albums)

            return albumListLoadedSideEffect(for: state)

        case .loadingFailed(let error):
            state.isLoading = false
            state.error = error

            // If network fails, keep showing cached albums.
            return state.albums.isEmpty ? LoadCachedAlbumsSideEffect(repository: repository) : nil

        case .cachedAlbumsLoaded(let albums):
            state.albums = ordered(albums)

            return albumListLoadedSideEffect(for: state)
        }
    }

    private func ordered(_ albums: [Album]) -> [Album] {
        isReversed ? albums.reversed() : albums
    }

    private func albumListLoadedSideEffect(for state: AlbumListState) -> SideEffect? {
        guard !state.albums.isEmpty else { return nil }

        return AlbumListLoadedSideEffect(albums: state.albums, sender: albumListLoadedSender)
    }
}
