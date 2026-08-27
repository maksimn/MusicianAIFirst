//
//  AlbumDetailsReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// Produces the new state of the album details for every dispatched action.
///
/// The feature shows the album the user has tapped in the album list and keeps track
/// of the track being played, both of which are the actions of the other features.
struct AlbumDetailsReducer {

    func reduce(_ state: inout AlbumDetailsState, _ action: Action) -> SideEffect {
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
