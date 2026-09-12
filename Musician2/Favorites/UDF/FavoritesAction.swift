//
//  FavoritesAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 12.09.2026.
//

import UDF

/// The actions of the favorites feature.
enum FavoritesAction: Action {

    /// The favorites screen has been shown and needs its tracks: they are spread over all the stored
    /// albums, which is the only place the favorite marks outlive a launch in.
    case loadFavoriteTracks

    /// The favorite tracks have been read from the storage.
    case favoriteTracksLoaded([Track])

    /// The user has taken the favorite mark off a track of the list: the tracklist of an album reacts
    /// to it, because it may be showing that very track as a favorite one.
    case removeFromFavorites(Track)
}
