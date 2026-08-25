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
    let albumDetailsReducer: AlbumDetailsReducer
    let audioPlayerReducer: AudioPlayerReducer
    let trackSelectorReducer: TrackSelectorReducer

    func reduce(_ state: inout AppState, _ action: Action) -> SideEffect {
        let albumListSideEffect = albumListReducer.reduce(&state.albumList, action)
        let albumDetailsSideEffect = albumDetailsReducer.reduce(&state.albumDetails, action)
        let audioPlayerSideEffect = audioPlayerReducer.reduce(&state.audioPlayer, action)
        let trackSelectorSideEffect = trackSelectorReducer.reduce(&state.trackSelector, action)

        let sideEffects = [albumListSideEffect, albumDetailsSideEffect, audioPlayerSideEffect, trackSelectorSideEffect]

        guard sideEffects.count > 1 else { return sideEffects.first ?? nil }

        return CombineSideEffect(effects: sideEffects)
    }
}
