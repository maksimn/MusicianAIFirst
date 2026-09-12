//
//  SideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 13.09.2026.
//

import UDF

/// Writes the changed favorite flag of a track to the storage, which owns it between the launches.
///
/// Nothing is dispatched back: the state already shows the track as the user has just marked it,
/// and a failed write leaves the storage with the previous flag, which the next reading restores.
struct SaveTrackSideEffect: SideEffectProtocol {

    let track: Track

    let cacheService: AlbumCacheService

    let logger: Logger

    /// The moment of the change is stamped here and not in the reducer, because reading the clock is
    /// an effect: the reducer stays a function of nothing but the state and the action.
    func execute(with dispatcher: ActionDispatcher) {
        do {
            try cacheService.saveTrack(track)
        } catch {
            logger.errorWithContext(error)
        }
    }
}
