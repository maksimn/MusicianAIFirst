//
//  AlbumDetailsState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 24.08.2026.
//

import Foundation

/// The state of the album details: the shown album and its track selected for the playback, if any.
struct AlbumDetailsState {

    let album: Album

    var selectedTrack: Track?
}
