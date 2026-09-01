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
/// tracks are listed and which of them is the one being played. Both of them are announced by
/// the other features, so the reducer only listens and never fetches anything itself.
struct AlbumTracklistReducer {

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

        default:
            break
        }

        return nil
    }
}
