//
//  FavoritesSideEffects.swift
//  Musician2
//
//  Created by Maksim Ivanov on 12.09.2026.
//

import Foundation
import UDF

/// Reads the tracks marked as favorite ones out of every stored album.
///
/// A failed reading dispatches nothing: the screen keeps the tracks it already shows, and on the very
/// first reading that leaves it empty — which is what having no favorite tracks looks like anyway.
struct LoadFavoriteTracksSideEffect: SideEffectProtocol {

    let cacheService: AlbumCacheService

    let logger: Logger

    func execute(with dispatcher: ActionDispatcher) {
        do {
            dispatcher.dispatch(FavoritesAction.favoriteTracksLoaded(try cacheService.loadFavoriteTracks()))
        } catch {
            logger.errorWithContext(error)
        }
    }
}
