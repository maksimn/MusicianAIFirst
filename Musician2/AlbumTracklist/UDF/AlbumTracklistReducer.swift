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
/// The first two are announced by the other features, so the reducer only listens and never fetches
/// anything itself; the favorite flag is the feature's own and is stored through the repository.
struct AlbumTracklistReducer {

    private let repository: AlbumRepository

    private let logger: Logger

    init(repository: AlbumRepository, logger: Logger) {
        self.repository = repository
        self.logger = logger
    }

    func reduce(_ state: inout AlbumTracklistState, _ action: Action) -> SideEffect {
        switch action {
        case let action as AlbumListAction:
            if case .albumTapped(let album) = action {
                state.album = album
            }

        case let action as TrackSelectorAction:
            if case .nextTrack(let trackData) = action {
                state.currentTrack = trackData.track
            }

        case let action as AlbumTracklistAction:
            if case .toggleIsFavorite(let track) = action {
                return toggleIsFavorite(of: track, in: &state)
            }

        default:
            break
        }

        return nil
    }

    /// Marks the track as a favorite one — or takes the mark off — in every copy of it the feature
    /// keeps, and has the change written to the storage the flag outlives the launch in.
    ///
    /// The album of the state holds value copies of its tracks, so the tapped track is replaced in it
    /// as well; otherwise the list would keep showing the flag the track had before the tap.
    private func toggleIsFavorite(of track: Track, in state: inout AlbumTracklistState) -> SideEffect {
        var toggledTrack = track

        toggledTrack.isFavorite.toggle()

        state.album = state.album?.replacing(toggledTrack)

        if state.currentTrack?.trackId == toggledTrack.trackId {
            state.currentTrack = toggledTrack
        }

        return SaveTrackSideEffect(track: toggledTrack, repository: repository, logger: logger)
    }
}
