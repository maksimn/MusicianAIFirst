//
//  FavoritesState.swift
//  Musician2
//
//  Created by Maksim Ivanov on 12.09.2026.
//

import Foundation

/// The state of the favorites screen: the tracks the user has marked as favorite ones, whatever
/// album each of them belongs to, and the track the whole application is playing, so that the list
/// can mark it as the current one.
struct FavoritesState {

    /// The favorite tracks, the one marked last coming first — the order the storage returns them in.
    var tracks: [Track] = []

    /// The track selected for the playback, whatever album it belongs to.
    var currentTrack: Track?
}
