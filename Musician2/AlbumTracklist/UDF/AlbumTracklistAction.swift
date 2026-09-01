//
//  AlbumTracklistAction.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import UDF

/// The actions of the album tracklist feature.
enum AlbumTracklistAction: Action {

    /// The user has tapped a track of the listed album: the track selector and the audio
    /// player react to it, because picking a track overrides whatever was queued next.
    case trackTapped(Track, Album)
}
