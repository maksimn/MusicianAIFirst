//
//  AlbumTracklistState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import Foundation

/// The state of a shown album's tracklist: the album whose tracks are listed and the track
/// the whole application is playing, so that the list can mark it as the current one.
struct AlbumTracklistState {

    var album: Album?

    /// The track selected for the playback, whatever album it belongs to.
    var currentTrack: Track?
}
