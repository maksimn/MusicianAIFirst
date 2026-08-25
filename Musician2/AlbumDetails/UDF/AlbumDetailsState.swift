//
//  AlbumDetailsState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

/// The state of the album details: the shown album and the track the whole application is playing.
struct AlbumDetailsState {

    var album: Album?

    /// The track selected for the playback, whatever album it belongs to.
    var currentTrack: Track?
}
