//
//  AlbumTracklistView.swift
//  Musician2
//
//  Created by Maksim Ivanov on 01.09.2026.
//

import SwiftUI

/// The tracklist of the shown album, connected to the store.
///
/// It is the seam between the store-agnostic `TracklistView` and the feature: it feeds the list
/// with the album's tracks and the currently played one, and turns a tap on a track into an action.
struct AlbumTracklistView: View {

    let store: ObservableStore<AlbumTracklistState>

    var body: some View {
        if let album = store.state.album {
            TracklistView(
                tracks: album.tracks,
                currentTrack: store.state.currentTrack,
                textColor: album.textColor
            ) { track in
                store.dispatch(AlbumTracklistAction.trackTapped(track, album))
            }
        }
    }
}
