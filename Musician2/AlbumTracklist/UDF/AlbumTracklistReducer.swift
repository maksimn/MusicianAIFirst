//
//  AlbumTracklistReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import UDF

/// Produces the new state of an album's tracklist for every dispatched action.
///
/// The feature owns the whole logic of working with the tracks of a shown album: which album's
/// tracks are listed, which of them is the one being played and which of them are the favorite ones.
/// The first two are announced by the other features; the favorite flag is the feature's own and lives
/// in the storage, so the listed album is read from there rather than taken from the announcement.
struct AlbumTracklistReducer {

    private let cacheService: AlbumCacheService

    private let logger: Logger

    init(cacheService: AlbumCacheService, logger: Logger) {
        self.cacheService = cacheService
        self.logger = logger
    }

    func reduce(_ state: inout AlbumTracklistState, _ action: Action) -> SideEffect {
        switch action {
        case let action as AlbumListAction:
            if case .albumTapped(let album) = action {
                return showAlbum(album, in: &state)
            }

        case let action as TrackSelectorAction:
            if case .nextTrack(let trackData) = action {
                state.currentTrack = trackData.track
            }

        case let action as FavoritesAction:
            if case .removeFromFavorites(let track) = action {
                takeFavoriteMarkOff(of: track, in: &state)
            }

        case let action as AlbumTracklistAction:
            switch action {
            case .toggleIsFavorite(let track):
                return toggleIsFavorite(of: track, in: &state)

            case .albumLoaded(let album):
                if album.albumId == state.album?.albumId {
                    state.album = album
                }

            case .trackTapped:
                break
            }

        default:
            break
        }

        return nil
    }

    /// Shows the tapped album at once and has its stored version read by its id.
    ///
    /// The album list keeps the albums as they were loaded, so the tapped album may miss the favorite
    /// flags changed since then — the tracklist would show the ones of a previous visit. The tapped
    /// copy only fills the screen being pushed until the stored album arrives; an album that arrives
    /// after another one has been tapped is dropped by its id when it is loaded.
    private func showAlbum(_ album: Album, in state: inout AlbumTracklistState) -> SideEffect {
        state.album = album

        return LoadAlbumSideEffect(albumId: album.albumId, cacheService: cacheService, logger: logger)
    }

    /// Marks the track as a favorite one — or takes the mark off — and has the change written to the
    /// storage the flag outlives the launch in.
    private func toggleIsFavorite(of track: Track, in state: inout AlbumTracklistState) -> SideEffect {
        var toggledTrack = track

        toggledTrack.isFavorite.toggle()

        apply(toggledTrack, in: &state)

        return SaveTrackSideEffect(track: toggledTrack, cacheService: cacheService, logger: logger)
    }

    /// Takes the favorite mark off a track the user has removed from the favorites screen, which may
    /// well be a track of the listed album: otherwise the tracklist, left on the screen while the
    /// removal happened on another tab, would keep showing the track as a favorite one. Nothing is
    /// written to the storage here — the favorites feature writes the mark it has taken off itself.
    private func takeFavoriteMarkOff(of track: Track, in state: inout AlbumTracklistState) {
        var unmarkedTrack = track

        unmarkedTrack.isFavorite = false

        apply(unmarkedTrack, in: &state)
    }

    /// Carries a changed track into every copy of it the feature keeps.
    ///
    /// The album of the state holds value copies of its tracks, so the changed track is replaced in it
    /// as well; otherwise the list would keep showing the flag the track had before the change.
    private func apply(_ track: Track, in state: inout AlbumTracklistState) {
        state.album = state.album?.replacing(track)

        if state.currentTrack?.trackId == track.trackId {
            state.currentTrack = track
        }
    }
}
