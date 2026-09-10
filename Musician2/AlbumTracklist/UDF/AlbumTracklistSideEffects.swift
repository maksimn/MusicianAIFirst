//
//  AlbumTracklistSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 09.09.2026.
//

import Foundation
import UDF

/// Reads the tapped album from the storage, which the favorite flags are written to.
///
/// A failed reading dispatches nothing: the tracklist keeps showing the album as it was tapped, which
/// differs from the stored one in nothing but the favorite flags changed since the list was loaded.
struct LoadAlbumSideEffect: SideEffectProtocol {

    let albumId: Int

    let cacheService: AlbumCacheService

    let logger: Logger

    func execute(with dispatcher: ActionDispatcher) {
        do {
            dispatcher.dispatch(AlbumTracklistAction.albumLoaded(try cacheService.loadAlbum(albumId: albumId)))
        } catch {
            logger.errorWithContext(error)
        }
    }
}

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
