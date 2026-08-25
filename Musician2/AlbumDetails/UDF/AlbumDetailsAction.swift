//
//  AlbumDetailsAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

import UDF

/// The actions of the album details feature.
enum AlbumDetailsAction: Action {

    /// The user has tapped a track of the shown album.
    case trackTapped(Track, Album)
}
