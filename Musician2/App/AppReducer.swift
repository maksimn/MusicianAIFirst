//
//  AppReducer.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// The reducer of the whole application state.
///
/// It gives every feature reducer a chance to react to every action: the features share
/// the actions, not the state.
struct AppReducer {

    let albumListReducer: AlbumListReducer
    let albumTracklistReducer: AlbumTracklistReducer
    let audioPlayerReducer: AudioPlayerReducer
    let trackSelectorReducer: TrackSelectorReducer

    func reduce(_ state: inout AppState, _ action: Action) -> SideEffect {
        let albumListSideEffect = albumListReducer.reduce(&state.albumList, action)
        let albumTracklistSideEffect = albumTracklistReducer.reduce(&state.albumTracklist, action)
        let audioPlayerSideEffect = audioPlayerReducer.reduce(&state.audioPlayer, action)
        let trackSelectorSideEffect = trackSelectorReducer.reduce(&state.trackSelector, action)

        let sideEffects = [albumListSideEffect, albumTracklistSideEffect, audioPlayerSideEffect, trackSelectorSideEffect]

        guard sideEffects.count > 1 else { return sideEffects.first ?? nil }

        return CombineSideEffect(effects: sideEffects)
    }
}
