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
