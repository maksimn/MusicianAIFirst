//
//  TrackSelectorState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 25.08.2026.
//

/// The list the playing track has been picked from, which the track to play next is taken from: the
/// playback goes on through the very list the user has picked in, be it an album or the favorites.
///
/// The list is a copy taken at the moment of the pick, so the marks the user changes afterwards
/// neither reorder nor cut short the playback already running through it.
enum TrackQueue: Equatable {

    /// The tracks of an album, in the order the album lists them.
    case album(Album)

    /// The favorite tracks, as the favorites screen listed them: they belong to no single album
    /// the next track could be taken from, so the list itself is the queue.
    case favorites([Track])

    var tracks: [Track] {
        switch self {
        case .album(let album):
            return album.tracks

        case .favorites(let tracks):
            return tracks
        }
    }
}

/// The state of the track selector: the track the application is playing and the list it comes from.
struct TrackSelectorState {

    var queue: TrackQueue?

    var selectedTrack: Track?
}
