//
//  FavoritesReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 12.09.2026.
//

import UDF

/// Produces the new state of the favorites feature for every dispatched action.
///
/// The feature owns the list of the tracks marked as favorite ones, which belong to no single album:
/// the storage is the only place holding the marks of all the albums at once, so the list is read
/// from there. It is read once and then kept in step with every mark the user changes afterwards —
/// an album's tracklist announces each of them — instead of being re-read, because a re-read would
/// race with the writing of the very change that caused it.
struct FavoritesReducer {

    private let cacheService: AlbumCacheService

    private let logger: Logger

    init(cacheService: AlbumCacheService, logger: Logger) {
        self.cacheService = cacheService
        self.logger = logger
    }

    func reduce(_ state: inout FavoritesState, _ action: Action) -> SideEffect {
        switch action {
        case let action as FavoritesAction:
            switch action {
            case .loadFavoriteTracks:
                return LoadFavoriteTracksSideEffect(cacheService: cacheService, logger: logger)

            case .favoriteTracksLoaded(let tracks):
                state.tracks = tracks

            case .removeFromFavorites(let track):
                return removeFromFavorites(track, in: &state)

            case .trackTapped:
                break
            }

        case let action as AlbumTracklistAction:
            if case .toggleIsFavorite(let track) = action {
                applyChangedMark(of: track, in: &state)
            }

        case let action as TrackSelectorAction:
            if case .nextTrack(let trackData) = action {
                state.currentTrack = trackData.track
            }

        default:
            break
        }

        return nil
    }

    /// Drops the track from the list at once and has the taken off mark written to the storage,
    /// which owns the marks between the launches.
    private func removeFromFavorites(_ track: Track, in state: inout FavoritesState) -> SideEffect {
        var removedTrack = track

        removedTrack.isFavorite = false

        state.tracks.removeAll { $0.trackId == removedTrack.trackId }

        return SaveTrackSideEffect(track: removedTrack, cacheService: cacheService, logger: logger)
    }

    /// Adds a track just marked in an album's tracklist to the list, or drops the one whose mark has
    /// been taken off there — that feature writes the storage itself, so nothing is written here.
    ///
    /// The announced track carries the mark it had before the tap, the same way the announcing feature
    /// receives it, so the change is applied here as well. The newly marked track goes first, because
    /// the list is ordered by the moment of the marking, the freshest one first.
    private func applyChangedMark(of track: Track, in state: inout FavoritesState) {
        var changedTrack = track

        changedTrack.isFavorite.toggle()

        state.tracks.removeAll { $0.trackId == changedTrack.trackId }

        guard changedTrack.isFavorite else { return }

        state.tracks.insert(changedTrack, at: 0)
    }
}
